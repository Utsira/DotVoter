@testable import App
@testable import Model
import Vapor
import Crypto
import XCTest
import class Foundation.Bundle

class RoutesTestCase: XCTestCase {
	
	enum Result<T> {
		case success(T), failure(Error)
	}
	
	struct NoResponseError: Error {
		let action: Update.Action
	}
	
	private let decoder = JSONDecoder()
	private let encoder = JSONEncoder()
	
	override func setUp() {
		super.setUp()
		Room.shared.cardManager.addTestCards()
	}
	
	func newSocket() throws -> MockWebSocket {
		let socket = MockWebSocket()
		try SocketController.openConnection(socket: socket, senderId: UUID().uuidString)
		return socket
	}
	
	@discardableResult
	func performAction(_ action: Update.Action, on partial: PartialCard, with socket: MockWebSocket) throws -> PartialCard {
		var updated: Result<PartialCard> = .failure(NoResponseError(action: action))
		
		socket.clientHandlesBinary = { data in
			updated = self.didData(data, containCard: partial, matchingOn: \.message)
		}
		let payload = Update(action: action, card: partial)
		try socket.clientSendsEncodable(payload)
		switch updated {
			case .success(let match):
				return match
			case .failure(let error):
				throw error
		}
	}
	
	// MARK: - Data parsing
	
	func didResponse<T: Equatable>(_ response: ResponseType, containCard expectedCard: PartialCard, matchingOn keypath: KeyPath<PartialCard, T>) -> Result<PartialCard> {
		switch response {
		case .failure(let error):
			return .failure(error)
		case .success(let cards):
			guard let match = cards.first(where: { card in
				return card[keyPath: keypath] == expectedCard[keyPath: keypath]}) else {
					return .failure(CardError.cardCouldNotBeFound)
			}
			return .success(match)
		}
	}
	
	func didData<T: Equatable>(_ data: Data, containCard expectedCard: PartialCard, matchingOn keypath: KeyPath<PartialCard, T>) -> Result<PartialCard> {
		do {
			let result = try decoder.decode(ResponseType.self, from: data)
			return didResponse(result, containCard: expectedCard, matchingOn: keypath)
		} catch {
			return .failure(error)
		}
	}
	
	//MARK: - Tests
	
	func testResultSuccess() throws {
		let partial = PartialCard(id: UUID(), message: "howdy", category: "doody", voteCount: 1)
		let result: ResponseType = .success([partial])
		let resultEncoded = try encoder.encode(result)
		let resultDecoded = try decoder.decode(ResponseType.self, from: resultEncoded)
		XCTAssertEqual(result, resultDecoded)
	}
	
	func testNewCard() throws {
		do {
			let socket = try newSocket()
			let partial = PartialCard(id: UUID(), message: "new card", category: "default", voteCount: 0)
			let result = try performAction(.new, on: partial, with: socket)
			XCTAssertNotNil(result)
		} catch {
			XCTFail(String(describing: error))
		}
	}
	
	func testUpVoteCard() {
		do {
			let socket = try newSocket()
			var partial = PartialCard(id: UUID(), message: "upvote card", category: "default", voteCount: 0)
			partial = try performAction(.new, on: partial, with: socket)
			let result = try performAction(.upVote, on: partial, with: socket)
			XCTAssertEqual(result.voteCount, partial.voteCount + 1)
		} catch {
			XCTFail(String(describing: error))
		}
	}
	
	func testEditCard() {
		do {
			let socket = try newSocket()
			var partial = PartialCard(id: UUID(), message: "edit card", category: "default", voteCount: 0)
			partial = try performAction(.new, on: partial, with: socket)
			var updated = partial
			updated.message = "wowzers"
			let result = try performAction(.edit, on: updated, with: socket)
			XCTAssertEqual(result.message, updated.message)
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testCannotAddSameCardTwice() {
		do {
			let socket = try newSocket()
			var partial = PartialCard(id: UUID(), message: "Cannot add same card twice", category: "default", voteCount: 0)
			partial = try performAction(.new, on: partial, with: socket)
			do {
				try performAction(.new, on: partial, with: socket)
				XCTFail("should've thrown")
			} catch let error as CardError {
				XCTAssertEqual(error, .cardAlreadyExists)
			}
		} catch {
			XCTFail(String(describing: error))
		}
	}

	func testCannotUpvoteNonExistentCard() {
		do {
			let socket = try newSocket()
			let partial = PartialCard(id: UUID(), message: "Cannot upvote nonexistant", category: "default", voteCount: 0)
			do {
				try performAction(.upVote, on: partial, with: socket)
				XCTFail("should've thrown")
			} catch let error as CardError {
				XCTAssertEqual(error, .cardCouldNotBeFound)
			}
		} catch {
			XCTFail(String(describing: error))
		}
	}
	
	func testCannotDownvoteCardAtZeroVotes() {
		do {
			let socket = try newSocket()
			var partial = PartialCard(id: UUID(), message: "Cannot downvote past zero", category: "default", voteCount: 1)
			partial = try performAction(.new, on: partial, with: socket)
			partial = try performAction(.upVote, on: partial, with: socket)
			partial = try performAction(.downVote, on: partial, with: socket)
			do {
				try performAction(.downVote, on: partial, with: socket)
				XCTFail("should've thrown")
			} catch let error as CardError {
				XCTAssertEqual(error, .cardCannotBeDownVotedBelowOne)
			}
		} catch {
			XCTFail(String(describing: error))
		}
	}
}

extension Result: Equatable {
	static public func == (lhs: Result<T, E>, rhs: Result<T, E>) -> Bool {
		switch (lhs, rhs) {
		case (.success(let lhv), .success(let rhv)):
			return lhv == rhv
		case (.failure(let lhv), .failure(let rhv)):
			return lhv == rhv
		default:
			return false
		}
	}
}
