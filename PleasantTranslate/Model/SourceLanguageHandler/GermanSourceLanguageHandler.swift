//
//  GermanSourceLanguageHandler.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 22.05.21.
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

struct GermanSourceLanguageHandler: SourceLanguageHandler {

    // MARK: - API
    static var displayName: String { NSLocalizedString("German", comment: "") }
    static var twoLetterCode: LanguageTwoLetterCode { "de" }
    var naturalLanguage: NLLanguage { .german }

    // MARK: - Constants
    let continuationPatternPresets: [PrewashLineContinuationPattern] = [
        .init(lineEndPattern: "…", lineStartPattern: "…"),
        .init(lineEndPattern: "...", lineStartPattern: "..."),
    ]
    
    let unwantedCharactersPresets: [String] = ["♪"]
}
