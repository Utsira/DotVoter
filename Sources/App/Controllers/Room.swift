//
//  Room.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation
import Vapor
import Model

final class Room {
	static let shared = Room()
	
	private var connections = SafeDictionary<String, WebSocket>()
	let cardManager = CardManager()
	private let encoder = JSONEncoder()
	
	private init() {}
	
	func add(connection: WebSocket, sender: String) {
		connections[sender] = connection
	}
	
	func sender(for socket: WebSocket) -> String? {
		return connections.first(where: {
			let (_, value) = $0
			return value === socket
		})?.key
	}
	
	func broadcast(updatedCards: ResponseType, toAllExcept sender: String) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			guard sender != id else { return }
			socket.send(data)
		}
	}
	
	func broadcast(updatedCards: ResponseType) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			socket.send(data)
		}
	}
}
