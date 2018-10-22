//
//  SafeDictionary.swift
//  DotVoteServer
//
//  Created by Oliver Dew on 19/10/2018.
//

import Foundation

final class SafeDictionary<Key: Hashable, Value>: ExpressibleByDictionaryLiteral {
	
	private var cache = [Key : Value]()
	private let queue = DispatchQueue(label: "com.SaltPig.DotVoter.SafeDictionary", attributes: .concurrent)
	
	init(dictionaryLiteral elements: (Key, Value)...) {
		for (key, value) in elements {
			self[key] = value
		}
	}
	
	func remove(at key: Key) -> Value? {
		return queue.sync(flags: .barrier) {
			cache.removeValue(forKey: key)
		}
	}
	
	func forEach(body: ((key: Key, value: Value)) throws -> Void) rethrows {
		try cache.forEach(body)
	}
	
	subscript(_ key: Key) -> Value? {
		get {
			return queue.sync {
				cache[key]
			}
		}
		set {
			queue.sync(flags: .barrier) {
				cache[key] = newValue
			}
		}
	}
}
