//
//  WebSocketType.swift
//  App
//
//  Created by Oliver Dew on 06/11/2018.
//

import Vapor

public protocol WebSocketType: AnyObject {
	func onText(_ callback: @escaping (WebSocketType, String) -> ())
	func send(_ binary: Data, promise: Promise<Void>?)
	func send<S>(_ text: S, promise: Promise<Void>?) where S: Collection, S.Element == Character
}

extension WebSocket: WebSocketType {
	public func onText(_ callback: @escaping (WebSocketType, String) -> ()) {
		onText(callback as ((WebSocket, String) -> ()))
	}
}
