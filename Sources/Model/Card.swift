//
//  Card.swift
//  Model
//
//  Created by Oliver Dew on 18/10/2018.
//

import Foundation

public struct PartialCard: Codable, Equatable {
	public let id: UUID?
	public var message: String
	public let category: String
	public let voteCount: Int

	public init(id: UUID?, message: String, category: String, voteCount: Int) {
		self.id = id
		self.message = message
		self.category = category
		self.voteCount = voteCount
	}

	public func complete(with author: String, id: UUID) -> Card {
		return Card(id: id, author: author, message: message, category: category, voteCount: voteCount)
	}
}

public final class Card: Codable {
	public let id: UUID
	public let author: String
	public var message: String
	public var category: String
	public var voteCount: Int
	
	public init(id: UUID, author: String, message: String, category: String, voteCount: Int) {
		self.id = id
		self.author = author
		self.message = message
		self.category = category
		self.voteCount = voteCount
	}
	
	public var partial: PartialCard {
		return PartialCard(id: id, message: message, category: category, voteCount: voteCount)
	}
}
