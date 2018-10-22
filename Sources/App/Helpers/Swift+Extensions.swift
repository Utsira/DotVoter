//
//  Swift+Extensions.swift
//  Async
//
//  Created by Oliver Dew on 18/10/2018.
//

import Foundation

extension Array {
	subscript(safe index: Int) -> Element? {
		get {
			return indices.contains(index) ? self[index] : nil
		}
		set {
			guard indices.contains(index),
				let newValue = newValue
				else { return }
			self[index] = newValue
		}
	}
}
