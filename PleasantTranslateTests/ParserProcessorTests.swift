//
//  ParserProcessorTests.swift
//  PleasantTranslateTests
//
//  Created by Eberhard Rensch on 04.01.23.
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
final class ParserProcessorTests: XCTestCase {

    func testSucess() async throws {
        let processor = ParserProcessor.sample
        
        let rawSubtitles =
        """
        1
        00:03:02,920 --> 00:03:05,920
        Es ist gut, dass die Leben
        in mehreren Kreisen verlaufen.

        2
        00:03:06,080 --> 00:03:11,560
        Aber mein Leben ist nur einmal herumgelaufen,
        und nicht einmal ganz.

        3
        00:03:11,760 --> 00:03:13,800
        Das Wichtigste fehlt.

        4
        00:03:13,960 --> 00:03:17,400
        Ich habe ihren Namen
        schon so oft
        hineingeschrieben.
        """
        
        let results = await processor.process(input: rawSubtitles)
        let subtitles: [Subtitle] = try extractProcessorResult(from: results)
        
        XCTAssertEqual(subtitles.count, 4)
        guard subtitles.count == 4 else { return }

        XCTAssertEqual(subtitles[safe: 0]?.id, "1")
        XCTAssertEqual(subtitles[safe: 1]?.id, "2")
        XCTAssertEqual(subtitles[safe: 2]?.id, "3")
        XCTAssertEqual(subtitles[safe: 3]?.id, "4")
   
        XCTAssertEqual(subtitles[safe: 0]?.timecode.description, "00:03:02,920 --> 00:03:05,920")
        XCTAssertEqual(subtitles[safe: 1]?.timecode.description, "00:03:06,080 --> 00:03:11,560")
        XCTAssertEqual(subtitles[safe: 2]?.timecode.description, "00:03:11,760 --> 00:03:13,800")
        XCTAssertEqual(subtitles[safe: 3]?.timecode.description, "00:03:13,960 --> 00:03:17,400")
        
        XCTAssertEqual(subtitles[safe: 0]?.lines.count, 2)
        XCTAssertEqual(subtitles[safe: 1]?.lines.count, 2)
        XCTAssertEqual(subtitles[safe: 2]?.lines.count, 1)
        XCTAssertEqual(subtitles[safe: 3]?.lines.count, 3)

        XCTAssertEqual(subtitles[safe: 0]?.lines[safe: 0], "Es ist gut, dass die Leben")
        XCTAssertEqual(subtitles[safe: 0]?.lines[safe: 1], "in mehreren Kreisen verlaufen.")

        XCTAssertEqual(subtitles[safe: 1]?.lines[safe: 0], "Aber mein Leben ist nur einmal herumgelaufen,")
        XCTAssertEqual(subtitles[safe: 1]?.lines[safe: 1], "und nicht einmal ganz.")

        XCTAssertEqual(subtitles[safe: 2]?.lines[safe: 0], "Das Wichtigste fehlt.")

        XCTAssertEqual(subtitles[safe: 3]?.lines[safe: 0], "Ich habe ihren Namen")
        XCTAssertEqual(subtitles[safe: 3]?.lines[safe: 1], "schon so oft")
        XCTAssertEqual(subtitles[safe: 3]?.lines[safe: 2], "hineingeschrieben.")
    }
    
    func testIssues() async throws {
        let rawSubtitles =
        """
        1
        00:03:02,920 --> 00:03:05,920
        Es ist gut, dass die Leben
        in mehreren Kreisen verlaufen.

        Unexpected
        2
        00:03:06,080 --> 00:03:11,560
        Aber mein Leben ist nur einmal herumgelaufen,
        und nicht einmal ganz.

        3
        Das Wichtigste fehlt.

        4
        00:03:13,960 --> 00:03:17,400
        Ich habe ihren Namen
        schon so oft
        hineingeschrieben.
        
        5
        6
        00:03:21,120 --> 00:03:22,960
        Ich bin allein.
        
        7
        00:03:43,600 --> 00:03:48,240
        Als Kind umgab mich die Welt,
        und ich fühlte mich geborgen.
        """
    
        let parser = ParserProcessor.SubtitleParser(lines: rawSubtitles.components(separatedBy: CharacterSet.newlines))
        let (subtitles, issues) = parser.parse()
        
        XCTAssertEqual(subtitles.count, 5)
        guard subtitles.count == 5 else { return }
        
        XCTAssertEqual(subtitles[safe: 0]?.id, "1")
        XCTAssertEqual(subtitles[safe: 1]?.id, "2")
        XCTAssertEqual(subtitles[safe: 2]?.id, "4")
        XCTAssertEqual(subtitles[safe: 3]?.id, "6")
        XCTAssertEqual(subtitles[safe: 4]?.id, "7")

        XCTAssertEqual(subtitles[safe: 0]?.timecode.description, "00:03:02,920 --> 00:03:05,920")
        XCTAssertEqual(subtitles[safe: 1]?.timecode.description, "00:03:06,080 --> 00:03:11,560")
        XCTAssertEqual(subtitles[safe: 2]?.timecode.description, "00:03:13,960 --> 00:03:17,400")
        XCTAssertEqual(subtitles[safe: 3]?.timecode.description, "00:03:21,120 --> 00:03:22,960")
        XCTAssertEqual(subtitles[safe: 4]?.timecode.description, "00:03:43,600 --> 00:03:48,240")

        XCTAssertEqual(subtitles[safe: 0]?.lines.count, 2)
        XCTAssertEqual(subtitles[safe: 1]?.lines.count, 2)
        XCTAssertEqual(subtitles[safe: 2]?.lines.count, 3)
        XCTAssertEqual(subtitles[safe: 3]?.lines.count, 1)
        XCTAssertEqual(subtitles[safe: 4]?.lines.count, 2)

        XCTAssertEqual(subtitles[safe: 0]?.lines[safe: 0], "Es ist gut, dass die Leben")
        XCTAssertEqual(subtitles[safe: 0]?.lines[safe: 1], "in mehreren Kreisen verlaufen.")

        XCTAssertEqual(subtitles[safe: 1]?.lines[safe: 0], "Aber mein Leben ist nur einmal herumgelaufen,")
        XCTAssertEqual(subtitles[safe: 1]?.lines[safe: 1], "und nicht einmal ganz.")

        XCTAssertEqual(subtitles[safe: 2]?.lines[safe: 0], "Ich habe ihren Namen")
        XCTAssertEqual(subtitles[safe: 2]?.lines[safe: 1], "schon so oft")
        XCTAssertEqual(subtitles[safe: 2]?.lines[safe: 2], "hineingeschrieben.")

        XCTAssertEqual(subtitles[safe: 3]?.lines[safe: 0], "Ich bin allein.")
        
        XCTAssertEqual(subtitles[safe: 4]?.lines[safe: 0], "Als Kind umgab mich die Welt,")
        XCTAssertEqual(subtitles[safe: 4]?.lines[safe: 1], "und ich fühlte mich geborgen.")

        XCTAssertEqual(issues.count, 3)
        guard issues.count == 3 else { return }

        switch issues[safe: 0]?.reason {
        case .unexpectedText(let text): XCTAssertEqual(text, "Unexpected")
        default: XCTFail("Wrong issues[0].reason: \(String(describing: issues[safe: 0]?.reason.description))")
        }
        XCTAssertEqual(try XCTUnwrap(issues[safe: 0]?.lineRange), 5...5)

        switch issues[safe: 1]?.reason {
        case .timecodeMissing: break
        default: XCTFail("Wrong issues[1].reason: \(String(describing: issues[safe: 1]?.reason.description))")
        }
        XCTAssertEqual(try XCTUnwrap(issues[safe: 1]?.lineRange), 11...12)

        switch issues[safe: 2]?.reason {
        case .timecodeMissing: break
        default: XCTFail("Wrong issues[2].reason: \(String(describing: issues[safe: 2]?.reason.description))")
        }
        XCTAssertEqual(try XCTUnwrap(issues[safe: 2]?.lineRange), 20...21)
    }

}
