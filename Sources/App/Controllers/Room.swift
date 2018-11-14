//
//  Room.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation
import Vapor

class Room<T: Encodable> {
	
	private var connections = SafeDictionary<String, WebSocketType>()
	private let encoder = JSONEncoder()
	
	func add(connection: WebSocketType, sender: String) {
		connections[sender] = connection
	}
	
	func sender(for socket: WebSocketType) -> String? {
		return connections.first(where: {
			let (_, value) = $0
			return value === socket
		})?.key
	}
	
	func broadcast(updatedCards: T, toAllExcept sender: String) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			guard sender != id else { return }
			socket.send(data, promise: nil)
		}
	}
	
	func broadcast(updatedCards: T) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			socket.send(data, promise: nil)
		}
	}
}
