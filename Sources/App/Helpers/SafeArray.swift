//
//  SafeArray.swift
//  Async
//
//  Created by Oliver Dew on 18/10/2018.
//

import Foundation

final class SafeArray<T>: ExpressibleByArrayLiteral {
	
	private var cache = [T]()
	private let queue = DispatchQueue(label: "com.SaltPig.DotVoter.SafeArray", attributes: .concurrent)
	
	init(arrayLiteral elements: T...) {
		for element in elements {
			append(element)
		}
	}
	
	var array: [T] {
		return queue.sync {
			cache
		}
	}
	
	func append(_ element: T) {
		queue.sync(flags: .barrier) {
			cache.append(element)
		}
	}
	
	func remove(at index: Int) -> T {
		return queue.sync(flags: .barrier) {
			cache.remove(at: index)
		}
	}
	
	func removeAll() {
		queue.sync(flags: .barrier) {
			cache.removeAll()
		}
	}
	
	func contains (where predicate: (T) throws -> Bool) rethrows -> Bool {
		return try queue.sync {
			try cache.contains(where: predicate)
		}
	}
	
	func first(where predicate: (T) throws -> Bool) rethrows -> T? {
		return try queue.sync {
			try cache.first(where: predicate)
		}
	}
	
	subscript(_ index: Int) -> T? {
		get {
			return queue.sync {
				cache[safe: index]
			}
		}
		set {
			queue.sync(flags: .barrier) {
				cache[safe: index] = newValue
			}
		}
	}
}
