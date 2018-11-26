//
//  DecodableSpec.swift
//  SwiftCheck
//
//  Created by Brian Gerstle on 11/26/18.
//  Copyright © 2018 Typelift. All rights reserved.
//

import SwiftCheck
import XCTest

struct TestDecodable: Equatable, Codable, Arbitrary {
	let foo: String
	let bar: Int?
	let nested: NestedTestDecodable

	struct NestedTestDecodable: Equatable, Codable, Arbitrary {
		let bazzes: [String]
		let buzzes: [String: Int]
	}
}

struct TestDecodableWithoutBar: Arbitrary {
	let test: TestDecodable

	static let arbitrary: Gen<TestDecodableWithoutBar> =
		TestDecodable
			.arbitrary
			.suchThat { $0.bar == nil }
			.map { TestDecodableWithoutBar(test: $0) }
}

struct NonEmptyCollectionSize: Arbitrary {
	let size: Int
	static var arbitrary: Gen<NonEmptyCollectionSize> {
		return Gen<Int>.fromElements(in: 1...50).map { NonEmptyCollectionSize(size: $0) }
	}
}

class DecodableSpec: XCTestCase {
	func testExampleType() {
		property("Generates arbitrary instances of example nested type") <- forAll { (test: TestDecodable) in
			let description = String(reflecting: test)
			return description.count > 0
		}
	}

	func testGeneratesNonemptyCollectionFields() {
		property("Generates non-empty array fields") <- forAll { (aSize: NonEmptyCollectionSize) in
			let test =
				TestDecodable.NestedTestDecodable
					.arbitrary
					.resize(aSize.size)
					.suchThat {
						return $0.bazzes.count > 0 && $0.buzzes.count > 0
					}
					.generate
			return test.bazzes.count > 0 && test.buzzes.count > 0
		}
	}

	func testGeneratesNilFields() {
		property("Generates nil fields") <- forAll { (aTest: TestDecodableWithoutBar) in
			return aTest.test.bar == nil
		}
	}
}
