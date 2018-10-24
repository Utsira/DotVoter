@testable import App
import Vapor
import Crypto
import XCTest
import class Foundation.Bundle

@available(OSX 10.13, *)
class RoutesTestCase: XCTestCase {
	
	enum HTTPMethod: String {
		case get = "GET"
		case post = "POST"
	}
	
	private let process = Process()
	let pipe = Pipe()
	private let decoder = JSONDecoder()
	private let encoder = JSONEncoder()
	
	override func setUp() {
		let binary = productsDirectory.appendingPathComponent("Run")
		process.executableURL = binary
		process.standardOutput = pipe
		do {
			try process.run()
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	override func tearDown() {
		process.terminate()
		process.waitUntilExit()
	}
	
	/// Returns path to the built products directory.
	private var productsDirectory: URL {
		#if os(macOS)
		return Bundle(for: RoutesTestCase.self).bundleURL.deletingLastPathComponent()
		#else
		return Bundle.main.bundleURL
		#endif
	}
	
	func makeRequest(_ path: String, method: HTTPMethod, body: Data? = nil, headers: [String: String] = [:], completion: ((Data, HTTPURLResponse) throws -> Void)?) {
		var components = URLComponents()
		components.scheme = "http"
		components.host = "localhost"
		components.port = 8080
		components.path = path
		guard let url = components.url else { return }
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.httpBody = body
		request.allHTTPHeaderFields = headers
		let task = URLSession.shared.dataTask(with: request) { data, response, error
			in
			if let error = error {
				XCTFail(error.localizedDescription)
				return
			}
			guard let data = data, let response = response as? HTTPURLResponse else {
				XCTFail("No data")
				return
			}
			do {
				try completion?(data, response)
			} catch {
				XCTFail(error.localizedDescription)
			}
		}
		task.resume()
	}
	
	func socketAccept(for key: String) throws -> String {
		let concat = "\(key)258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
		let hash = try SHA1.hash(concat)
		return hash.base64EncodedString()
	}
	
	func testWsHandshake() throws {
		let await = expectation(description: "request upgraded")
		let myKey = "mysecretkey"
		let acceptance = try socketAccept(for: myKey)
		let headers = [
			"Connection": "Upgrade",
			"Upgrade": "websocket",
			"Host": "localhost",
			"Origin": "http://localhost:8080",
			"Sec-WebSocket-Key": myKey,
			"Sec-WebSocket-Version": "13"
		]
		makeRequest("/dotVote", method: .get, headers: headers) { data, response in
			XCTAssertEqual(response.allHeaderFields["Upgrade"] as? String, "websocket")
			XCTAssertEqual(response.allHeaderFields["Sec-WebSocket-Accept"] as? String, acceptance)
			await.fulfill()
		}
		
		waitForExpectations(timeout: 5)
	}
	
	func openSocket() throws -> WebSocket {
		let worker = MultiThreadedEventLoopGroup(numberOfThreads: 2)
		return try HTTPClient.webSocket(scheme: .http, hostname: "localhost", port: 8080, path: "/dotVote", headers: .init(), maxFrameSize: 1 << 14, on: worker).wait()
	}
	
	func readdNewCard(_ partial: PartialCard, socket: WebSocket) throws {
		let await = expectation(description: "will receive response from server")
		let awaitEmpty = expectation(description: "will receive response from server")
		let payload = Payload(action: .new, cards: [partial])
		let data = try encoder.encode(payload)
		socket.onBinary { socket, data in
			if String(data: data, encoding: .utf8) == "[]" {
				awaitEmpty.fulfill()
				return
			}
			if let cards = try? self.decoder.decode([PartialCard].self, from: data) {
				XCTAssertEqual(cards, [partial])
				await.fulfill()
				return
			}
			
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
		socket.send(data)
		wait(for: [awaitEmpty], timeout: 5)
	}
	
	func addNewCards(_ partials: [PartialCard], socket: WebSocket) throws {
		let await = expectation(description: "will receive response from server")
		let payload = Payload(action: .new, cards: partials)
		let data = try encoder.encode(payload)
		socket.onBinary { socket, data in
			guard let cards = try? self.decoder.decode([PartialCard].self, from: data) else {
				XCTFail("couldn't decipher response")
				return
			}
			XCTAssertEqual(cards, partials)
			await.fulfill()
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
	}
	
	@discardableResult
	func upvoteCards(_ partials: [PartialCard], socket: WebSocket) throws -> [PartialCard] {
		let await = expectation(description: "will receive response from server")
		let payload = Payload(action: .upVote, cards: partials)
		let data = try encoder.encode(payload)
		var updated = partials
		socket.onBinary { socket, data in
			guard let cards = try? self.decoder.decode([PartialCard].self, from: data) else {
				XCTFail("couldn't decipher response")
				return
			}
			XCTAssertEqual(cards[0].voteCount, partials[0].voteCount + 1)
			updated = cards
			await.fulfill()
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
		return updated
	}
	
	@discardableResult
	func downvoteCards(_ partials: [PartialCard], socket: WebSocket) throws -> [PartialCard] {
		let await = expectation(description: "will receive response from server")
		let payload = Payload(action: .downVote, cards: partials)
		let data = try encoder.encode(payload)
		var updated = partials
		socket.onBinary { socket, data in
			guard let cards = try? self.decoder.decode([PartialCard].self, from: data) else {
				XCTFail("couldn't decipher response")
				return
			}
			XCTAssertEqual(cards[0].voteCount, partials[0].voteCount - 1)
			updated = cards
			await.fulfill()
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
		return updated
	}
	
	@discardableResult
	func editCards(_ partials: [PartialCard], socket: WebSocket) throws -> [PartialCard] {
		let await = expectation(description: "will receive response from server")
		var partials = partials.map { partial -> PartialCard in
			var new = partial
			new.message = "wowzers"
			return new
		}
		let payload = Payload(action: .edit, cards: partials)
		let data = try encoder.encode(payload)
		var updated = partials
		socket.onBinary { socket, data in
			guard let cards = try? self.decoder.decode([PartialCard].self, from: data) else {
				XCTFail("couldn't decipher response")
				return
			}
			XCTAssertEqual(cards, partials)
			updated = cards
			await.fulfill()
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
		return updated
	}
	
	func testWsOnText() throws {
		let socket = try openSocket()
		let await = expectation(description: "will receive response from server")
		socket.onText { ws, text in
			XCTAssertEqual(text, "You said hiya")
			await.fulfill()
		}
		socket.send("hiya")
		wait(for: [await], timeout: 5)
		socket.close()
	}
	
	func testNewCard() throws {
		let socket = try openSocket()
		let partial = PartialCard(id: UUID(), message: "Hi there", category: "default", voteCount: 0)
		try addNewCards([partial], socket: socket)
		socket.close()
	}
	
	func testUpVoteCard() throws {
		let socket = try openSocket()
		let partial = PartialCard(id: UUID(), message: "Hi there", category: "default", voteCount: 0)
		try addNewCards([partial], socket: socket)
		try upvoteCards([partial], socket: socket)
		socket.close()
	}
	
	func testEditCard() throws {
		let socket = try openSocket()
		let partial = PartialCard(id: UUID(), message: "Hi there", category: "default", voteCount: 0)
		try addNewCards([partial], socket: socket)
		try editCards([partial], socket: socket)
		socket.close()
	}
	
	func testCannotAddSameCardTwice() throws {
		let socket = try openSocket()
		let partial = PartialCard(id: UUID(), message: "Hi there", category: "default", voteCount: 0)
		try readdNewCard(partial, socket: socket)
		socket.close()
	}
	
	func testCannotUpvoteNonExistentCard() throws {
		let socket = try openSocket()
		let await = expectation(description: "will receive response from server")
		let partial = PartialCard(id: UUID(), message: "Hi there", category: "default", voteCount: 0)
		let payload = Payload(action: .upVote, cards: [partial])
		let data = try encoder.encode(payload)
		socket.onBinary { socket, data in
			XCTAssertEqual(String(data: data, encoding: .utf8), "[]")
			await.fulfill()
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
	}
	
	func testCannotDownvoteCardAtZeroVotes() throws {
		let socket = try openSocket()
		var partials = [PartialCard(id: UUID(), message: "Hi there", category: "default", voteCount: 0)]
		try addNewCards(partials, socket: socket)
		partials = try upvoteCards(partials, socket: socket)
		partials = try downvoteCards(partials, socket: socket)
		
		let await = expectation(description: "will receive response from server")
		let payload = Payload(action: .downVote, cards: partials)
		let data = try encoder.encode(payload)
		socket.onBinary { socket, data in
			XCTAssertEqual(String(data: data, encoding: .utf8), "[]")
			await.fulfill()
		}
		socket.send(data)
		wait(for: [await], timeout: 5)
		
		socket.close()
	}
}
