//
//  Card.swift
//  Async
//
//  Created by Oliver Dew on 18/10/2018.
//

import Vapor

struct PartialCard: Content, Equatable {
	let id: UUID
	var message: String
	let category: String
	let voteCount: Int

	func complete(with author: String) -> Card {
		return Card(id: id, author: author, message: message, category: category, voteCount: voteCount)
	}
}

struct Card: Content {
	let id: UUID
	let author: String
	let message: String
	let category: String
	var voteCount: Int
	
	var partial: PartialCard {
		return PartialCard(id: id, message: message, category: category, voteCount: voteCount)
	}
}
