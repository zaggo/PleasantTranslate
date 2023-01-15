//
//  String+Utilities.swift
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

extension String {
    func convertedToUtf8() throws -> String {
        guard let cString = self.cString(using: .utf8),
              let utf8String = String(utf8String: cString) else {
            throw Errors.invalidEncoding
        }
        return utf8String
    }
    
    enum Errors: Error {
        case invalidEncoding
    }
    
    func isMatch<R>(of r: R) -> Bool where R : RegexComponent {
        self.wholeMatch(of: r) != nil
    }
        
    var fullRange: Range<Index> { range(withStartOffset: 0, endOffset: count) }
    func range(withStartOffset start: Int, endOffset end: Int) -> Range<Index> {
        let startIndex = Index(utf16Offset: start, in: self)
        let endIndex = Index(utf16Offset: end, in: self)
        return startIndex ..< endIndex
    }
}

extension StringProtocol {
    var removeWhitespaces: String {
        unicodeScalars.filter({ !CharacterSet.whitespaces.contains($0) }).string
    }
}

extension Sequence where Element == UnicodeScalar {
    var string: String { .init(String.UnicodeScalarView(self)) }
}
