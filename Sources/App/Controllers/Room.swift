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
	
	private var connections = SafeDictionary<String, WebSocketType>()
	let cardManager = CardManager()
	private let encoder = JSONEncoder()
	
	private init() {}
	
	func add(connection: WebSocketType, sender: String) {
		connections[sender] = connection
	}
	
	func sender(for socket: WebSocketType) -> String? {
		return connections.first(where: {
			let (_, value) = $0
			return value === socket
		})?.key
	}
	
	func broadcast(updatedCards: ResponseType, toAllExcept sender: String) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			guard sender != id else { return }
			socket.send(data, promise: nil)
		}
	}
	
	func broadcast(updatedCards: ResponseType) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			socket.send(data, promise: nil)
		}
	}
}
