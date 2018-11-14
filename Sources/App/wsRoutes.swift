//
//  wsRoutes.swift
//  App
//
//  Created by Oliver Dew on 20/10/2018.
//

import Vapor

public func wsRoutes(_ webSocketServer: NIOWebSocketServer) {
	webSocketServer.get("vote", String.parameter, use: DotVoteRoomController.shared.openConnection)
}
