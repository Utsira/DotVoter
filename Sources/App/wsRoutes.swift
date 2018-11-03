//
//  wsRoutes.swift
//  App
//
//  Created by Oliver Dew on 20/10/2018.
//

import Vapor

public func wsRoutes(_ webSocketServer: NIOWebSocketServer) {
	let room = Room.shared
	room.cardManager.addTestCards()
	webSocketServer.get("dotVote", use: SocketController.openConnection)
}
