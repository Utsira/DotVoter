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

final class Card: Content {
	let id: UUID
	let author: String
	var message: String
	var category: String
	var voteCount: Int
	
	init(id: UUID, author: String, message: String, category: String, voteCount: Int) {
		self.id = id
		self.author = author
		self.message = message
		self.category = category
		self.voteCount = voteCount
	}
	
	var partial: PartialCard {
		return PartialCard(id: id, message: message, category: category, voteCount: voteCount)
	}
}
