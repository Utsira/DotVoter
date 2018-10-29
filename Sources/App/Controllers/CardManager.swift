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
	
	var cards = SafeArray<Card>()
	
	func handle(payload: Payload, author: String) -> Result<Payload> {
		let newOrUpdatedCards: [PartialCard]
		switch payload.action {
		case .new:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard !cards.contains(where: {$0.id == partial.id}) else { return nil }
				let new = partial.complete(with: author, id: UUID())
				cards.append(new)
				return partial
			}
		case .upVote:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard let card = cards.first(where: {$0.id == partial.id}) else { return nil }
				card.voteCount += 1
				return card.partial
			}
		case .downVote:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard let card = cards.first(where: {$0.id == partial.id}),
					card.voteCount > 0
					else { return nil }
				card.voteCount -= 1
				return card.partial
			}
		case .edit:
			newOrUpdatedCards = payload.cards.compactMap { partial in
				guard let card = cards.first(where: {$0.id == partial.id}),
					card.author == author
					else { return nil }
				card.message = partial.message
				return partial
			}
		}
		return .success(Payload(action: payload.action, cards: newOrUpdatedCards))
	}
}
