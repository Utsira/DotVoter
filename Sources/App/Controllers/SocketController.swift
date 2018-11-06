//
//  SocketController.swift
//  App
//
//  Created by Oliver Dew on 02/11/2018.
//

import Foundation
import Vapor
import Model

struct SocketController {
	
	static private let decoder = JSONDecoder()
	static private let encoder = JSONEncoder()
	
	private init() {}
	
	static func openConnection(socket: WebSocketType, request: Request) throws {
		let senderId = request.http.remotePeer.description
		try openConnection(socket: socket, senderId: senderId)
	}
	
	static func openConnection(socket: WebSocketType, senderId: String) throws {
		let room = Room.shared
		room.add(connection: socket, sender: senderId)
		
		let payload: ResponseType = .success(room.cardManager.partials)
		let data = try encoder.encode(payload)
		socket.send(data, promise: nil)
		socket.onText { ws, text in
			onText(socket: ws, text: text, senderId: senderId)
		}
	}
	
	static private func onText(socket: WebSocketType, text: String, senderId: String) {
		let room = Room.shared
		guard let data = text.data(using: .utf8),
			let payload = try? decoder.decode(Update.self, from: data)
			else {
				socket.send("Bad payload", promise: nil)
				return
		}
		
		let outcome = room.cardManager.handle(payload: payload, author: senderId)
		
		do {
			try handleOutcome(outcome, socket: socket)
		} catch {
			socket.send(error.localizedDescription, promise: nil)
		}
	}
	
	static private func handleOutcome(_ outcome: ResponseType, socket: WebSocketType) throws {
		switch outcome {
		case .success:
			try Room.shared.broadcast(updatedCards: outcome)
		case .failure:
			let errorEncoded = try encoder.encode(outcome)
			socket.send(errorEncoded, promise: nil)
		}
	}
}
