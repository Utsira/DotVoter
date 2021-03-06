//
//  MockNIOWebSocketServer.swift
//  AppTests
//
//  Created by Oliver Dew on 06/11/2018.
//

import Vapor
import App

final class MockWebSocket {
	
	private var onTextCallback: (WebSocketType, String) -> () = { _, _ in }
	
	// MARK: - Client-side (Tests use these to test the server)
	
	var clientHandlesBinary: (Data) -> Void = {_ in }
	var clientHandlesText: (String) -> Void = {_ in }
	
	func clientSendsText(_ text: String) {
		onTextCallback(self, text)
	}
	
	func clientSendsEncodable<T: Encodable>(_ encodable: T) throws {
		let data = try JSONEncoder().encode(encodable)
		clientSendsText(String(data: data, encoding: .utf8)!)
	}
}

extension MockWebSocket: WebSocketType {
	func onText(_ callback: @escaping (WebSocketType, String) -> ()) {
		onTextCallback = callback
	}
	
	func send(_ binary: Data, promise: EventLoopPromise<Void>?) {
		clientHandlesBinary(binary)
	}
	
	func send<S>(_ text: S, promise: EventLoopPromise<Void>?) where S : Collection, S.Element == Character {
		clientHandlesText(text as! String)
	}
}
