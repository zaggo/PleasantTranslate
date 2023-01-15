//
//  URLRequest+Utilities.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 03.01.23.
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

// Based on https://gist.github.com/nolanw/14b277903a2ba446f75202a6bfd55977
extension URLRequest {
    
    /// Configures the URL request for `application/x-www-form-urlencoded` data.
    ///
    /// The request's `httpBody` is set, and values are set for HTTP header fields `Content-Type` and `Content-Length`.
    /// - Parameter queryItems: The (name, value) pairs to encode and set as the request's body.
    /// - Note: The default `httpMethod` is `GET`, and `GET` requests do not typically have a body.
    ///         Remember to set the `httpMethod` to e.g. `POST` before sending the request.
    /// - Warning: It is a programmer error if any name or value in `queryItems` contains an unpaired UTF-16 surrogate.
    mutating func setFormURLEncoded(_ queryItems: [URLQueryItem]) {
        setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        func serialize(_ s: String) -> String {
            return s
                // Force-unwrapping because only known failure case is unpaired surrogate,
                // which we've documented above as an error.
                .addingPercentEncoding(withAllowedCharacters: Self.formURLEncodedAllowedCharacters)!
                .replacingOccurrences(of: " ", with: "+")
        }
        
        // https://url.spec.whatwg.org/#concept-urlencoded-serializer
        let output = queryItems.lazy
            .map { ($0.name, $0.value ?? "") }
            .map { (serialize($0), serialize($1)) }
            .map { "\($0)=\($1)" }
            .joined(separator: "&")
        
        let data = output.data(using: .utf8)
        httpBody = data
        
        if let contentLength = data?.count {
            setValue(String(contentLength), forHTTPHeaderField: "Content-Length")
        }
    }
    
    private static let formURLEncodedAllowedCharacters: CharacterSet = {
        // https://url.spec.whatwg.org/#urlencoded-serializing
        var allowed = CharacterSet()
        allowed.insert(UnicodeScalar(0x2A))
        allowed.insert(charactersIn: UnicodeScalar(0x2D)...UnicodeScalar(0x2E))
        allowed.insert(charactersIn: UnicodeScalar(0x30)...UnicodeScalar(0x39))
        allowed.insert(charactersIn: UnicodeScalar(0x41)...UnicodeScalar(0x5A))
        allowed.insert(UnicodeScalar(0x5F))
        allowed.insert(charactersIn: UnicodeScalar(0x61)...UnicodeScalar(0x7A))
        
        // and we'll deal with ` ` later…
        allowed.insert(" ")
        
        return allowed
    }()
}

extension URLRequest {

    func curlString() -> String {
        var curl = "curl --insecure"

        // Method
        if let method = httpMethod {
            curl += " -X \(method)"
        }

        // Headers
        for (name, val) in allHTTPHeaderFields ?? [:] {
            curl += " -H '\(name): \(val)'"
        }

        // Body
        if let body = httpBody {
            // Should work in most cases
            if let string = String(data: body, encoding: .utf8)?.replacingOccurrences(of: "'", with: "\\'") {
                curl += " --data-binary '\(string)'"

            } else {
                curl += " --data-binary 'ERR_NOT_A_STRING'"
            }
        }

        // URL
        if let url = url?.absoluteString {
            curl += " \(url)"
        } else {
            curl += " ERR_NO_URL"
        }

        return curl
    }
}
