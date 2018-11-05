@testable import App
@testable import Model
import Vapor
import Crypto
import XCTest
import class Foundation.Bundle

class RoutesTestCase: XCTestCase {
	
	//MARK: - Static
	
	private static let process = Process()
	private static let port = 5000
	
	override static func setUp() {
		super.setUp()
		let binary = productsDirectory.appendingPathComponent("Run")
		if #available(OSX 10.13, *) {
			#if os(macOS)
			process.executableURL = binary
			#endif
		} else {
			process.launchPath = binary.path
		}
		process.arguments = ["--port", "\(port)"]
		do {
			if #available(OSX 10.13, *) {
				#if os(macOS)
				try process.run()
				#endif
			} else {
				process.launch()
			}
		} catch {
			XCTFail(error.localizedDescription)
		}
	}
	
	override static func tearDown() {
		shutdownServer()
		#if os(macOS)
		process.terminate()
		process.waitUntilExit()
		#endif
		super.tearDown()
	}
	
	/// Returns path to the built products directory.
	private static var productsDirectory: URL {
		#if os(macOS)
		return Bundle(for: RoutesTestCase.self).bundleURL.deletingLastPathComponent()
		#else
		return Bundle.main.bundleURL
		#endif
	}
	
	static func shutdownServer() {
		makeRequest("/shutdown", method: .get)
	}
	
	// MARK: - Instance
	
	enum HTTPMethod: String {
		case get = "GET"
		case post = "POST"
	}
	
	private let decoder = JSONDecoder()
	private let encoder = JSONEncoder()
	
	func resetServer() {
		let expect = TestExpectation(description: "wait for shutdown")
		RoutesTestCase.makeRequest("/resetWithTests", method: .get) { result in
			switch result {
			case .success(_, let response) where 200..<300 ~= response.statusCode:
				expect.fulfill()
			case .failure(let error):
				XCTFail(error.localizedDescription)
			default:
				XCTFail("bad request")
			}
		}
		expect.wait(timeout: 5)
	}
	
	enum Result<T> {
		case success(T), failure(Error)
	}
	
	struct noResponseError: Error {}
	
	static func makeRequest(_ path: String, method: HTTPMethod, body: Data? = nil, headers: [String: String] = [:], completion: ((Result<(Data?, HTTPURLResponse)>) -> Void)? = nil) {
		var components = URLComponents()
		components.scheme = "http"
		components.host = "localhost"
		components.port = port
		components.path = path
		guard let url = components.url else { return }
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.httpBody = body
		request.allHTTPHeaderFields = headers
		let task = URLSession.shared.dataTask(with: request) { data, response, error
			in
			if let error = error {
				completion?(.failure(error))
				return
			}
			guard let response = response as? HTTPURLResponse else {
				completion?(.failure(noResponseError()))
				return
			}
			completion?(.success((data, response)))
			
		}
		task.resume()
	}
	
	func socketAccept(for key: String) throws -> String {
		let concat = "\(key)258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
		let hash = try SHA1.hash(concat)
		return hash.base64EncodedString()
	}
	
	//	func testWsHandshake() throws {
	//		let await = TestExpectation(description: "request upgraded")
	//		let myKey = "mysecretkey"
	//		let acceptance = try socketAccept(for: myKey)
	//		let headers = [
	//			"Connection": "Upgrade",
	//			"Upgrade": "websocket",
	//			"Host": "localhost",
	//			"Origin": "http://localhost:\(RoutesTestCase.port)",
	//			"Sec-WebSocket-Key": myKey,
	//			"Sec-WebSocket-Version": "13"
	//		]
	//		makeRequest("/dotVote", method: .get, headers: headers) { data, response in
	//			XCTAssertEqual(response.allHeaderFields["Upgrade"] as? String, "websocket")
	//			XCTAssertEqual(response.allHeaderFields["Sec-WebSocket-Accept"] as? String, acceptance)
	//			await.fulfill()
	//		}
	//
	//		waitForTestExpectations(timeout: 5)
	//	}
	
	func openSocket(file: StaticString = #file, line: UInt = #line) throws -> WebSocket {
		let worker = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		let socket = try HTTPClient.webSocket(scheme: .http, hostname: "localhost", port: RoutesTestCase.port, path: "/dotVote", headers: .init(), maxFrameSize: 1 << 14, on: worker).wait()
		let await = TestExpectation(description: "will receive response from server")
		
		socket.onBinary { socket, data in
			guard let result = try? self.decoder.decode(ResponseType.self, from: data), case .success = result else {
				XCTFail("no cards", file: file, line: line)
				return
			}
			await.fulfill()
		}
		await.wait(timeout: 5)
		return socket
	}
	
	func send(payload: Update, socket: WebSocket, file: StaticString = #file, line: UInt = #line) {
		guard let data = try? encoder.encode(payload),
			let string = String(data: data, encoding: .utf8) else {
				XCTFail("Couldn't parse payload", file: file, line: line)
				return
		}
		socket.send(string)
	}
	
	func readdNewCard(_ partial: PartialCard, socket: WebSocket, file: StaticString = #file, line: UInt = #line) throws {
		let await = TestExpectation(description: "will receive cards from server")
		let awaitError = TestExpectation(description: "will receive error cannot add same card twice")
		var updated = partial
		socket.onBinary { socket, data in
			print("^^^", String(data: data, encoding: .utf8)!)
			guard let result = try? self.decoder.decode(ResponseType.self, from: data) else {
				XCTFail("couldn't parse response", file: file, line: line)
				return
			}
			if let match = self.didResponse(result, containCard: partial, matchingOn: \.message, shouldFailTest: false, file: file, line: line) {
				updated = match
				await.fulfill()
				return
			}
			if self.didResponse(result, containError: .cardAlreadyExists, shouldFailTest: false) {
				awaitError.fulfill()
				return
			}
			XCTFail("dang", file: file, line: line)
		}
		let payload = Update(action: .new, card: partial)
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		let payload2 = Update(action: .new, card: updated)
		send(payload: payload2, socket: socket)
		awaitError.wait(timeout: 5)
	}
	
	@discardableResult
	func addNewCard(_ partial: PartialCard, socket: WebSocket, file: StaticString = #file, line: UInt = #line) throws -> PartialCard {
		let await = TestExpectation(description: "will receive response from server")
		let payload = Update(action: .new, card: partial)
		var updated = partial
		socket.onBinary { socket, data in
			guard let match = self.didData(data, containCard: partial, matchingOn: \.message) else { return }
			
			updated = match
			await.fulfill()
		}
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		return updated
	}
	
	@discardableResult
	func upvoteCard(_ partial: PartialCard, socket: WebSocket, file: StaticString = #file, line: UInt = #line) throws -> PartialCard {
		let await = TestExpectation(description: "will receive response from server")
		let payload = Update(action: .upVote, card: partial)
		var updated = partial
		socket.onBinary { socket, data in
			guard let match = self.didData(data, containCard: partial, matchingOn: \.id) else { return }
			XCTAssertEqual(match.voteCount, partial.voteCount + 1, file: file, line: line)
			updated = match
			await.fulfill()
		}
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		return updated
	}
	
	@discardableResult
	func downvoteCard(_ partial: PartialCard, socket: WebSocket, file: StaticString = #file, line: UInt = #line) throws -> PartialCard {
		let await = TestExpectation(description: "will receive response from server")
		let payload = Update(action: .downVote, card: partial)
		var updated = partial
		socket.onBinary { socket, data in
			guard let match = self.didData(data, containCard: partial, matchingOn: \.id) else { return }
			XCTAssertEqual(match.voteCount, partial.voteCount - 1, file: file, line: line)
			updated = match
			await.fulfill()
		}
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		return updated
	}
	
	@discardableResult
	func editCard(_ partial: PartialCard, socket: WebSocket, file: StaticString = #file, line: UInt = #line) throws -> PartialCard {
		let await = TestExpectation(description: "will receive response from server")
		var partial = partial
		partial.message = "wowzers"
		let payload = Update(action: .edit, card: partial)
		var updated = partial
		socket.onBinary { socket, data in
			guard let match = self.didData(data, containCard: partial, matchingOn: \.id) else { return }
			XCTAssertEqual(match.message, partial.message, file: file, line: line)
			updated = match
			await.fulfill()
		}
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		return updated
	}
	
	// MARK: - Data parsing
	
	func didResponse<T: Equatable>(_ response: ResponseType, containCard expectedCard: PartialCard, matchingOn keypath: KeyPath<PartialCard, T>, shouldFailTest: Bool = true, file: StaticString = #file, line: UInt = #line) -> PartialCard? {
		switch response {
		case .failure(let error):
			if shouldFailTest {
				XCTFail(error.localizedDescription, file: file, line: line)
			}
			return nil
		case .success(let cards):
			
			guard let match = cards.first(where: { card in
				return card[keyPath: keypath] == expectedCard[keyPath: keypath]}) else {
					if shouldFailTest {
						XCTFail("Card  not found", file: file, line: line)
					}
					return nil
			}
			return match
		}
	}
	
	func didData<T: Equatable>(_ data: Data, containCard expectedCard: PartialCard, matchingOn keypath: KeyPath<PartialCard, T>, file: StaticString = #file, line: UInt = #line) -> PartialCard? {
		guard let result = try? decoder.decode(ResponseType.self, from: data) else {
			XCTFail("Couldn't decipher data", file: file, line: line)
			return nil
		}
		return didResponse(result, containCard: expectedCard, matchingOn: keypath)
	}
	
	func didResponse(_ response: ResponseType, containError expectedError: CardError, shouldFailTest: Bool = true, file: StaticString = #file, line: UInt = #line) -> Bool {
		switch response {
		case .success:
			if shouldFailTest {
				XCTFail("Unexpectedly succeeded", file: file, line: line)
			}
			return false
		case .failure(let error):
			guard error == expectedError else {
				if shouldFailTest {
					XCTFail("Wrong error received: \(error.localizedDescription)", file: file, line: line)
				}
				return false
			}
			return true
		}
	}
	
	func didData(_ data: Data, containError expectedError: CardError, file: StaticString = #file, line: UInt = #line) -> Bool {
		guard let result = try? decoder.decode(ResponseType.self, from: data) else {
			XCTFail("Couldn't decipher data", file: file, line: line)
			return false
		}
		return didResponse(result, containError: expectedError, file: file, line: line)
	}
	
	//MARK: - Tests
	
	func testResultSuccess() throws {
		let partial = PartialCard(id: UUID(), message: "howdy", category: "doody", voteCount: 1)
		let result: ResponseType = .success([partial])
		let resultEncoded = try encoder.encode(result)
		let resultDecoded = try decoder.decode(ResponseType.self, from: resultEncoded)
		XCTAssertEqual(result, resultDecoded)
	}
	
	func testWsOnText() throws {
		let socket = try openSocket()
		let await = TestExpectation(description: "will receive response from server")
		socket.onText { ws, text in
			XCTAssertEqual(text, "Bad payload")
			await.fulfill()
		}
		socket.send("hiya")
		await.wait(timeout: 5)
		socket.close()
		resetServer()
	}
	
	func testNewCard() throws {
		let socket = try openSocket()
		let partial = PartialCard(id: UUID(), message: "new card", category: "default", voteCount: 0)
		try addNewCard(partial, socket: socket)
		socket.close()
		resetServer()
	}
	
	func testUpVoteCard() throws {
		let socket = try openSocket()
		var partial = PartialCard(id: UUID(), message: "upvote card", category: "default", voteCount: 0)
		partial = try addNewCard(partial, socket: socket)
		try upvoteCard(partial, socket: socket)
		socket.close()
		resetServer()
	}
	
	func testEditCard() throws {
		let socket = try openSocket()
		var partial = PartialCard(id: UUID(), message: "edit card", category: "default", voteCount: 0)
		partial = try addNewCard(partial, socket: socket)
		try editCard(partial, socket: socket)
		socket.close()
		resetServer()
	}
	
	func testCannotAddSameCardTwice() throws {
		let socket = try openSocket()
		let partial = PartialCard(id: UUID(), message: "Cannot add same card twice", category: "default", voteCount: 0)
		try readdNewCard(partial, socket: socket)
		socket.close()
		resetServer()
	}
	
	func testCannotUpvoteNonExistentCard() throws {
		let socket = try openSocket()
		let await = TestExpectation(description: "will receive response from server")
		let partial = PartialCard(id: UUID(), message: "Cannot upvote nonexistant", category: "default", voteCount: 0)
		let payload = Update(action: .upVote, card: partial)
		socket.onBinary { socket, data in
			if self.didData(data, containError: .cardCouldNotBeFound) {
				await.fulfill()
			}
		}
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		socket.close()
		resetServer()
	}
	
	func testCannotDownvoteCardAtZeroVotes() throws {
		let socket = try openSocket()
		var partial = PartialCard(id: UUID(), message: "Cannot downvote past zerp", category: "default", voteCount: 1)
		partial = try addNewCard(partial, socket: socket)
		partial = try upvoteCard(partial, socket: socket)
		partial = try downvoteCard(partial, socket: socket)
		
		let await = TestExpectation(description: "will receive response from server")
		let payload = Update(action: .downVote, card: partial)
		socket.onBinary { socket, data in
			if self.didData(data, containError: .cardCannotBeDownVotedBelowOne) {
				await.fulfill()
			}
		}
		send(payload: payload, socket: socket)
		await.wait(timeout: 5)
		socket.close()
		resetServer()
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
