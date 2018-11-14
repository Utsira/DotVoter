//
//  DotVoteRoomController.swift
//  App
//
//  Created by Oliver Dew on 14/11/2018.
//

import Foundation

final class DotVoteRoomController: RoomController {
	
	typealias R = DotVoteRoom
	let rooms = SafeDictionary<String, DotVoteRoom>()
	
	static let shared = DotVoteRoomController()
	
	private init() {
		let demoRoom = DotVoteRoom()
		demoRoom.resetAndAddTestCards()
		rooms["autumn-event"] = demoRoom
	}
}
