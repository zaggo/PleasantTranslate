//
//  AvailableCCPatterns.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 13.05.21.
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

struct AvailableCCPatterns {
    static let shared = AvailableCCPatterns()
    private init() {}
    
    @LocalUserDefault(key: "AvailableCCPatterns", defaultValue: presets)
    var substitutions: [CCPattern]
    
    static let presets = [
        CCPattern(pattern: #"\[[^\]]+\]"#, description: #"Remove "[Music]""#),
        CCPattern(pattern: #"\([^\)]+\)"#, description: #"Remove "(Frank)""#),
        CCPattern(pattern: #"[A-Z ]+:"#, description: #"Remove "FRANK:""#),
        CCPattern(pattern: #"♪[^♪]+♪"#, description: #"Remove "♪ Something ♪""#)
    ]
}

typealias CCPatternId = String
struct CCPattern: Codable, Identifiable {
    init(id: CCPatternId = UUID().uuidString, pattern: String, description: String) {
        self.id = id
        self.pattern = pattern
        self.description = description
    }
    
    let id: CCPatternId
    let pattern: String
    let description: String
}

extension Sequence where Element == CCPattern {
    func processLine(_ line: String) -> String {
        var processedLine = line
        var substitutionHappened: Bool
        repeat {
            substitutionHappened = false
            for substitution in self {
                let processed = processedLine.replacingOccurrences(of: substitution.pattern,
                                                                 with: "",
                                                                 options: .regularExpression,
                                                                 range: nil)
                if processed != processedLine {
                    substitutionHappened = true
                    processedLine = processed
                }
            }
        } while(substitutionHappened)

        processedLine = processedLine.trimmingCharacters(in: CharacterSet.whitespaces)
        if line != processedLine
            && !processedLine.isEmpty
            && !processedLine.hasPrefix("-")
            && line.hasSuffix(processedLine){
            processedLine = "- \(processedLine)"
        }
        return processedLine
    }
}
