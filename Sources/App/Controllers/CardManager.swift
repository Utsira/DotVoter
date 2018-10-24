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
	
	var cards = SafeDictionary<UUID, Card>()
	
	func handle(payload: Payload, author: String) -> Result<Payload> {
		let newOrUpdatedCards: [PartialCard]
		switch payload.action {
		case .new:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard cards[partial.id] == nil else { return nil }
				let new = partial.complete(with: author)
				cards[partial.id] = new
				return partial
			}
		case .upVote:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard var card = cards[partial.id] else { return nil }
				card.voteCount += 1
				cards[partial.id] = card
				return card.partial
			}
		case .downVote:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard var card = cards[partial.id],
					card.voteCount > 0
					else { return nil }
				card.voteCount -= 1
				cards[partial.id] = card
				return card.partial
			}
		case .edit:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard let card = cards[partial.id],
					card.author == author
					else { return nil }
				cards[partial.id] = partial.complete(with: author)
				return partial
			}
		}
		return .success(Payload(action: payload.action, cards: newOrUpdatedCards))
	}
}
