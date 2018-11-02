//
//  Update.swift
//  App
//
//  Created by Oliver Dew on 22/10/2018.
//

import Foundation

public struct Update: Codable {
	public enum Action: String, Codable {
		case new, edit, upVote, downVote
	}
	public let action: Action
	public let card: PartialCard
}
