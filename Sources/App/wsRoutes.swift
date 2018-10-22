//
//  wsRoutes.swift
//  App
//
//  Created by Oliver Dew on 20/10/2018.
//

import Vapor

public func wsRoutes(_ webSocketServer: NIOWebSocketServer) {
	let room = Room()
	let encoder = JSONEncoder()
	let decoder = JSONDecoder()
	
	webSocketServer.get("dotVote") { socket, req in
		let senderId = req.http.remotePeer.description
		room.add(connection: socket, sender: senderId)
		
		socket.onText { ws, text in
			ws.send("You said \(text)")
			
		}
		socket.onBinary { ws, data in
			guard let payload = try? decoder.decode(Payload.self, from: data) else {
				ws.send("Bad payload")
				return
			}
			let outcome = room.cardManager.handle(payload: payload, author: senderId)
			switch outcome {
			case .success(let card):
				guard let encodedCard = try? encoder.encode(card.partial) else {
					ws.send("Could not format return value")
					return
				}
				room.broadcast(data: encodedCard)
			case .failure(let message):
				ws.send(message)
			}
		}
	}
}
