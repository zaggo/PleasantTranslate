//
//  SentenceTests.swift
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

final class SentenceTests: XCTestCase {

    func testCalculateSplits() throws {
        let targetLanguageHandler = EnglishTargetLanguageHandler()
        let lines = [
            "Aber meine besteht aus einem Kreis,",
            "nicht einmal einem ganzen."
          ]
        let sentence: Sentence = .init(text: "But mine exists of one circle, not even a whole one.",
                                       extras: [],
                                       sources: [SentenceSource(subtitleIndex: 0, lineIndex: 0, range: lines[0].fullRange),
                                                 SentenceSource(subtitleIndex: 0, lineIndex: 1, range: lines[1].fullRange)])
        let subtitle: Subtitle = Subtitle(id: "german",
                                          timecode: .sample,
                                          lines: lines)
        let splits = sentence.calculateSplits(subtitles: [subtitle], targetLanguageHandler: targetLanguageHandler)
        let splitLines = sentence.split(at: splits)
        XCTAssertEqual(splits.count, 2)
        let splitInfo = try XCTUnwrap(splits[safe: 0])
        XCTAssertFalse(splitInfo.isVirtualSplit)
        XCTAssertEqual(splitInfo.line, lines[safe: 0])
        XCTAssertEqual(splitLines[safe: 0], "But mine exists of one circle,")
        XCTAssertEqual(splitLines[safe: 1], "not even a whole one.")
    }
    
    func testCalculateSplitsWordOptimized() throws {
        let targetLanguageHandler = EnglishTargetLanguageHandler()
        let lines = [
            "Aber meine besteht aus einem Kreis,",
            "nicht einmal einem ganzen."
          ]
        let sentence: Sentence = .init(text: "But short one circle and not even a whole one.",
                                       extras: [],
                                       sources: [SentenceSource(subtitleIndex: 0, lineIndex: 0, range: lines[0].fullRange),
                                                 SentenceSource(subtitleIndex: 0, lineIndex: 1, range: lines[1].fullRange)])
        let subtitle: Subtitle = Subtitle(id: "german",
                                          timecode: .sample,
                                          lines: lines)
        let splits = sentence.calculateSplits(subtitles: [subtitle], targetLanguageHandler: targetLanguageHandler)
        let splitLines = sentence.split(at: splits)
        XCTAssertEqual(splits.count, 2)
        let splitInfo = try XCTUnwrap(splits[safe: 0])
        XCTAssertFalse(splitInfo.isVirtualSplit)
        XCTAssertEqual(splitInfo.line, lines[safe: 0])
        XCTAssertEqual(splitLines[safe: 0], "But short one circle")
        XCTAssertEqual(splitLines[safe: 1], "and not even a whole one.")
    }

    func testCalculateSplitsCommaOptimized() throws {
        let targetLanguageHandler = EnglishTargetLanguageHandler()
        let lines = [
            "Aber meine besteht aus einem Kreis,",
            "nicht einmal einem ganzen."
          ]
        let sentence: Sentence = .init(text: "But mine exists of one circle with filler, not even a whole one.",
                                       extras: [],
                                       sources: [SentenceSource(subtitleIndex: 0, lineIndex: 0, range: lines[0].fullRange),
                                                 SentenceSource(subtitleIndex: 0, lineIndex: 1, range: lines[1].fullRange)])
        let subtitle: Subtitle = Subtitle(id: "german",
                                          timecode: .sample,
                                          lines: lines)
        let splits = sentence.calculateSplits(subtitles: [subtitle], targetLanguageHandler: targetLanguageHandler)
        let splitLines = sentence.split(at: splits)
        XCTAssertEqual(splits.count, 2)
        let splitInfo = try XCTUnwrap(splits[safe: 0])
        XCTAssertFalse(splitInfo.isVirtualSplit)
        XCTAssertEqual(splitInfo.line, lines[safe: 0])
        XCTAssertEqual(splitLines[safe: 0], "But mine exists of one circle with filler,")
        XCTAssertEqual(splitLines[safe: 1], "not even a whole one.")
    }

    func testCalculateSplitsLongLine() throws {
        let targetLanguageHandler = GermanTargetLanguageHandler()
        let lines1 = [
            "But on a cold afternoon,",
            "after school..."
          ]
        let lines2 = [
            "something happened.",
          ]
        let sentence: Sentence = .init(text: "Doch an einem kalten Nachmittag nach der Schule passierte etwas.",
                                       extras: [],
                                       sources: [
                                        SentenceSource(subtitleIndex: 0, lineIndex: 0, range: lines1[0].fullRange),
                                        SentenceSource(subtitleIndex: 0, lineIndex: 1, range: lines1[1].fullRange),
                                        SentenceSource(subtitleIndex: 1, lineIndex: 0, range: lines2[0].fullRange),
                                       ])
        let subtitle1: Subtitle = Subtitle(id: "1",
                                          timecode: .sample,
                                          lines: lines1)
        let subtitle2: Subtitle = Subtitle(id: "2",
                                          timecode: .sample,
                                          lines: lines2)
        let splits = sentence.calculateSplits(subtitles: [subtitle1, subtitle2], targetLanguageHandler: targetLanguageHandler)
        XCTAssertEqual(splits.count, 3)
        let splitInfo1 = try XCTUnwrap(splits[safe: 0])
        XCTAssertFalse(splitInfo1.isVirtualSplit)
        XCTAssertEqual(splitInfo1.line, lines1[safe: 0])
        let splitInfo2 = try XCTUnwrap(splits[safe: 1])
        XCTAssertFalse(splitInfo2.isVirtualSplit)
        XCTAssertEqual(splitInfo2.line, lines1[safe: 1])
        let splitInfo3 = try XCTUnwrap(splits[safe: 2])
        XCTAssertFalse(splitInfo3.isVirtualSplit)
        XCTAssertEqual(splitInfo3.line, lines2[safe: 0])

        let splitLines = sentence.split(at: splits)
        XCTAssertEqual(splitLines[safe: 0], "Doch an einem kalten Nachmittag")
        XCTAssertEqual(splitLines[safe: 1], "nach der Schule")
        XCTAssertEqual(splitLines[safe: 2], "passierte etwas.")
    }

    func testCalculateSplitsManyShortParts() throws {
        let targetLanguageHandler = JapaneseTargetLanguageHandler()
        let lines = [
            ["\"Let us live..."],
            ["\"...that when it is over..."],
            ["\"...we can look each other..."],
            ["\"...in the eye..."],
            ["\"...and know..."],
            ["\"...that we..."],
            ["\"...have acted..."],
            ["\"...honorably.\""],
        ]
        let sources = lines.enumerated().map { SentenceSource(subtitleIndex: $0, lineIndex: 0, range: $1[0].fullRange) }
        let sentence = Sentence(text: #""生きよう" "それが終わった時" "互いの目を見て" "知ろう" "名誉ある行動をしたことを""#,
                                extras: [],
                                sources: sources)
        let subtitles = lines.enumerated().map { Subtitle(id: "\($0)", timecode: .sample, lines: $1) }
        
        let splits = sentence.calculateSplits(subtitles: subtitles, targetLanguageHandler: targetLanguageHandler)
        let splitLines = sentence.split(at: splits)
        XCTAssertEqual(splits.count, 8)
        XCTAssertEqual(splitLines[safe: 0], "\"生きよう\"")
        XCTAssertEqual(splitLines[safe: 1], "\"それが終わった時\"")
        XCTAssertEqual(splitLines[safe: 2], "\"互いの目を見て\"")
        XCTAssertEqual(splitLines[safe: 3], "\"知ろう\"")
        XCTAssertEqual(splitLines[safe: 4], "\"名誉")
        XCTAssertEqual(splitLines[safe: 5], "ある")
        XCTAssertEqual(splitLines[safe: 6], "行動を")
        XCTAssertEqual(splitLines[safe: 7], "したことを\"")

    }
}
