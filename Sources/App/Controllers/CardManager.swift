//
//  CardManager.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation

final class CardManager {
	
	enum Error: String, Swift.Error, Codable {
		case cardAlreadyExists, cardCouldNotBeFound, cardCannotBeDownVotedBelowOne, cardCanOnlyBeEditedByAuthor
	}
	
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
	
	func addTestCards() {
		let partials = [
			PartialCard(id: nil, message: "I miss the sofas in Bader", category: "sad", voteCount: 1),
			PartialCard(id: nil, message: "iOS social is coming up", category: "glad", voteCount: 2),
			PartialCard(id: nil, message: "Apple's prices are up 20%", category: "mad", voteCount: 1),
			PartialCard(id: nil, message: "I cracked the back of my iPhone XR", category: "sad", voteCount: 1),
			PartialCard(id: nil, message: "There's still a camera bump", category: "sad", voteCount: 2),
			PartialCard(id: nil, message: "Just 31 sleeps 'til Xmas", category: "glad", voteCount: 1),
			PartialCard(id: nil, message: "TAB showing up a lot in iOS Goodies", category: "glad", voteCount: 1),
			PartialCard(id: nil, message: "My UITests passed on 3rd retry", category: "glad", voteCount: 1),
			PartialCard(id: nil, message: "It's 2018 and there're still no hoverboards", category: "mad", voteCount: 1)
		]
//		let partials = (0..<10).map { i in
//			PartialCard(id: nil, message: "test blah \(i)", category: ["mad", "sad", "glad"].randomElement() ?? "", voteCount: Int.random(in: 0..<6))
//		}
		cards.removeAll()
		partials.forEach { card in
			cards.append(card.complete(with: UUID().uuidString, id: UUID()))
		}
	}
}
