//
//  ParserProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 09.05.21.
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

import SwiftUI
import Combine
import os

class ParserProcessor: Processor {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        super.init(inputProvider: inputProvider, document: document)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        numberOfDropFromBeginningSubtitles = try container.decode(.numberOfDropFromBeginningSubtitles)
        numberOfDropFromEndSubtitles = try container.decode(.numberOfDropFromEndSubtitles)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(numberOfDropFromBeginningSubtitles, forKey: .numberOfDropFromBeginningSubtitles)
        try container.encode(numberOfDropFromEndSubtitles, forKey: .numberOfDropFromEndSubtitles)
    }
    
    // MARK: - UI
    override var processorName: String { NSLocalizedString("Parse SRT", comment: "") }

    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                ParserSettingsView(processor: self)
            }
        )
    }

    override var resultsView: AnyView {
        AnyView(
            ProcessingResultView(
                processor: self,
                content: { (content: [Subtitle]) in
                    SubtitlesView(subtitles: content)
                })
        )
    }
    
    override var alternativeResultsView: AnyView {
        AnyView(ParserIssuesView(processor: self))
    }

    override var alternativeResultsTitle: String? { NSLocalizedString("Issues", comment: "") }
    
    // MARK: - API
    @MainActor
    override func resetProcessor() {
        super.resetProcessor()
        issues.removeAll()
        numberOfSubtitles = 0
    }

    
    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let inputString = input as? String else {
            return .failure(ProcessorError.wrongInputFormat)
        }
        
        await resetProcessor()
        
        let lines = inputString.components(separatedBy: CharacterSet.newlines)
        
        let parser = SubtitleParser(lines: lines)
        let (subtitles, issues) = parser.parse()
        
        for issue in issues {
            guard let start = issue.lineRange.first,
                  let end = issue.lineRange.last else {
                await addIssue(issue)
                continue
            }
            let except = lines[max(0, start-5)...min(end+5, lines.count)].joined(separator: "\n")
            await addIssue(Issue(lineRange: issue.lineRange, reason: issue.reason, sourceText: except))
        }
        await setNumberOfSubtitles(subtitles.count)

        let dropBegin = subtitles.dropFirst(numberOfDropFromBeginningSubtitles)
        let dropEnd = dropBegin.dropLast(numberOfDropFromEndSubtitles)
        
        return .success(Array(dropEnd))
    }

    
    // MARK: - Service
    @MainActor
    private func setNumberOfSubtitles(_ number: Int) {
        numberOfSubtitles = number
    }
    
    @MainActor
    private func addIssue(_ issue: Issue) {
        self.issues.append(issue)
    }

    
    // MARK: - Publishers
    @Published var numberOfSubtitles: Int = 0
    @Published var issues: [Issue] = []

    @Published var numberOfDropFromEndSubtitles: Int = 0 {
        didSet { Task{ await resetProcessor() } }
    }
    
    @Published var numberOfDropFromBeginningSubtitles: Int = 0 {
        didSet { Task{ await resetProcessor() } }
    }
    
    // MARK: - Constants
    private enum CodingKeys: CodingKey {
        case numberOfDropFromBeginningSubtitles
        case numberOfDropFromEndSubtitles
    }

    enum StateMachine {
        case number
        case timeStamps
        case text
        case error
    }

    // MARK: - Cache
    struct Cache {
        var number: String?
        var timeCode: SubtitleTimecode?
        var text: [String] = []
                
        var asSubtitle: Subtitle? {
            guard let number, let timeCode else { return nil }
            return Subtitle(id: number, timecode: timeCode, lines: text)
        }
                
        mutating func reset() {
            number = nil
            timeCode = nil
            text.removeAll()
        }
    }

    // MARK: - Issue
    struct Issue: Identifiable {
        let id: String = UUID().uuidString
        let lineRange: ClosedRange<Int>
        let reason: Reason
        var sourceText: String?
        
        enum Reason {
            case emptyText(String)
            case numberMissing
            case timecodeMissing
            case unexpectedText(String)
        }
    }
    
    // MARK: - SubtitleParser
    class SubtitleParser {
        // MARK: Initialization
        init(lines: [String]) {
            self.lines = lines
        }
        
        // MARK: API
        func parse() -> ([Subtitle], [ParserProcessor.Issue]) {
            while let subtitle = parseSubtitle() {
                subtitles.append(subtitle)
            }
            
            return (subtitles, issues)
        }
        
        // MARK: Service
        private func parseSubtitle() -> Subtitle? {
            do {
                while currentLine.isEmpty {
                    guard nextLine() else { return nil }
                }

                lastStartIndex = lineIndex
                
                let number = try fetchNumber()
                guard nextLine() else {
                    issues.append(.init(lineRange: lastStartIndex...lineIndex, reason: .timecodeMissing))
                    return nil
                }

                let timecode = try fetchTimecode()
                guard nextLine() else {
                    issues.append(.init(lineRange: lastStartIndex...lineIndex, reason: .emptyText(number)))
                    return .init(id: number, timecode: timecode, lines: [])
                }

                let textLines = parseLines()
                return .init(id: number, timecode: timecode, lines: textLines)
                
            } catch ParserError.notANumber {
                issues.append(.init(lineRange: lastStartIndex...lineIndex, reason: .unexpectedText(currentLine)))
                guard nextLine() else { return nil }
            } catch ParserError.notATimecode {
                issues.append(.init(lineRange: lastStartIndex...lineIndex, reason: .timecodeMissing))
                while !currentLine.isMatch(of: numberPattern) {
                    guard nextLine() else { return nil }
                }
            } catch {
                return nil
            }
            
            return parseSubtitle()
        }
        
        private func parseLines() -> [String] {
            var textLines = [String]()
            while !currentLine.isEmpty {
                textLines.append(currentLine)
                guard nextLine() else {
                    currentLine = ""
                    break
                }
            }
            return textLines
        }
        
        private func fetchNumber() throws -> String {
            guard let match = currentLine.wholeMatch(of: numberPattern) else { throw ParserError.notANumber }
            return String(match.1)
        }
        
        private func fetchTimecode() throws -> SubtitleTimecode {
            guard let match = currentLine.wholeMatch(of: timestampsPattern),
                  let start = SubtitleTimecode.formatter.date(from: String(match.1)),
                  let end = SubtitleTimecode.formatter.date(from: String(match.2)) else { throw ParserError.notATimecode }
            return SubtitleTimecode(start: start, end: end)
        }

        @discardableResult
        private func nextLine() -> Bool {
            guard !lines.isEmpty else { return false }
            lineIndex += 1
            currentLine = lines.removeFirst().trimmingCharacters(in: .whitespaces)
            return true
        }
        
        // MARK: iVars
        private var subtitles: [Subtitle] = []
        private var issues: [ParserProcessor.Issue] = []

        private var lines: [String]
        private var lineIndex = -1
        private var lastStartIndex = 0
        private var currentLine: String = ""
        
        // MARK: Constants
        private let numberPattern = /^\s*(\d+)\s*$/
        private let timestampsPattern = /^\s*(?<start>[\d:,]+)\s*\-\-\>\s*(?<end>[\d:,]+)\s*$/
        
        private enum ParserError: Error {
            case notANumber
            case notATimecode
        }
    }

}

extension ParserProcessor.Issue: CustomStringConvertible {
    var description: String {
        "\(reason) (Lines \(lineRange))"
    }
}

extension ParserProcessor.Issue.Reason: CustomStringConvertible {
    var description: String {
        switch self {
        case .emptyText(let id):
            return String(format: NSLocalizedString("No text for Subtitle #%@", comment: ""), id)
        case .numberMissing:
            return NSLocalizedString("Subtitle number is missing", comment: "")
        case .timecodeMissing:
            return NSLocalizedString("Timecodes are missing", comment: "")
        case .unexpectedText(let text):
            return String(format: NSLocalizedString("Skipped unexpected text: '%@'", comment: ""), text)
        }
    }
}
