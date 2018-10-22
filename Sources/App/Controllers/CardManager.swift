//
//  CardManager.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation

enum Result<T> {
	case success(T)
	case failure(String)
}

final class CardManager {
	
	private var cards = SafeDictionary<UUID, Card>()
	
	func handle(payload: Payload, author: String) -> Result<Card> {
		var card: Card
		switch payload.action {
		case .new:
			guard cards[payload.card.id] == nil else {
				return .failure("Card already exists")
			}
			card = payload.card.complete(with: author)
			card.voteCount = 0
		case .upVote:
			guard let retreived = cards[payload.card.id] else {
				return .failure("Card does not exist")
			}
			card = retreived
			card.voteCount += 1
		case .downVote:
			guard let retreived = cards[payload.card.id] else {
				return .failure("Card does not exist")
			}
			guard retreived.voteCount > 0 else {
				return .failure("Vote count can't be negative")
			}
			card = retreived
			card.voteCount -= 1
		case .resetVotes:
			
		case .edit:
			guard let retreived = cards[payload.card.id] else {
				return .failure("Card does not exist")
			}
			guard retreived.author == author else {
				return .failure("You cannot edit another user's card")
			}
			card = payload.card.complete(with: author)
			card.voteCount = retreived.voteCount
		}
		cards[payload.card.id] = card
		return .success(card)
	}
}
