//
//  PrewashLineContinuationPattern.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 05.01.23.
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

struct PrewashLineContinuationPattern {
    let lineEndPattern: String
    let lineStartPattern: String
}

extension Sequence where Element == PrewashLineContinuationPattern {
    func process(preceedingLines: inout [String], followingLines: inout [String]) -> Bool {
        for pattern in self {

            guard preceedingLines.hasSuffix(pattern.lineEndPattern) && followingLines.hasPrefix(pattern.lineStartPattern) else {
                continue
            }

            preceedingLines.removeSuffix(pattern.lineEndPattern)
            followingLines.removePrefix(pattern.lineStartPattern)

            return true
        }
        return false
    }
}

private extension Array where Element == String {
    func hasSuffix(_ suffix: String) -> Bool {
        last?.hasSuffix(suffix) ?? false
    }
    
    func hasPrefix(_ prefix: String) -> Bool {
        first?.hasPrefix(prefix) ?? false
    }
    
    mutating func removeSuffix(_ suffix: String) {
        guard !isEmpty else { return }
        append(String(removeLast().dropLast(suffix.count)))
    }
    
    mutating func removePrefix(_ prefix: String) {
        guard !isEmpty else { return }
        insert(String(removeFirst().dropFirst(prefix.count)), at: 0)
    }
}
