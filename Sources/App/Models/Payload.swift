//
//  Payload.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation
import Vapor

struct Update: Content {
	enum Action: String, Codable {
		case new, edit, upVote, downVote
	}
	let action: Action
	let card: PartialCard
}
