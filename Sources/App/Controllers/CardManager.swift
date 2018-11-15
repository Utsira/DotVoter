//
//  CardManager.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation
import Model

final class CardManager {

	private let cards = SafeArray<Card>()
	
	var partials: [PartialCard] {
		return cards.array.map { $0.partial }
	}
	
	func handle(payload: Update, author: String) -> ResponseType {
		switch payload.action {
		case .new:
			guard !cards.contains(where: {$0.id == payload.card.id}) else { return .failure(.cardAlreadyExists) }
			let new = payload.card.complete(with: author, id: UUID())
			cards.append(new)
		case .upVote:
			guard let card = cards.first(where: {$0.id == payload.card.id}) else { return .failure(.cardCouldNotBeFound) }
				card.voteCount += 1
		case .downVote:
			guard let card = cards.first(where: {$0.id == payload.card.id}) else { return .failure(.cardCouldNotBeFound) }
			guard card.voteCount > 1 else { return .failure(.cardCannotBeDownVotedBelowOne)}
			card.voteCount -= 1
		case .edit:
			guard let card = cards.first(where: {$0.id == payload.card.id}) else { return .failure(.cardCouldNotBeFound) }
			guard card.author == author else { return .failure(.cardCanOnlyBeEditedByAuthor)}
			card.message = payload.card.message
		}
		return .success(partials)
	}
	
	func reset() {
		cards.removeAll()
	}
	
	func resetAndAddTestCards() {
		reset()
		let partials = [
			PartialCard(id: nil, message: "That one slide with the ComicSans 🤦‍♂️", category: "mad", voteCount: 3),
			PartialCard(id: nil, message: "Still using Intel silicon in 🖥", category: "mad", voteCount: 2),
			PartialCard(id: nil, message: "I don't have to plug the ✏️ into the ⚡️ port anymore", category: "glad", voteCount: 1),
			PartialCard(id: nil, message: "Prices 📈 20% across the board", category: "glad", voteCount: 2),
			PartialCard(id: nil, message: "♻️ Aluminum!", category: "glad", voteCount: 2)
		]
		partials.forEach { card in
			cards.append(card.complete(with: UUID().uuidString, id: UUID()))
		}
	}
}
