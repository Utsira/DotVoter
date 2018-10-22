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
	
	func add(connection: WebSocket, sender: String) {
		connections[sender] = connection
	}
	
	func broadcast(data: Data) { //, toAllExcept sender: String
		connections.forEach { (_, socket) in
			socket.send(data)
		}
	}
}
