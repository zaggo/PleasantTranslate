//
//  SplitTranslationProcessorTests.swift
//  PleasantTranslateTests
//
//  Created by Privat on 08.03.23.
//

import XCTest
@testable import PleasantTranslate

final class SplitTranslationProcessorTests: XCTestCase {
    let doc = PleasantTranslateDocument.sample
    lazy var preWasher = PrewashProcessor(inputProvider: nil, document: doc)
    lazy var processor = SplitTranslationsProcessor(inputProvider: preWasher, document: doc)

    func testSpaceAfterJoinedSenctences() async throws {
        doc.targetLanguage = GermanTargetLanguageHandler.self
        
        let line1 = "Why? Do you have somewhere else to be?"
        let line2 = "Me? No. Just wondered about the time."
        let subtitles: [Subtitle] = [
            .sample(withLines: [line1]),
            .sample(withLines: [line2]),
            .sample(withLines: ["Okay. Please get back to work now."]),
            .sample(withLines: ["Sure thing! I’ll get back to it."]),
        ]

        let source11 = try SentenceSource(subtitleIndex: 0, lineIndex: 0, range: XCTUnwrap(line1.range(of: "Why?")))
        let source12 = try SentenceSource(subtitleIndex: 0, lineIndex: 0, range: XCTUnwrap(line1.range(of: "Do you have somewhere else to be?")))
        let source21 = try SentenceSource(subtitleIndex: 1, lineIndex: 0, range: XCTUnwrap(line2.range(of: "Me?")))
        let source22 = try SentenceSource(subtitleIndex: 1, lineIndex: 0, range: XCTUnwrap(line2.range(of: "No.")))
        let source23 = try SentenceSource(subtitleIndex: 1, lineIndex: 0, range: XCTUnwrap(line2.range(of: "Just wondered about the time.")))
        let sentence11 = Sentence(text: "Warum?", extras: [], sources: [source11])
        let sentence12 = Sentence(text: "Müssen Sie woanders hin?", extras: [], sources: [source12])
        let sentence21 = Sentence(text: "Ich?", extras: [], sources: [source21])
        let sentence22 = Sentence(text: "Nein.", extras: [], sources: [source22])
        let sentence23 = Sentence(text: "Ich habe mich nur über die Uhrzeit gewundert.", extras: [], sources: [source23])
        let translations: ([Sentence], [Sentence]) = (
        [sentence11, sentence12, sentence21, sentence22, sentence23],
        [sentence11, sentence12, sentence21, sentence22, sentence23]
        )
                
        await preWasher.processAndCacheResultsForUnitTest(input: subtitles)

        let processed: [Subtitle] = try await processor.process(input: translations).extractSuccessResult()
        
        XCTAssertEqual(processed.count, 2)
        XCTAssertEqual(processed[safe: 0]?.lines[safe: 0], "Warum? Müssen Sie woanders hin?")
        XCTAssertEqual(processed[safe: 1]?.lines[safe: 0], "Ich? Nein.")
        XCTAssertEqual(processed[safe: 1]?.lines[safe: 1], "Ich habe mich nur über die Uhrzeit gewundert.")
    }
}
