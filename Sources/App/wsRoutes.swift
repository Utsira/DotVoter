//
//  wsRoutes.swift
//  App
//
//  Created by Oliver Dew on 20/10/2018.
//

import Vapor

public func wsRoutes(_ webSocketServer: NIOWebSocketServer) {
	let room = Room()
	addTestCards(to: room)
	let encoder = JSONEncoder()
	let decoder = JSONDecoder()
	
	webSocketServer.get("dotVote") { socket, req in
		let senderId = req.http.remotePeer.description
		room.add(connection: socket, sender: senderId)
		
		let payload = Payload(action: .new, cards: room.cardManager.cards.array.map{ $0.partial
		})
		let data = try encoder.encode(payload)
		socket.send(data)
		socket.onText { ws, text in
			guard let data = text.data(using: .utf8), let payload = try? decoder.decode(Payload.self, from: data) else {
				ws.send("Bad payload")
				return
			}
			let outcome = room.cardManager.handle(payload: payload, author: senderId)
			switch outcome {
			case .success(let payload):
				guard let payloadData = try? encoder.encode(payload) else {
					ws.send("Could not format return value")
					return
				}
				room.broadcast(data: payloadData)
			case .failure(let message):
				ws.send(message)
			}
		}
	}
}

func addTestCards(to room: Room) {
	let cards = (0..<10).map { i in
		PartialCard(id: UUID(), message: "test blah \(i)", category: "hi", voteCount: i)
	}
	cards.forEach { card in
		room.cardManager.cards.append(card.complete(with: UUID().uuidString))
	}
}
