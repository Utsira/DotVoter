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
