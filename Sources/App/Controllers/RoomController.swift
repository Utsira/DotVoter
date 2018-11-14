//
//  SocketController.swift
//  App
//
//  Created by Oliver Dew on 02/11/2018.
//

import Foundation
import Vapor
import Model

final class RoomController {
	
	static let shared = RoomController()
	
	private let decoder = JSONDecoder()
	private let encoder = JSONEncoder()
	
	let rooms = SafeDictionary<String, DotVoteRoom>()
	
	private init() {
		let demoRoom = DotVoteRoom()
		demoRoom.cardManager.resetAndAddTestCards()
		rooms["autumn-event"] = demoRoom
	}
	
	func openConnection(socket: WebSocketType, request: Request) throws {
		let senderId = request.http.remotePeer.description
		let roomId = try request.parameters.next(String.self)
		try openConnection(socket: socket, roomId: roomId, senderId: senderId)
	}
	
	func openConnection(socket: WebSocketType, roomId: String, senderId: String) throws {
		let room = getOrCreateRoom(for: roomId)
		room.add(connection: socket, sender: senderId)
		
		let payload: ResponseType = .success(room.cardManager.partials)
		let data = try encoder.encode(payload)
		socket.send(data, promise: nil)
		socket.onText { ws, text in
			self.onText(socket: ws, text: text, room: room, senderId: senderId)
		}
	}
	
	private func getOrCreateRoom(for id: String) -> DotVoteRoom {
		if let room = rooms[id] {
			return room
		}
		let room = DotVoteRoom()
		rooms[id] = room
		return room
	}
	
	private func onText(socket: WebSocketType, text: String, room: DotVoteRoom, senderId: String) {
		guard let data = text.data(using: .utf8),
			let payload = try? decoder.decode(Update.self, from: data)
			else {
				socket.send("Bad payload", promise: nil)
				return
		}
		
		let outcome = room.cardManager.handle(payload: payload, author: senderId)
		
		do {
			try handleOutcome(outcome, room: room, socket: socket)
		} catch {
			socket.send(error.localizedDescription, promise: nil)
		}
	}
	
	private func handleOutcome(_ outcome: ResponseType, room: DotVoteRoom, socket: WebSocketType) throws {
		switch outcome {
		case .success:
			try room.broadcast(updatedCards: outcome)
		case .failure:
			let errorEncoded = try encoder.encode(outcome)
			socket.send(errorEncoded, promise: nil)
		}
	}
}
