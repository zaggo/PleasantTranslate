//
//  PurgeCCProcessorTests.swift
//  PleasantTranslateTests
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

import XCTest
@testable import PleasantTranslate

final class PurgeCCProcessorTests: XCTestCase {
    let subtitles: [Subtitle] = [
        .sample(withLines: ["[Frank] Text1"]),
        .sample(withLines: ["Frank: Text2"]),
        .sample(withLines: ["FRANK: Text3"]),
        .sample(withLines: ["(Frank) Text4"]),
        .sample(withLines: ["Ein Lied: ♪ 2, 3, 4 ♪"]),
        .sample(withLines: ["♪ 2, 3, 4 ♪"]),
        .sample(withLines: ["FRANK: Text5", "♪ 2, 3, 4 ♪"]),
    ]
    
    func testSubstitude() throws {
        let processor = PurgeCCProcessor.sample
        let substitutions = AvailableCCPatterns.presets
        let disabled = Set<SubtitleId>()
        
        let (processed, changes) = processor.purge(subtitles: subtitles,
                                                   substitutions: substitutions,
                                                   disabledSubtitleIds: disabled)
        
        XCTAssertEqual(processed.count, 6)
        XCTAssertEqual(processed[safe: 0]?.lines[safe: 0], "- Text1")
        XCTAssertEqual(processed[safe: 0]?.id, subtitles[safe: 0]?.id)
        XCTAssertEqual(processed[safe: 0]?.timecode, subtitles[safe: 0]?.timecode)
        
        XCTAssertEqual(processed[safe: 1], subtitles[safe: 1])

        XCTAssertEqual(processed[safe: 2]?.lines[safe: 0], "- Text3")
        XCTAssertEqual(processed[safe: 2]?.id, subtitles[safe: 2]?.id)
        XCTAssertEqual(processed[safe: 2]?.timecode, subtitles[safe: 2]?.timecode)

        XCTAssertEqual(processed[safe: 3]?.lines[safe: 0], "- Text4")
        XCTAssertEqual(processed[safe: 3]?.id, subtitles[safe: 3]?.id)
        XCTAssertEqual(processed[safe: 3]?.timecode, subtitles[safe: 3]?.timecode)

        XCTAssertEqual(processed[safe: 4]?.lines[safe: 0], "Ein Lied:")
        XCTAssertEqual(processed[safe: 4]?.id, subtitles[safe: 4]?.id)
        XCTAssertEqual(processed[safe: 4]?.timecode, subtitles[safe: 4]?.timecode)

        XCTAssertEqual(processed[safe: 5]?.lines[safe: 0], "- Text5")
        XCTAssertEqual(processed[safe: 5]?.lines.count, 1)
        XCTAssertEqual(processed[safe: 5]?.id, subtitles[safe: 6]?.id)
        XCTAssertEqual(processed[safe: 5]?.timecode, subtitles[safe: 6]?.timecode)

        XCTAssertEqual(changes.count, 6)
        
        XCTAssertEqual(changes[safe: 0]?.original, subtitles[safe: 0])
        XCTAssertEqual(changes[safe: 0]?.processed, processed[safe: 0])
        
        XCTAssertEqual(changes[safe: 1]?.original, subtitles[safe: 2])
        XCTAssertEqual(changes[safe: 1]?.processed, processed[safe: 2])
        
        XCTAssertEqual(changes[safe: 2]?.original, subtitles[safe: 3])
        XCTAssertEqual(changes[safe: 2]?.processed, processed[safe: 3])
        
        XCTAssertEqual(changes[safe: 3]?.original, subtitles[safe: 4])
        XCTAssertEqual(changes[safe: 3]?.processed, processed[safe: 4])
        
        XCTAssertEqual(changes[safe: 4]?.original, subtitles[safe: 5])

        XCTAssertEqual(changes[safe: 5]?.original, subtitles[safe: 6])
        XCTAssertEqual(changes[safe: 5]?.processed, processed[safe: 5])
    }

}
