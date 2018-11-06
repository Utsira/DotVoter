//
//  Application+Testable.swift
//  AppTests
//
//  Created by Oliver Dew on 05/11/2018.
//

import Vapor

extension Application {
	
	func hitws() throws {
		let responder = try self.make(WebSocketResponder.self)
		
	}
	func sendRequest<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), body: T? = nil) throws -> Response where T: Content {
		let responder = try self.make(Responder.self)
		let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
		let wrappedRequest = Request(http: request, using: self)
		if let body = body {
			try wrappedRequest.content.encode(body)
		}
		return try responder.respond(to: wrappedRequest).wait()
	}
	
	func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type) throws -> T where T: Decodable {
		let emptyContent: String? = nil
		let response = try self.sendRequest(to: path, method: method, headers: headers, body: emptyContent)
		return try response.content.decode(type).wait()
	}
}

struct EmptyContent: Content {}
