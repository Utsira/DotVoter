//
//  XCTest+LinuxFiller.swift
//  AppTests
//
//  Created by Oliver Dew on 05/11/2018.
//

import XCTest

final class TestExpectation {
	private let description: String
	private let semaphore = DispatchSemaphore(value: 0)
	
	init(description: String) {
		self.description = description
	}
	
	func wait(timeout: TimeInterval, file: StaticString = #file, line: UInt = #line) {
		switch semaphore.wait(timeout: .now() + timeout) {
		case .success:
			return
		case .timedOut:
			XCTFail("timed out waiting for: \"\(description)\"", file: file, line: line)
		}
	}
	
	func fulfill() {
		semaphore.signal()
	}
 }
