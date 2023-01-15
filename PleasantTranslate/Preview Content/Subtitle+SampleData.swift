//
//  Subtitle+SampleData.swift
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

extension Subtitle {
    static var sample: Self {
        .sample(withLines: ["What are they thinking about?", "What are they looking for?"])
    }
    
    static var splitSample: Self {
        .sample(withLines: ["But from time to time he calls me", "or visits me unexpectedly."])
    }

    static func sample(withLines lines: [String]) -> Subtitle {
        .init(id: "\(Int.random(in: 1..<100))",
              timecode: .sample,
              lines: lines)
    }
}
