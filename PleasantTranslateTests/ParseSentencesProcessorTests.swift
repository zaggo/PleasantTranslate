//
//  ParseSentencesProcessorTests.swift
//  PleasantTranslateTests
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

import XCTest
@testable import PleasantTranslate

final class ParseSentencesProcessorTests: XCTestCase {
    let doc = PleasantTranslateDocument.sample
    lazy var processor = ParseSentencesProcessor(inputProvider: nil, document: doc)

    func testExample() async throws {

        let subtitles: [Subtitle] = [
            .sample(withLines: ["You´ve got nothing to lose."]),
            .sample(withLines: ["I'm looking for someone of your age", "for the evening news."]),
            .sample(withLines: ["Tell me you are."]),
            .sample(withLines: ["You are Ana.", "-Yes, my child."]),
            .sample(withLines: ["Pretty good.", "And you? Are you still with your teacher?"]),
            .sample(withLines: ["If you had acted like brother", "and sister..."]),
            .sample(withLines: ["everything would be like it was."]),
            
        ]

        let sentences: [Sentence] = try await processor.process(input: subtitles).extractSuccessResult()
        
        XCTAssertEqual(sentences.count, 9)
        let s1 = try XCTUnwrap(sentences[safe: 0])
        XCTAssertEqual(s1.text.trimmed, "You´ve got nothing to lose.")
        XCTAssertEqual(s1.extras, [])
        XCTAssertEqual(s1.sources.count, 1)
        XCTAssertEqual(s1.sources.first?.subtitleIndex, 0)
        XCTAssertEqual(s1.sources.first?.lineIndex, 0)
        XCTAssertEqual(s1.sources.first?.range, subtitles[safe: 0]?.lines[safe: 0]?.fullRange)
        
        let s2 = try XCTUnwrap(sentences[safe: 1])
        XCTAssertEqual(s2.text.trimmed, "I'm looking for someone of your age for the evening news.")
        XCTAssertEqual(s2.extras, [])
        XCTAssertEqual(s2.sources.count, 2)
        XCTAssertEqual(s2.sources[safe: 0]?.subtitleIndex, 1)
        XCTAssertEqual(s2.sources[safe: 0]?.lineIndex, 0)
        XCTAssertEqual(s2.sources[safe: 0]?.range, subtitles[safe: 1]?.lines[safe: 0]?.fullRange)
        XCTAssertEqual(s2.sources[safe: 1]?.subtitleIndex, 1)
        XCTAssertEqual(s2.sources[safe: 1]?.lineIndex, 1)
        XCTAssertEqual(s2.sources[safe: 1]?.range, subtitles[safe: 1]?.lines[safe: 1]?.fullRange)

        let s4 = try XCTUnwrap(sentences[safe: 3])
        XCTAssertEqual(s4.text.trimmed, "You are Ana.")
        XCTAssertEqual(s4.extras, [])
        XCTAssertEqual(s4.sources.count, 1)
        XCTAssertEqual(s4.sources[safe: 0]?.subtitleIndex, 3)
        XCTAssertEqual(s4.sources[safe: 0]?.lineIndex, 0)
        XCTAssertEqual(s4.sources[safe: 0]?.range, subtitles[safe: 3]?.lines[safe: 0]?.fullRange)

        let s5 = try XCTUnwrap(sentences[safe: 4])
        XCTAssertEqual(s5.text.trimmed, "Yes, my child.")
        XCTAssertEqual(s5.extras, .hyphened)
        XCTAssertEqual(s5.sources.count, 1)
        XCTAssertEqual(s5.sources[safe: 0]?.subtitleIndex, 3)
        XCTAssertEqual(s5.sources[safe: 0]?.lineIndex, 1)
        let sourceLine5 = try XCTUnwrap(subtitles[safe: 3]?.lines[safe: 1])
        XCTAssertEqual(s5.sources[safe: 0]?.range, sourceLine5.range(withStartOffset: 1, endOffset: sourceLine5.count))

        let s6 = try XCTUnwrap(sentences[safe: 5])
        XCTAssertEqual(s6.text.trimmed, "Pretty good.")
        XCTAssertEqual(s6.extras, [])
        XCTAssertEqual(s6.sources.count, 1)
        XCTAssertEqual(s6.sources[safe: 0]?.subtitleIndex, 4)
        XCTAssertEqual(s6.sources[safe: 0]?.lineIndex, 0)
        XCTAssertEqual(s6.sources[safe: 0]?.range, subtitles[safe: 4]?.lines[safe: 0]?.fullRange)

        let s7 = try XCTUnwrap(sentences[safe: 6])
        XCTAssertEqual(s7.text.trimmed, "And you?")
        XCTAssertEqual(s7.extras, [])
        XCTAssertEqual(s7.sources.count, 1)
        XCTAssertEqual(s7.sources[safe: 0]?.subtitleIndex, 4)
        XCTAssertEqual(s7.sources[safe: 0]?.lineIndex, 1)
        let range7 = try XCTUnwrap(s7.sources[safe: 0]?.range)
        XCTAssertEqual(subtitles[safe: 4]?.lines[safe: 1]?[range7].trimmed, "And you?")

        let s8 = try XCTUnwrap(sentences[safe: 7])
        XCTAssertEqual(s8.text.trimmed, "Are you still with your teacher?")
        XCTAssertEqual(s8.extras, [])
        XCTAssertEqual(s8.sources.count, 1)
        XCTAssertEqual(s8.sources[safe: 0]?.subtitleIndex, 4)
        XCTAssertEqual(s8.sources[safe: 0]?.lineIndex, 1)
        let range8 = try XCTUnwrap(s8.sources[safe: 0]?.range)
        XCTAssertEqual(subtitles[safe: 4]?.lines[safe: 1]?[range8].trimmed, "Are you still with your teacher?")
        
        let s9 = try XCTUnwrap(sentences[safe: 8])
        XCTAssertEqual(s9.text.trimmed, "If you had acted like brother and sister everything would be like it was.")
        XCTAssertEqual(s9.extras, [])
        XCTAssertEqual(s9.sources.count, 3)
        XCTAssertEqual(s9.sources[safe: 0]?.subtitleIndex, 5)
        XCTAssertEqual(s9.sources[safe: 0]?.lineIndex, 0)
        XCTAssertEqual(s9.sources[safe: 0]?.range, subtitles[safe: 5]?.lines[safe: 0]?.fullRange)
        XCTAssertEqual(s9.sources[safe: 1]?.subtitleIndex, 5)
        XCTAssertEqual(s9.sources[safe: 1]?.lineIndex, 1)
        let range9 = try XCTUnwrap(s9.sources[safe: 1]?.range)
        XCTAssertEqual(subtitles[safe: 5]?.lines[safe: 1]?[range9].trimmed, "and sister")
        XCTAssertEqual(s9.sources[safe: 2]?.subtitleIndex, 6)
        XCTAssertEqual(s9.sources[safe: 2]?.lineIndex, 0)
        XCTAssertEqual(s9.sources[safe: 2]?.range, subtitles[safe: 6]?.lines[safe: 0]?.fullRange)
    }
}
