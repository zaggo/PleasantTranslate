//
//  EnglishTargetLanguageHandler.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 07.01.23.
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
import NaturalLanguage

struct EnglishTargetLanguageHandler: TargetLanguageHandler {
    static var displayName: String { NSLocalizedString("English", comment: "") }
    static var twoLetterCode: LanguageTwoLetterCode { "en" }
    static var naturalLanguage: NLLanguage { .english }

    // MARK: - Initialization
    init() {
        tokenizer.setLanguage(Self.naturalLanguage)
    }
    
    // MARK: - API
    let maxLineLength = 50
        
    // MARK: - iVars
    let tokenizer = NLTokenizer(unit: .word)
    
    // MARK: - Constants
    let splitAfterTriggers = [",", ".", "…", ")", "}", "]", ":"]
    let splitBeforeTriggers = ["(", "[", "{"]
    let splitBeforeWordTriggers = ["and", "or", "but"]
    let splitAfterWordTriggers: [String] = []
}
