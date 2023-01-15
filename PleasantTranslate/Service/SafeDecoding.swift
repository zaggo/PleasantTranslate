//
//  SafeDecoding.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 04.01.23.
//
//  Copyright © 2023 Pleasant Software, Freiburg
//
//  This file is part of PleasantTranslate.
//
//  PleasantTranslate is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  PleasantTranslate is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with PleasantTranslate. If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

// Based on http://kean.github.io/post/codable-tips-and-tricks#1-safely-decoding-arrays

extension KeyedDecodingContainer {
    public func decode<T: Decodable>(_ key: Key, as type: T.Type = T.self) throws -> T {
        return try self.decode(T.self, forKey: key)
    }

    public func decodeIfPresent<T: Decodable>(_ key: KeyedDecodingContainer.Key, as type: T.Type = T.self) throws -> T? {
        return try decodeIfPresent(T.self, forKey: key)
    }
}

/// A wrapper for decoded objects which tolerates failing. In case of failing, the optional `value` is set to nil
/// - Note: In `DEBUG` builds a `assertionFailure` will stop the process in case of a fail.
public struct Safe<Base: Decodable>: Decodable {
    public let value: Base?

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self.value = try container.decode(Base.self)
        } catch {
            // log.severe("Decoding Failed: \(error)")
            // TO DO: automatically send a report about a corrupted data
            self.value = nil
        }
    }
}

extension KeyedDecodingContainer {
    public func decodeSafely<T: Decodable>(_ key: KeyedDecodingContainer.Key) -> T? {
        return self.decodeSafely(T.self, forKey: key)
    }

    public func decodeSafely<T: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer.Key) -> T? {
        let decoded = try? decode(Safe<T>.self, forKey: key)
        return decoded?.value
    }

    public func decodeSafelyIfPresent<T: Decodable>(_ key: KeyedDecodingContainer.Key) -> T? {
        return self.decodeSafelyIfPresent(T.self, forKey: key)
    }

    public func decodeSafelyIfPresent<T: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer.Key) -> T? {
        let decoded = try? decodeIfPresent(Safe<T>.self, forKey: key)
        return decoded?.value
    }
}

extension KeyedDecodingContainer {
    public func decodeSafelyArray<T: Decodable>(of type: T.Type, forKey key: KeyedDecodingContainer.Key) -> [T] {
        let array = decodeSafely([Safe<T>].self, forKey: key)
        return array?.compactMap { $0.value } ?? []
    }
}

extension JSONDecoder {
    public func decodeSafelyArray<T: Decodable>(of type: T.Type, from data: Data) -> [T] {
        guard let array = try? decode([Safe<T>].self, from: data) else { return [] }
        return array.compactMap { $0.value }
    }
}
