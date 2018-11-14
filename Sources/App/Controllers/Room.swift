//
//  Room.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation
import Vapor

protocol Room {
	associatedtype T: Encodable
	
	var connections: SafeDictionary<String, WebSocketType> { get }
	var encoder: JSONEncoder { get }
	
	init()
	func onConnection(socket: WebSocketType) throws
	func onText(socket: WebSocketType, text: String, senderId: String)
}

extension Room {
	
	func add(connection: WebSocketType, sender: String) {
		connections[sender] = connection
	}
	
	func sender(for socket: WebSocketType) -> String? {
		return connections.first(where: {
			let (_, value) = $0
			return value === socket
		})?.key
	}
	
	func broadcast(payload: T, toAllExcept sender: String) throws {
		let data = try encoder.encode(payload)
		connections.forEach { (id, socket) in
			guard sender != id else { return }
			socket.send(data, promise: nil)
		}
	}
	
	func broadcast(payload: T) throws {
		let data = try encoder.encode(payload)
		connections.forEach { (id, socket) in
			socket.send(data, promise: nil)
		}
	}
}
