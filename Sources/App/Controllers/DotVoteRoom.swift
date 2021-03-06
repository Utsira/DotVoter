//
//  DotVoteRoom.swift
//  App
//
//  Created by Oliver Dew on 14/11/2018.
//

import Foundation
import Model

final class DotVoteRoom: Room {
	typealias T = ResponseType
	var connections = SafeDictionary<String, WebSocketType>()
	let encoder = JSONEncoder()
	
	private let decoder = JSONDecoder()
	private let cardManager = CardManager()
	
	func onText(socket: WebSocketType, text: String, senderId: String) {
		guard let data = text.data(using: .utf8),
			let payload = try? decoder.decode(Update.self, from: data)
			else {
				socket.send("Bad payload", promise: nil)
				return
		}
		
		let outcome = cardManager.handle(payload: payload, author: senderId)
		
		do {
			try handleOutcome(outcome, socket: socket)
		} catch {
			socket.send(error.localizedDescription, promise: nil)
		}
	}
	
	func onConnection(socket: WebSocketType) throws {
		let payload: ResponseType = .success(cardManager.partials)
		let data = try encoder.encode(payload)
		socket.send(data, promise: nil)
	}
	
	private func handleOutcome(_ outcome: ResponseType, socket: WebSocketType) throws {
		switch outcome {
		case .success:
			try broadcast(payload: outcome)
		case .failure:
			let errorEncoded = try encoder.encode(outcome)
			socket.send(errorEncoded, promise: nil)
		}
	}
	
	func resetAndAddTestCards() {
		cardManager.resetAndAddTestCards()
	}
}
