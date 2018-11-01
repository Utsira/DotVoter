//
//  CardManager.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation

enum Result<T> {
	case success(T)
	case failure(Error)
}

final class CardManager {
	
	enum Error: Swift.Error {
		case cardAlreadyExists, cardCouldNotBeFound, cardCannotBeDownVotedBelowZero, cardCanOnlyBeEditedByAuthor
	}
	
	private let cards = SafeArray<Card>()
	
	var partials: [PartialCard] {
		return cards.array.map { $0.partial }
	}
	
	func handle(payload: Update, author: String) -> Result<Card> {
		switch payload.action {
		case .new:
			guard !cards.contains(where: {$0.id == payload.card.id}) else { return .failure(Error.cardAlreadyExists) }
			let new = payload.card.complete(with: author, id: UUID())
			cards.append(new)
			return .success(new)
		case .upVote:
			guard let card = cards.first(where: {$0.id == payload.card.id}) else { return .failure(Error.cardCouldNotBeFound) }
				card.voteCount += 1
			return .success(card)
		case .downVote:
			guard let card = cards.first(where: {$0.id == payload.card.id}) else { return .failure(Error.cardCouldNotBeFound) }
			guard card.voteCount > 0 else { return .failure(Error.cardCannotBeDownVotedBelowZero)}
			card.voteCount -= 1
			return .success(card)
		case .edit:
			guard let card = cards.first(where: {$0.id == payload.card.id}) else { return .failure(Error.cardCouldNotBeFound) }
			guard card.author == author else { return .failure(Error.cardCanOnlyBeEditedByAuthor)}
			card.message = payload.card.message
			return .success(card)
		}
	}
	
	func addTestCards() {
		let partials = (0..<10).map { i in
			PartialCard(id: nil, message: "test blah \(i)", category: "hi", voteCount: Int.random(in: 0..<6))
		}
		partials.forEach { card in
			cards.append(card.complete(with: UUID().uuidString, id: UUID()))
		}
	}
}
