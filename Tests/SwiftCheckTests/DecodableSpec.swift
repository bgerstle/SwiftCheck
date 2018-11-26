//
//  DecodableSpec.swift
//  SwiftCheck
//
//  Created by Brian Gerstle on 11/26/18.
//  Copyright © 2018 Typelift. All rights reserved.
//

import SwiftCheck
import XCTest

private struct TestDecodable: Equatable, Codable, Arbitrary {
	let foo: String
	let bar: Int?
	let nested: NestedTestDecodable

	struct NestedTestDecodable: Equatable, Codable, Arbitrary {
		let bazzes: [String]
		let buzzes: [String: Int]
	}
}

class DecodableSpec: XCTestCase {
	func testExampleType() {
		property("Generates arbitrary instances of example nested type with empty & non-empty values")
		<- forAll { (test: TestDecodable) in
			return true
				.cover(test.bar == nil, percentage: 1, label: "bar nil")
				.cover(test.foo.count > 0, percentage: 1, label: "foo not empty")
				.cover(test.nested.bazzes.count > 0, percentage: 1, label: "nested bazzes not empty")
				.cover(test.nested.buzzes.count > 0, percentage: 1, label: "nested buzzes not empty")
		}
	}
}
