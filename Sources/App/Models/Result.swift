//
//  Result.swift
//  App
//
//  Created by Oliver Dew on 01/11/2018.
//

import Foundation

typealias CodableError = Error & Codable & Equatable
typealias ResponseType = Result<[PartialCard], CardManager.Error>

enum Result<T: Codable & Equatable, E: CodableError> {
	case success(T)
	case failure(E)
}

extension Result: Codable {
	enum CodingKeys: CodingKey {
		case success, failure
	}
	
	enum Error: Swift.Error {
		case noKeyForSuccessOrFailure, foundKeysForSuccessAndFailure
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let successValue = try container.decodeIfPresent(T.self, forKey: .success)
		let error = try container.decodeIfPresent(E.self, forKey: .failure)
		switch (successValue, error) {
		case (.some(let successValue), .none):
			self = .success(successValue)
		case (.none, .some(let error)):
			self = .failure(error)
		case (.none, .none):
			throw Error.noKeyForSuccessOrFailure
		case (.some, .some):
			throw Error.foundKeysForSuccessAndFailure
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .success(let value):
			try container.encode(value, forKey: .success)
		case .failure(let error):
			try container.encode(error, forKey: .failure)
		}
	}
}
