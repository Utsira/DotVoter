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
	
	init<S>(keysAndValues: S, uniquingKeysWith combine: (Dictionary<Key, Value>.Value, Dictionary<Key, Value>.Value) throws -> Dictionary<Key, Value>.Value) rethrows where S : Sequence, S.Element == (Key, Value) {
		try queue.sync(flags: .barrier) {
			cache = try Dictionary(keysAndValues, uniquingKeysWith: combine)
		}
	}
	
	func remove(at key: Key) -> Value? {
		return queue.sync(flags: .barrier) {
			cache.removeValue(forKey: key)
		}
	}
	
	func contains(where test: ((key: Key, value: Value)) throws -> Bool) rethrows -> Bool {
		return try queue.sync {
			return try cache.contains(where: test)
		}
	}
	
	func merge(other: [Key : Value], uniquingKeysWith disambiguator: (Value, Value) throws -> Value = { a, b in b }) rethrows {
		try queue.sync(flags: .barrier) {
			try cache.merge(other, uniquingKeysWith: disambiguator)
		}
	}
	
	func merge(other: [(Key, Value)], uniquingKeysWith disambiguator: (Value, Value) throws -> Value = { a, b in b }) rethrows {
		
		try queue.sync(flags: .barrier) {
			try cache.merge(other, uniquingKeysWith: disambiguator)
		}
	}
	
	func map<T>(transform: ((key: Key, value: Value)) throws -> T ) rethrows -> [T] {
		return try queue.sync {
			return try cache.map(transform)
		}
	}
	
	func mapValues<T>(transform: (Value) throws -> T) rethrows -> [Key: T] {
		return try queue.sync {
			return try cache.mapValues(transform)
		}
	}
	
	func forEach(body: ((key: Key, value: Value)) throws -> Void) rethrows {
		try queue.sync(flags: .barrier) {
			try cache.forEach(body)
		}
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
