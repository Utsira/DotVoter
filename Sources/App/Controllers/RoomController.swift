//
//  SocketController.swift
//  App
//
//  Created by Oliver Dew on 02/11/2018.
//

import Foundation
import Vapor
import Model

protocol RoomController {
	associatedtype R: Room
	var rooms: SafeDictionary<String, R> { get }
}

extension RoomController {
	
	func openConnection(socket: WebSocketType, request: Request) throws {
		let senderId = request.http.remotePeer.description
		let roomId = try request.parameters.next(String.self)
		try openConnection(socket: socket, roomId: roomId, senderId: senderId)
	}
	
	func openConnection(socket: WebSocketType, roomId: String, senderId: String) throws {
		let room = getOrCreateRoom(for: roomId)
		room.add(connection: socket, sender: senderId)
		try room.onConnection(socket: socket)
		socket.onText { ws, text in
			room.onText(socket: ws, text: text, senderId: senderId)
		}
	}
	
	func getOrCreateRoom(for id: String) -> R {
		if let room = rooms[id] {
			return room
		}
		let room = R()
		rooms[id] = room
		return room
	}
}
