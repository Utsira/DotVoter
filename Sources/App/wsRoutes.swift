//
//  wsRoutes.swift
//  App
//
//  Created by Oliver Dew on 20/10/2018.
//

import Vapor

public func wsRoutes(_ webSocketServer: NIOWebSocketServer) {
	let room = Room()
	room.cardManager.addTestCards()
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()
	
	webSocketServer.get("dotVote") { socket, req in
		let senderId = req.http.remotePeer.description
		room.add(connection: socket, sender: senderId)
		
		let payload = room.cardManager.partials
		let data = try encoder.encode(payload)
		socket.send(data)
		
		socket.onText { ws, text in
			guard let data = text.data(using: .utf8), let payload = try? decoder.decode(Update.self, from: data) else {
				ws.send("Bad payload")
				return
			}
			let outcome = room.cardManager.handle(payload: payload, author: senderId)
			switch outcome {
			case .success:
				do {
					try room.broadcast(updatedCards: room.cardManager.partials)
				} catch {
					ws.send(error.localizedDescription)
				}
			case .failure(let cardError):
				do {
					let errorEncoded = try encoder.encode(cardError)
					ws.send(errorEncoded)
				} catch {
					ws.send(cardError.localizedDescription)
				}
			}
		}
	}
}
