//
//  SplitTranslationsProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 16.05.21.
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
import NaturalLanguage

class SplitTranslationsProcessor: Processor {
    
    // MARK: - Initialization
    override func addBindings() {
        super.addBindings()
        
        document?.$targetLanguage
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                Task { await self.resetProcessor() }
            })
            .store(in: &bindings)

        $cachedResult
            .map { cachedResults in
                guard let processResult = cachedResults?.processingResult,
                      case .success(let result) = processResult,
                      let translatedSubtitles = result as? [Subtitle] else {
                    return []
                }
                return translatedSubtitles
            }
            .assign(to: &$translatedSubtitles)
    }
    
    
    // MARK: - UI
    override var processorName: String { NSLocalizedString("Split Translations", comment: "") }
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                SplitTranslationsSettingsView(processor: self)
            }
        )
    }

    override var resultsView: AnyView {
        AnyView(
            ProcessingResultView(
                processor: self,
                content: { (content: [Subtitle]) in
                    ScrollView {
                        LazyVStack {
                            ForEach(self.translatedSentences) { sentence in
                                VStack {
                                    TranslatedSubtitleView(sentence: sentence,
                                                           originalSubtitles: self.originalSubtitles,
                                                           translatedSubtitles: content,
                                                           targetLanguageHandler: self.document?.targetLanguageHandler)
                                    Divider()
                                }
                            }
                        }
                    }
                }
            )
        )
    }
    
    override var alternativeResultsView: AnyView {
        AnyView(SplitTranslationsIssuesView(processor: self))
    }
    
    override var alternativeResultsTitle: String? { NSLocalizedString("Issues", comment: "") }
    
    // MARK: - API
    @MainActor
    override func resetProcessor() {
        super.resetProcessor()
        issues.removeAll()
        numberOfSubtitles = 0
        originalSubtitles = []
        translatedSentences = []
    }
    
    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let (translatedSentences, _) = input as? ([Sentence], [Sentence]) else {
            return .failure(ProcessorError.wrongInputFormat)
        }
        
        guard let document else {
            return .failure(ProcessorError.noDocument)
        }
        
        guard let prewashResults = inputProvider?.processedOutput(from: PrewashProcessor.id),
              case .success(let results) = prewashResults.processingResult,
              let originalSubtitles = results as? [Subtitle] else {
            return .failure(ProcessorError.missingInput)
        }
        
        let targetLanguageHandler = document.targetLanguageHandler
        
        var translatedSubtitles: [Subtitle] = []
        
        for sentence in translatedSentences {
            let lineSplits = sentence.calculateSplits(subtitles: originalSubtitles,
                                                      targetLanguageHandler: targetLanguageHandler)
            var splittedLines = sentence.split(at: lineSplits)
            
            var isMoreThan2Lines = false
            var lineOffset = 0
            for lineSplit in lineSplits {
                let originalSubtitle = originalSubtitles[lineSplit.subtitleIndex]
                
                let isEntryExisting = translatedSubtitles.indices.contains(lineSplit.subtitleIndex)
                var translatedSubtitle: Subtitle
                if isEntryExisting {
                    translatedSubtitle = translatedSubtitles[lineSplit.subtitleIndex]
                } else {
                    lineOffset = 0
                    translatedSubtitle = originalSubtitle.copyByReplacing(lines: [])
                }
                
                var isLineExisting = translatedSubtitle.lines.indices.contains(lineSplit.lineIndex+lineOffset)
                var line = isLineExisting ? translatedSubtitle.lines[lineSplit.lineIndex+lineOffset] : ""
                var isVirtualSplit = lineSplit.isVirtualSplit
                if splittedLines.isEmpty {
                    await addIssue(.init(sentence: sentence, reason: .lessLines))
                } else {
                    let translatedLine = splittedLines.removeFirst()
                    let appended = targetLanguageHandler.append(senctenceWithText: translatedLine, to: line)
                    if appended.count > targetLanguageHandler.maxLineLength && translatedSubtitle.lines.count < 3 {
                        isLineExisting = false
                        line = translatedLine
                        isVirtualSplit = true
                    } else {
                        line = appended
                    }
                    
                    var lines = translatedSubtitle.lines
                    if isLineExisting {
                        lines[lineSplit.lineIndex+lineOffset] = line.trimmingCharacters(in: CharacterSet.whitespaces)
                    } else {
                        lines.append(line.trimmingCharacters(in: CharacterSet.whitespaces))
                    }
                    translatedSubtitle.lines = lines
                }
                if translatedSubtitle.lines.count > 2 {
                    isMoreThan2Lines = true
                }
                if isEntryExisting {
                    translatedSubtitles[lineSplit.subtitleIndex] = translatedSubtitle
                } else {
                    translatedSubtitles.append(translatedSubtitle)
                }
                
                if isVirtualSplit {
                    lineOffset += 1
                    if isMoreThan2Lines {
                        await addIssue(.init(sentence: sentence, reason: .moreThan2Lines))
                    } else {
                        await addIssue(.init(sentence: sentence, reason: .longLineSplit))
                    }
                } else if isMoreThan2Lines {
                    await addIssue(.init(sentence: sentence, reason: .moreThan2Lines))
                }
            }
        }
        
        await MainActor.run {
            self.numberOfSubtitles = self.translatedSubtitles.count
            self.originalSubtitles = originalSubtitles
            self.translatedSentences = translatedSentences
        }
        
        return .success(translatedSubtitles)
    }
    
    // MARK: - Service
    @MainActor
    private func addIssue(_ issue: Issue) {
        self.issues.append(issue)
    }
    
    // MARK: - Publishers
    @Published var numberOfSubtitles: Int = 0
    @Published var translatedSubtitles: [Subtitle] = []
    @Published var issues: [Issue] = []
    
    // MARK: - iVars
    private(set) var originalSubtitles: [Subtitle] = []
    private(set) var translatedSentences: [Sentence] = []
    private var bindings: [AnyCancellable] = []

    // MARK: - Helpers
    struct Issue: Identifiable {
        let id: String = UUID().uuidString
        //        let original: Subtitle
        //        let translated: Subtitle
        let sentence: Sentence
        let reason: Reason
        
        enum Reason {
            case lessLines
            case longLineSplit
            case moreThan2Lines
        }
    }
}

extension SplitTranslationsProcessor.Issue.Reason {
    var displayString: String {
        switch self {
        case .lessLines:
            return "Less Lines"
        case .longLineSplit:
            return "Long Line Split"
        case .moreThan2Lines:
            return "More than 2 lines"
        }
    }
}
