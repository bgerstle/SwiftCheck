//
//  Decodable.swift
//  SwiftCheck
//
//  Created by Brian Gerstle on 11/26/18.
//  Copyright © 2018 Typelift. All rights reserved.
//

import Foundation

extension Decodable {
	public static var arbitrary: Gen<Self> {
		return ArbitraryCoder.generator()
	}
}

class ArbitraryCoder: Decoder {
	let composer: GenComposer
	let codingPath: [CodingKey]
	let userInfo: [CodingUserInfoKey : Any]

	init(composer: GenComposer, codingPath: [CodingKey]) {
		self.composer = composer
		self.codingPath = codingPath
		self.userInfo = [:]
	}

	static func generator<T: Decodable>() -> Gen<T> {
		return Gen.compose { composer in
			return try! T.init(from: ArbitraryCoder(composer: composer, codingPath: []))
		}
	}

	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
	where Key : CodingKey {
		return KeyedDecodingContainer(ArbitraryKeyedDecodingContainer<Key>(composer: composer, codingPath: codingPath))
	}

	func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		return ArbitraryUnkeyedDecodingContainer(composer: composer, codingPath: codingPath)
	}

	func singleValueContainer() throws -> SingleValueDecodingContainer {
		return ArbitrarySingleValueDecodingContainer(composer: composer, codingPath: codingPath)
	}
}

enum ArbitraryUnkeyedDecodingContainerError: Error {
	case outOfBounds
}

struct ArbitraryUnkeyedDecodingContainer: UnkeyedDecodingContainer {
	let composer: GenComposer
	let codingPath: [CodingKey]

	var count: Int?

	var isAtEnd: Bool {
		guard let count = count else {
			return true
		}
		return currentIndex >= count - 1
	}

	var currentIndex: Int = 0

	init(composer: GenComposer, codingPath: [CodingKey]) {
		self.composer = composer
		self.codingPath = codingPath
		self.count = composer.generate(using: Gen<Int>.fromElements(in: 0...100))
	}

	mutating func pop<T: Arbitrary>(_ type: T.Type) throws -> T {
		return try pop(T.arbitrary)
	}

	mutating func pop<T>(_ gen: Gen<T>) throws -> T {
		guard !isAtEnd else {
			throw ArbitraryUnkeyedDecodingContainerError.outOfBounds
		}
		currentIndex += 1
		return composer.generate(using: gen)
	}

	mutating func decodeNil() throws -> Bool {
		return try pop(Bool.self)
	}

	mutating func decode(_ type: Bool.Type) throws -> Bool {
		return try pop(type)
	}

	mutating func decode(_ type: String.Type) throws -> String {
		return try pop(type)
	}

	mutating func decode(_ type: Double.Type) throws -> Double {
		return try pop(type)
	}

	mutating func decode(_ type: Float.Type) throws -> Float {
		return try pop(type)
	}

	mutating func decode(_ type: Int.Type) throws -> Int {
		return try pop(type)
	}

	mutating func decode(_ type: Int8.Type) throws -> Int8 {
		return try pop(type)
	}

	mutating func decode(_ type: Int16.Type) throws -> Int16 {
		return try pop(type)
	}

	mutating func decode(_ type: Int32.Type) throws -> Int32 {
		return try pop(type)
	}

	mutating func decode(_ type: Int64.Type) throws -> Int64 {
		return try pop(type)
	}

	mutating func decode(_ type: UInt.Type) throws -> UInt {
		return try pop(type)
	}

	mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
		return try pop(type)
	}

	mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
		return try pop(type)
	}

	mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
		return try pop(type)
	}

	mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
		return try pop(type)
	}

	mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
		return try pop(T.arbitrary)
	}

	mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
	where NestedKey : CodingKey {
		return KeyedDecodingContainer(
			ArbitraryKeyedDecodingContainer<NestedKey>(
				composer: composer,
				codingPath: codingPath))
	}

	mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
		return ArbitraryUnkeyedDecodingContainer(composer: composer, codingPath: codingPath)
	}

	mutating func superDecoder() throws -> Decoder {
		return ArbitraryCoder(composer: composer, codingPath: codingPath)
	}
}

enum ArbitraryKeyedDecodingContainerError: Error {
	case noSuchElement
}

class ArbitraryKeyedDecodingContainer<KeyType>: KeyedDecodingContainerProtocol
where KeyType: CodingKey {
	typealias Key = KeyType
	let composer: GenComposer
	let codingPath: [CodingKey]
	var arbitraryKeys: [Key]?
	lazy var allKeys: [Key] = {
		// NOTE: only used for dictionaries which iterate through the keys in this property
		// Other Decodable types using keyed containers know the keys up front and access them directly
		let arbitraryKeys =
			String
				.arbitrary
				.map { KeyType.init(stringValue: $0) }
				.suchThat { $0 != nil }
				.map { $0! }
		return composer.generate(using: arbitraryKeys.proliferate)
	}()

	init (composer: GenComposer, codingPath: [CodingKey]) {
		self.composer = composer
		self.codingPath = codingPath
	}

	func contains(_ key: ArbitraryKeyedDecodingContainer<KeyType>.Key) -> Bool {
		guard let keys = arbitraryKeys else {
			return true
		}
		let stringValue = key.stringValue
		return keys.contains { $0.stringValue == stringValue }
	}

	func decode<T>(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) -> T?
		where T: Arbitrary {
			return decode(forKey: key, T.arbitrary)
	}

	private func decode<T>(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key, _ gen: Gen<T>) -> T? {
		return contains(key) ? (composer.generate(using: gen) as T) : nil
	}

	func decodeOptional<T>(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) -> T?
	where T: Arbitrary {
		return decodeOptional(forKey: key, T.arbitrary)
	}

	private func decodeOptional<T>(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key, _ gen: Gen<T>) -> T? {
        let value = composer.generate(using: Gen.one(of: [
			Gen<T?>.pure(nil),
			gen.map { Optional($0) }
		]))
		return value
	}

	private func strictDecode<T: Arbitrary>(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> T {
		return try strictDecode(forKey: key, T.arbitrary)
	}

	private func strictDecode<T>(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key, _ gen: Gen<T>) throws -> T {
		guard let value = decode(forKey: key, gen) else {
			throw DecodingError.keyNotFound(
				key,
				DecodingError.Context(
					codingPath: codingPath,
					debugDescription: String(reflecting: self)))
		}
		return value
	}

	func decodeNil(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Bool {
		return contains(key) && composer.generate()
	}

	func decode(_ type: Int.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Bool.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Bool {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Int8.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int8 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: UInt.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Float.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Float {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Int16.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int16 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Int32.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int32 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Int64.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int64 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: UInt8.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt8 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: Double.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Double {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: String.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> String {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: UInt16.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt16 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: UInt32.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt32 {
		return try strictDecode(forKey: key)
	}

	func decode(_ type: UInt64.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt64 {
		return try strictDecode(forKey: key)
	}

	func decode<T>(_ type: T.Type, forKey key: KeyType) throws -> T where T : Decodable {
		return try strictDecode(forKey: key, T.arbitrary)
	}

	// NOTE: Must override the default implementation of decodeIfPresent since this is what's called for keys that might be missing,
	// such as optional fields of structs.

	func decodeIfPresent(_ type: Int.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: Int8.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int8? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: UInt.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: Float.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Float? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: Int16.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int16? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: Int32.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int32? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: Int64.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Int64? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: UInt8.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt8? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: Double.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> Double? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: String.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> String? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: UInt16.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt16? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: UInt32.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt32? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent(_ type: UInt64.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UInt64? {
		return decodeOptional(forKey: key)
	}

	func decodeIfPresent<T>(_ type: T.Type, forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> T?
	where T : Decodable {
		return decodeOptional(forKey: key, T.arbitrary)
	}

	func nestedUnkeyedContainer(forKey key: ArbitraryKeyedDecodingContainer<KeyType>.Key) throws -> UnkeyedDecodingContainer {
		let _: Bool = try strictDecode(forKey: key)
		return ArbitraryUnkeyedDecodingContainer(
			composer: composer,
			codingPath: codingPath + [key])
	}

	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: KeyType) throws -> KeyedDecodingContainer<NestedKey>
	where NestedKey : CodingKey {
		let _: Bool = try strictDecode(forKey: key)
		return KeyedDecodingContainer(
			ArbitraryKeyedDecodingContainer<NestedKey>(
				composer: composer,
				codingPath: codingPath + [key]))
	}

	func superDecoder() throws -> Decoder {
		return ArbitraryCoder(composer: composer, codingPath: codingPath)
	}

	func superDecoder(forKey key: KeyType) throws -> Decoder {
		let _: Bool = try strictDecode(forKey: key)
		return ArbitraryCoder(composer: composer, codingPath: codingPath + [key])
	}
}

class ArbitrarySingleValueDecodingContainer: SingleValueDecodingContainer {
	let composer: GenComposer
	let codingPath: [CodingKey]

	init(composer: GenComposer, codingPath: [CodingKey]) {
		self.codingPath = codingPath
		self.composer = composer
	}

	func decodeNil() -> Bool {
		return composer.generate()
	}

	func decode(_ type: Bool.Type) throws -> Bool {
		return composer.generate()
	}

	func decode(_ type: String.Type) throws -> String {
		return composer.generate()
	}

	func decode(_ type: Double.Type) throws -> Double {
		return composer.generate()
	}

	func decode(_ type: Float.Type) throws -> Float {
		return composer.generate()
	}

	func decode(_ type: Int.Type) throws -> Int {
		return composer.generate()
	}

	func decode(_ type: Int8.Type) throws -> Int8 {
		return composer.generate()
	}

	func decode(_ type: Int16.Type) throws -> Int16 {
		return composer.generate()
	}

	func decode(_ type: Int32.Type) throws -> Int32 {
		return composer.generate()
	}

	func decode(_ type: Int64.Type) throws -> Int64 {
		return composer.generate()
	}

	func decode(_ type: UInt.Type) throws -> UInt {
		return composer.generate()
	}

	func decode(_ type: UInt8.Type) throws -> UInt8 {
		return composer.generate()
	}

	func decode(_ type: UInt16.Type) throws -> UInt16 {
		return composer.generate()
	}

	func decode(_ type: UInt32.Type) throws -> UInt32 {
		return composer.generate()
	}

	func decode(_ type: UInt64.Type) throws -> UInt64 {
		return composer.generate()
	}

	func decode<T>(_ type: T.Type) throws -> T
	where T : Decodable {
		return composer.generate(using: T.arbitrary)
	}
}
