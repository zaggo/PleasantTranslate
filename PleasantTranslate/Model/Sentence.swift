//
//  Sentence.swift
//  
//
//  Created by Eberhard Rensch on 04.05.21.
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
import Cocoa
import os
struct Sentence: Identifiable {
         
    // MARK: - API
    func translate(with text: String) -> Sentence {
        .init(text: text, extras: extras, sources: sources)
    }

    func calculateSplits(subtitles: [Subtitle],
                         targetLanguageHandler: any TargetLanguageHandler) -> [LineSplitInfo] {
        
        // Calculate length of the translated text
        let targetTextLength = textForSplitting.count
        
        // Calculate length of the original Text
        let sourceTextLength = sources.reduce(0) { total, source in
            let line = subtitles[source.subtitleIndex].lines[source.lineIndex]
            let sourceLine = line[source.range]
            return total + sourceLine.count
        }
        
        if sourceTextLength == 0 {
           // logger.critical("sourceTextLength == 0!")
            guard let source = sources.first else { return [] }
            let subtitle = subtitles[source.subtitleIndex]
            let originalLine = String(subtitle.lines[source.lineIndex][source.range])
            return [LineSplitInfo(id: "Error \(UUID().uuidString)",
                                  line: originalLine,
                                  subtitleIndex: source.subtitleIndex,
                                  lineIndex: source.lineIndex,
                                  isVirtualSplit: false,
                                  percentage: 1,
                                  proposedSplitPosition: 0)]
        }
        
        // Calculate how many percent of the whole sentence is in each original subtite line
        let sourceLinePercentage = sources.map { source -> Double in
            let line = subtitles[source.subtitleIndex].lines[source.lineIndex]
            let sourceLine = line[source.range]
            return Double(sourceLine.count)/Double(sourceTextLength)
        }
        
        // Calculate the theoretical split position of the translated text
        // based on the sourcetext percentage.
        // This might split the translated text in the middle of a word.
        // We try to fix this below…
        var proposedSplitLengths = sourceLinePercentage.map { Int($0 * Double(targetTextLength)) }
        
        // Fix rounding errors by adding the missing characters to the shortest lines.
        var difference = targetTextLength - proposedSplitLengths.reduce(0, { $0+$1 })
        while difference > 0 {
            guard let min = proposedSplitLengths.min(),
                  let index = proposedSplitLengths.firstIndex(of: min) else { break }
            proposedSplitLengths[index] += 1
            difference -= 1
        }
        
        var lineSplits = [LineSplitInfo]()
        var lastSplitPos = 0
        for index in 0..<proposedSplitLengths.count {
            let source = sources[index]
            let subtitle = subtitles[source.subtitleIndex]
            let originalLine = String(subtitle.lines[source.lineIndex][source.range])
            let percentage = sourceLinePercentage[index]
            let proposedSplitPosition = lastSplitPos + proposedSplitLengths[index]
            
            // In case the calculated length of the target is too long
            if proposedSplitLengths[index] > targetLanguageHandler.maxLineLength {
                let virtualSplit = lastSplitPos + proposedSplitLengths[index]/2
                lineSplits.append(LineSplitInfo(id: source.id+"-Virtual",
                                                line: originalLine,
                                                subtitleIndex: source.subtitleIndex,
                                                lineIndex: source.lineIndex,
                                                isVirtualSplit: true,
                                                percentage: percentage/2,
                                                proposedSplitPosition: virtualSplit))
                lineSplits.append(LineSplitInfo(id: source.id,
                                                line: NSLocalizedString("<Long line split>", comment: ""),
                                                subtitleIndex: source.subtitleIndex,
                                                lineIndex: source.lineIndex,
                                                isVirtualSplit: false,
                                                percentage: percentage/2,
                                                proposedSplitPosition: proposedSplitPosition))
            } else {
                lineSplits.append(LineSplitInfo(id: source.id,
                                                line: originalLine,
                                                subtitleIndex: source.subtitleIndex,
                                                lineIndex: source.lineIndex,
                                                isVirtualSplit: false,
                                                percentage: percentage,
                                                proposedSplitPosition: proposedSplitPosition))
            }
            lastSplitPos = proposedSplitPosition
        }
        
        // This will optimize the splits, so the line doesn't split in the middle of
        // a word
        return targetLanguageHandler.optimizeSplits(for: textForSplitting,
                                                    splits:lineSplits)
    }
    
    var textForSplitting: String {
        var out = text
        if extras.contains(.startEllipsis) { out = "… \(out)" }
        // if extras.contains(.endEllipsis) { out = "\(out)…" }
        if extras.contains(.hyphened) { out = "- \(out)" }
        return out
    }
    
    func split(at splits: [LineSplitInfo]) -> [String] {
        var fragments: [String] = []
        let textToSplit = textForSplitting
        var lowerBound = textToSplit.startIndex
        for split in splits.dropLast() {
            guard let upperBound = textToSplit.index(lowerBound, offsetBy: split.proposedSplitPosition, limitedBy: textToSplit.endIndex) else {
                let fragment = textToSplit[lowerBound..<textToSplit.endIndex]
                fragments.append(String(fragment))
                return fragments
            }
            let fragment = textToSplit[lowerBound..<upperBound].trimmingCharacters(in: .whitespaces)
            fragments.append(String(fragment))
            lowerBound = upperBound
        }
        let fragment = textToSplit[lowerBound..<textToSplit.endIndex].trimmingCharacters(in: .whitespaces)
        fragments.append(String(fragment))
        return fragments
    }

    // MARK: - iVars
    let id: String = UUID().uuidString
    let text: String
    let extras: Extras
    let sources: [SentenceSource]
    
    // MARK: - Constants
    lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: Self.self))

    // MARK: - Helper
    struct Extras: OptionSet {
        let rawValue: Int
        
        static let hyphened = Extras(rawValue: 1 << 0)
        static let startEllipsis = Extras(rawValue: 1 << 1)
        //static let endEllipsis = Extras(rawValue: 1 << 2)
    }
}

extension Sentence {
    var sourcesByEntryIndex: [(Int, [SentenceSource])] {
        var sections: [Int: [SentenceSource]] = [:]
        for source in sources {
            var section = sections[source.subtitleIndex] ?? []
            section.append(source)
            sections[source.subtitleIndex] = section
        }
        return sections.reduce(into: []) { (reduction, record) in
            reduction.append((record.key, record.value))
        }.sorted { $0.0 < $1.0 }
    }
    
    func attributedString(for splitInfos: [LineSplitInfo]) -> AttributedString {
        var out = AttributedString(textForSplitting)
        var lastStart = out.startIndex
        var colorIndex = 0
        for split in splitInfos.dropLast() {
            let endIndex = out.index(lastStart, offsetByCharacters: split.proposedSplitPosition)
            out[lastStart..<endIndex].foregroundColor = Self.lineSplitColors[colorIndex]
            lastStart = endIndex
            colorIndex = 1 - colorIndex
        }
        out[lastStart..<out.endIndex].foregroundColor = Self.lineSplitColors[colorIndex]
        return out
    }
    
    static let lineSplitColors: [NSColor] = [.systemIndigo, .systemOrange]
}
