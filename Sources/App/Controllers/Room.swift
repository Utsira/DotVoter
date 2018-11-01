//
//  Room.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation
import Vapor

final class Room {
	private var connections = SafeDictionary<String, WebSocket>()
	let cardManager = CardManager()
	private let encoder = JSONEncoder()
	
	func add(connection: WebSocket, sender: String) {
		connections[sender] = connection
	}
	
	func broadcast(updatedCards: [PartialCard], toAllExcept sender: String) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			guard sender != id else { return }
			socket.send(data)
		}
	}
	
	func broadcast(updatedCards: [PartialCard]) throws {
		let data = try encoder.encode(updatedCards)
		connections.forEach { (id, socket) in
			socket.send(data)
		}
	}
}
