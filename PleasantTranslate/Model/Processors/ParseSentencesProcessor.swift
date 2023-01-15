//
//  ParseSentencesProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 14.05.21.
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

class ParseSentencesProcessor: Processor {

    // MARK: - UI
    override var processorName: String { NSLocalizedString("Parse Sentences", comment: "") }
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                ParseSentencesSettingsView(processor: self)
            }
        )
    }
    
    override var resultsView: AnyView {
        var subtitles: [Subtitle] = []
        if let prewashResults = inputProvider?.processedOutput(from: PrewashProcessor.id),
           case .success(let result) = prewashResults.processingResult {
              subtitles = result as? [Subtitle] ?? []
        }

        return AnyView(
            ProcessingResultView(
                processor: self,
                content: { (content: [Sentence]) in
                    SentencesView(sentences: content, subtitles: subtitles)
                })
        )
    }

    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let originalSubtitles = input as? [Subtitle] else {
            return .failure(ProcessorError.wrongInputFormat)
        }
                
        guard let document else {
            return .failure(ProcessorError.noDocument)
        }
        
        let hyphenRegEx = /^[\-–—]\s*(.+)$/
        let startEllipsisRegEx = /^[…\.]+\s*(.+)$/
        let endEllipsisRegEx = /^(.+)\s*(…|\.{3})$/

        tokenizer.setLanguage(document.sourceLanguageHandler.naturalLanguage)

        var sentences: [Sentence] = []
        var subtitleIndex = 0
        var compount: String = ""
        var sources: [SentenceSource] = []
        var extras: Sentence.Extras = []
        
        repeat {
            let subtitle = originalSubtitles[subtitleIndex]
            var lineIndex = 0
            while lineIndex < subtitle.lines.count {
                let line = subtitle.lines[lineIndex]
                var lineFragment = line.trimmingCharacters(in: CharacterSet.whitespaces)
                
                // Check if the current sentence might be complete, due to special "sentence ending" triggers
                if let match = lineFragment.wholeMatch(of: hyphenRegEx) {
                    // Trigger 1: the remaining fragment is hyphenated
                    let sentence = Sentence(text: String(compount), extras: extras, sources: sources)
                    sentences.append(sentence)
                    
                    // Start the next compount
                    lineFragment = String(match.1) // remove the hyphen (it's messing up the translation)
                    extras = .hyphened // … but remember the hyphen for final assembly after translation.
                    sources = []
                    compount = ""
                } else if let match = lineFragment.wholeMatch(of: startEllipsisRegEx) {
                    // Trigger 2: the remaining fragment starts with an ellipsis or a point
                    let sentence = Sentence(text: String(compount), extras: extras, sources: sources)
                    sentences.append(sentence)
                    
                    // Start the next compount
                    lineFragment = String(match.1) // remove the ellipsis (it's messing up the translation)
                    extras = .startEllipsis //  … but remember the ellipsis for final assembly after translation.
                    sources = []
                    compount = ""
                }
                
                if let match = lineFragment.wholeMatch(of: endEllipsisRegEx) {
                    lineFragment = String(match.1) // remove the ellipsis (it's messing up the translation)
                    //extras.insert(.endEllipsis) //  … but remember the ellipsis for final assembly after translation.
                }
                
                // Add the lineFragment
                let appendedLineFragment = (compount.isEmpty ? "" : " ") + lineFragment
                compount += appendedLineFragment
                
                // Keep track of the source, the appended fragment came from:
                // The exact range of the fragment in the original line
                let range = line.range(of: lineFragment) ?? line.startIndex..<line.endIndex
                var source = SentenceSource(subtitleIndex: subtitleIndex, lineIndex: lineIndex, range: range)

                // The compount contains now either:
                // 1. one complete sentences
                // 2. one or more complete sentences and maybe the beginning of another sentence
                // 3. only the beginning of a sentence
                // Use the NLTokenizer to find out which it is:
                repeat {
                    // Feed the compount to the tokenizer
                    tokenizer.string = compount
                    let tokens = tokenizer.tokens(for: compount.startIndex..<compount.endIndex)
                    
                    // If there was at least one sentence recognized in the compount,
                    // we'll get a `rangeOfSentence` from the NLTokenizer
                    guard let rangeOfSentence = tokens.first else {
                        break // If not, we definitely have only a partial sentence (case 3.) -> bail
                    }
                    
                    // The found sentence reaches the end of the compount.
                    // This could mean one of two things:
                    // a. The sentence is complete
                    // b. The NLTokenizer did recognize a (partial) sentence, but it might continue
                    //    in the next subtitle/line. To be sure, we need to add more fragments
                    //    to the compount to give the NLTokenizer more context in the next iteration
                    guard rangeOfSentence.upperBound < compount.endIndex else {
                        sources.append(source) // Remember the source of the compount for now,
                        break                  // and bail…
                    }
                    
                    // The compount is longer than the recognized sentence:
                    // We have a complete sentence!
                    let detectedSentence = String(compount[rangeOfSentence])
                    
                    // Find out how much of the last added line is included in the
                    // detected sentence
                    let unusedCharsCount = compount.count-detectedSentence.count
                    if unusedCharsCount == lineFragment.count {
                        // Nothing of it… this means the sentence was already complete
                        // before adding the new fragment (but we weren't sure)
                        
                        // Add the detected sentence to the results
                        let sentence = Sentence(text: detectedSentence, extras: extras, sources: sources)
                        sentences.append(sentence)
                        
                        // Start the next compount
                        compount = lineFragment // … with the unused fragment
                        sources = []
                        extras = []
                        continue // -> Iterate the NLTokenizer loop
                    }
                    
                    // Create a source record reflecting the true source of the sentence
                    let endIndex = line.index(line.endIndex, offsetBy: -compount.count+detectedSentence.count)
                    let partialSource = SentenceSource(subtitleIndex: subtitleIndex,
                                                       lineIndex: lineIndex,
                                                       range: line.startIndex..<endIndex)
                    sources.append(partialSource)
                    
                    // Add the detected sentence to the results
                    let sentence = Sentence(text: detectedSentence, extras: extras, sources: sources)
                    sentences.append(sentence)

                    // Start the next compount
                    let fromIndex = appendedLineFragment.index(appendedLineFragment.endIndex, offsetBy: -unusedCharsCount)
                    compount = String(appendedLineFragment[fromIndex..<appendedLineFragment.endIndex])
                    sources = []
                    extras = []

                    // Adjust the current source record to exclude the above partial part
                    guard let sourceFromIndex = line.range(of: compount)?.lowerBound else {
                        fatalError("*** Cannot find \(compount) in \(line)") // Famous last words: This shouldn't happen ever!
                    }
                    source = SentenceSource(subtitleIndex: subtitleIndex, lineIndex: lineIndex, range: sourceFromIndex..<line.endIndex)
                } while true
                
                lineIndex += 1
            }
            
            subtitleIndex += 1
        } while(subtitleIndex < originalSubtitles.count)
        
        // Whatever is left in the compount, we add as the last sentence
        if !compount.isEmpty {
            let sentence = Sentence(text: compount, extras: extras, sources: sources)
            sentences.append(sentence)
        }

        await setStatistics(for: sentences)
        
        return .success(sentences)
    }

    // MARK: - Service
    @MainActor
    private func setStatistics(for sentences: [Sentence]) {
        numberOfSentences = sentences.count
        numberOfCharacters = sentences.reduce(0, { $0 + $1.text.count })
    }

    // MARK: - Publishers
    @Published var numberOfSentences: Int = 0
    @Published var numberOfCharacters: Int = 0

    // MARK: - Constants
    private let tokenizer = NLTokenizer(unit: .sentence)
}
