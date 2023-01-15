//
//  Sentence+SampleData.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 06.01.23.
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
extension Sentence {
    static var sample: Sentence {
        let text = "What are they thinking about?"
        return .init(text: text,
                     extras: .hyphened,
                     sources: [
                        SentenceSource(subtitleIndex: 0, lineIndex: 0, range: text.range(of: text)!)
                     ])
    }
    
    static var splitSample: Sentence {
        let text1 = "But from time to time he calls me"
        let text2 = "or visits me unexpectedly."
        let text = text1 + " " + text2
        
        return .init(text: text,
                     extras: [],
                     sources: [
                        SentenceSource(subtitleIndex: 0,
                                       lineIndex: 0,
                                       range: text1.range(of: text1)!),
                        SentenceSource(subtitleIndex: 0,
                                       lineIndex: 1,
                                       range: text2.range(of: text2)!)
                     ])
    }

}
