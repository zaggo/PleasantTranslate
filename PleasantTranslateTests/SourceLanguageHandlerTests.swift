//
//  SourceLanguageHandlerTests.swift
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

final class SourceLanguageHandlerTests: XCTestCase {
    let handler = EnglishSourceLanguageHandler()

    func testNop() throws {
        let subtitles: [Subtitle] = [
            .sample(withLines: ["Es ist gut, dass die Leben", "in mehreren Kreisen verlaufen."]),
            .sample(withLines: ["Aber mein Leben ist nur einmal herumgelaufen,", "und nicht einmal ganz."]),
        ]

        let (processed, changedIndexes) = handler.prewash(subtitles: subtitles, disabledSubtitleIds: [])
        
        XCTAssertEqual(changedIndexes.count, 0)
        XCTAssertEqual(processed.count, 2)
        XCTAssertEqual(processed.first, subtitles.first)
        XCTAssertEqual(processed.last, subtitles.last)
    }
    
    func testElipsis() throws {
        let subtitles: [Subtitle] = [
            .sample(withLines: ["Today in Guernica a German delegation", "officially expressed their feelings of..."]),
            .sample(withLines: ["...remorse to basque authorities."]),
            .sample(withLines: ["During the ceremony, the german ambassador", "in Spain held a speech."]),
        ]

        let (processed, changedIndexes) = handler.prewash(subtitles: subtitles, disabledSubtitleIds: [])
        
        XCTAssertEqual(changedIndexes.count, 2)
        XCTAssertEqual(processed.count, 3)
        XCTAssertEqual(processed[safe: 0]?.lines.last, "officially expressed their feelings of")
        XCTAssertEqual(processed[safe: 1]?.lines.first, "remorse to basque authorities.")
        XCTAssertEqual(processed[safe: 2], subtitles[safe: 2])
    }

    func testUnwanted() throws {
        let subtitles: [Subtitle] = [
            .sample(withLines: ["Today in ♪ Guernica a German delegation", "officially expressed their feelings of…"]),
            .sample(withLines: ["…remorse to basque authorities."]),
            .sample(withLines: ["During the ceremony, the german ambassador…", "  ♪  "]),
        ]

        let (processed, changedIndexes) = handler.prewash(subtitles: subtitles, disabledSubtitleIds: [])
        
        XCTAssertEqual(changedIndexes.count, 3)
        XCTAssertEqual(processed.count, 3)
        XCTAssertEqual(processed[safe: 0]?.lines.last, "officially expressed their feelings of")
        XCTAssertEqual(processed[safe: 1]?.lines.first, "remorse to basque authorities.")
        XCTAssertEqual(processed[safe: 2]?.lines.first, "During the ceremony, the german ambassador…")
        XCTAssertEqual(processed[safe: 2]?.lines.count, 1)
    }
    
    func testDisabled() throws {
        let subtitles: [Subtitle] = [
            .sample(withLines: ["Today in ♪ Guernica a German delegation", "officially expressed their feelings of…"]),
            .sample(withLines: ["…remorse to basque authorities."]),
            .sample(withLines: ["During the ceremony, the german ambassador…", "  ♪  "]),
        ]

        let disabledSubtitleIds = Set([try XCTUnwrap(subtitles[safe: 0]?.id), try XCTUnwrap(subtitles[safe: 2]?.id)])
        let (processed, changedIndexes) = handler.prewash(subtitles: subtitles, disabledSubtitleIds: disabledSubtitleIds)
        
        XCTAssertEqual(changedIndexes.count, 2)
        XCTAssertEqual(processed.count, 3)
        XCTAssertEqual(processed[safe: 0]?.lines.last, "officially expressed their feelings of…")
        XCTAssertEqual(processed[safe: 1]?.lines.first, "remorse to basque authorities.")
        XCTAssertEqual(processed[safe: 2]?.lines.first, "During the ceremony, the german ambassador…")
        XCTAssertEqual(processed[safe: 2]?.lines.last, "  ♪  ")
    }

}
