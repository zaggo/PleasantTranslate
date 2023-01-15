//
//  SubtitleTimecode.swift
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

struct SubtitleTimecode: Codable, Equatable {
    // MARK: - Initialization
    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
    
    init(startSeconds: TimeInterval, endSeconds: TimeInterval) {
        self.start = Self.zeroTime.addingTimeInterval(startSeconds)
        self.end = Self.zeroTime.addingTimeInterval(endSeconds)
    }

    // MARK: - API
    var startSeconds: TimeInterval {
        start.timeIntervalSinceReferenceDate - Self.zeroTime.timeIntervalSinceReferenceDate
    }

    var endSeconds: TimeInterval {
        end.timeIntervalSinceReferenceDate - Self.zeroTime.timeIntervalSinceReferenceDate
    }

    // MARK: - iVars
    let start: Date
    let end: Date
    
    // MARK: - Constants
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm:ss,SSS"
        return formatter
    }()
    
    static let zeroTime: Date = {
        formatter.date(from: "00:00:00,000")!
    }()
}

extension SubtitleTimecode: CustomStringConvertible {
    var description: String {
        let formatter = Self.formatter
        let start = formatter.string(from: start)
        let end = formatter.string(from: end)
        return "\(start) --> \(end)"
    }
}
