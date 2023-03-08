//
//  TargetLanguageHandler.swift
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
import NaturalLanguage

protocol TargetLanguageHandler: Identifiable {
    static var displayName: String { get }
    static var twoLetterCode: LanguageTwoLetterCode { get }
    static var naturalLanguage: NLLanguage { get }
    
    var tokenizer: NLTokenizer { get }

    var maxLineLength: Int { get }

    var splitAfterTriggers: [String] { get }
    var splitBeforeTriggers: [String] { get }
    var splitAfterWordTriggers: [String] { get }
    var splitBeforeWordTriggers: [String] { get }

    init()
    func optimizeSplits(for text: String, splits: [LineSplitInfo]) -> [LineSplitInfo]
    
    func append(senctenceWithText: String, to text: String) -> String
}

extension TargetLanguageHandler {
    var id: LanguageTwoLetterCode { Self.twoLetterCode }
}

extension TargetLanguageHandler {
    func optimizeSplits(for text: String, splits: [LineSplitInfo]) -> [LineSplitInfo] {
        tokenizer.string = text
        
        var optimizedSplits: [LineSplitInfo] = []
        
        var lowerBound = text.startIndex
//        var lastSplitPosition = 0
        for split in splits.dropLast() {
            let wordRanges = tokenizer.tokens(for: lowerBound..<text.endIndex)
            //let targetLength = split.proposedSplitPosition - lastSplitPosition
            for (index, wordRange) in wordRanges.enumerated() {
                
                let proposedUpperBound = wordRange.upperBound
                //let debugfragment = String(text[lowerBound..<proposedUpperBound])
                let distance = text.distance(from: text.startIndex, to: proposedUpperBound)
                if distance >= split.proposedSplitPosition {
                    var upperBound = proposedUpperBound
                    
                    if let refinedUpperBound = searchTriggerdSplit(in: text, lowerBound: lowerBound, around: proposedUpperBound) {
                        upperBound = refinedUpperBound
                    } else if let refinedUpperBound = searchWordSplit(in: text, lowerBound: lowerBound, tokens: wordRanges, around: index) {
                        upperBound = refinedUpperBound
                    }
                    
                    let optimized = split.copyWithProposedSplit(at: text.distance(from: lowerBound, to: upperBound))
                    optimizedSplits.append(optimized)
                    lowerBound = upperBound
                    break
                }
            }
 //           lastSplitPosition = split.proposedSplitPosition
        }
        
        if let optimized = splits.last?.copyWithProposedSplit(at: text.distance(from: lowerBound, to: text.endIndex)) {
            optimizedSplits.append(optimized)
        }
        return optimizedSplits
    }
}

// MARK: - Optimize Algorithms
extension TargetLanguageHandler {
    func searchTriggerdSplit(in text: String,
                             lowerBound: String.Index,
                             around pos: String.Index) -> String.Index? {
        let backwardsAfter = searchForSplitTriggers(in: text,
                                                    startAt: pos,
                                                    lowerBound: lowerBound,
                                                    searchBackwards: true,
                                                    triggers: splitAfterTriggers,
                                                    splitBefore: false)
        let backwardsBefore = searchForSplitTriggers(in: text,
                                                     startAt: pos,
                                                     lowerBound: lowerBound,
                                                     searchBackwards: true,
                                                     triggers: splitBeforeTriggers,
                                                     splitBefore: true)
        let forewardsAfter = searchForSplitTriggers(in: text,
                                                    startAt: pos,
                                                    lowerBound: lowerBound,
                                                    searchBackwards: false,
                                                    triggers: splitAfterTriggers,
                                                    splitBefore: false)
        let forewardsBefore = searchForSplitTriggers(in: text,
                                                     startAt: pos,
                                                     lowerBound: lowerBound,
                                                     searchBackwards: false,
                                                     triggers: splitBeforeTriggers,
                                                     splitBefore: true)

        let availableSplits = [backwardsAfter, backwardsBefore, forewardsAfter, forewardsBefore].compactMap({ $0 })
        
        guard !availableSplits.isEmpty else { return nil }
        
        let sortedSplits = availableSplits.sorted { $0.distanceFromProposedPosition < $1.distanceFromProposedPosition }
        return sortedSplits.first?.splitPosition
    }
    
    func searchForSplitTriggers(in text: String,
                                startAt: String.Index,
                                lowerBound: String.Index,
                                searchBackwards: Bool,
                                triggers: [String],
                                splitBefore: Bool,
                                maxDistance: Int = 5) -> SplitCandidate? {
        var searchStartIndex = startAt
        var limit = text.endIndex
        
        if searchBackwards {
            let correctedStartIndex = text.index(startAt,
                                                 offsetBy: -1,
                                                 limitedBy: text.startIndex)
            searchStartIndex =  correctedStartIndex ?? startAt
            limit = text.startIndex
        }
        
        for step in (0..<maxDistance) {
            guard let pos = text.index(searchStartIndex,
                                       offsetBy: step * (searchBackwards ? -1 : 1),
                                       limitedBy: limit) else { break }
            guard pos > lowerBound else { return nil }
            if let r = isRefinedSplitPos(in: text,
                                         pos: pos,
                                         triggers: triggers,
                                         splitBefore: splitBefore) {
                return SplitCandidate(splitPosition: r, distanceFromProposedPosition: step - (splitBefore ? 1 : 0))
            }
        }
        return nil
    }
    
    func isRefinedSplitPos(in text: String,
                                   pos: String.Index,
                                   triggers: [String],
                                   splitBefore: Bool) -> String.Index? {
        guard text.indices.contains(pos) else { return nil }
        
        for trigger in triggers {
            if trigger.count>1,
               let endPos = text.index(pos, offsetBy: trigger.count, limitedBy: text.endIndex),
               text[pos..<endPos] == trigger {
                    return splitBefore ? pos : endPos
            } else if String(text[pos]) == trigger {
                return splitBefore ? pos : text.index(pos, offsetBy: 1, limitedBy: text.endIndex)
            }
        }
        return nil
    }
}

extension TargetLanguageHandler {
    func searchWordSplit(in text: String,
                         lowerBound: String.Index,
                         tokens: [Range<String.Index>],
                         around tokenIndex: Int) -> String.Index? {
        
        let backwardsBefore = searchForSplitWord(in: text,
                                                 lowerBound: lowerBound,
                                                 tokens: tokens,
                                                 startAtIndex: tokenIndex,
                                                 searchBackwards: true,
                                                 splitBefore: true,
                                                 triggers: splitBeforeWordTriggers)
        let forewardsBefore = searchForSplitWord(in: text,
                                                 lowerBound: lowerBound,
                                                 tokens: tokens,
                                                 startAtIndex: tokenIndex,
                                                 searchBackwards: false,
                                                 splitBefore: true,
                                                 triggers: splitBeforeWordTriggers)
        let backwardsAfter = searchForSplitWord(in: text,
                                                lowerBound: lowerBound,
                                                tokens: tokens,
                                                startAtIndex: tokenIndex,
                                                searchBackwards: true,
                                                splitBefore: false,
                                                triggers: splitAfterWordTriggers)
        let forewardsAfter = searchForSplitWord(in: text,
                                                lowerBound: lowerBound,
                                                tokens: tokens,
                                                startAtIndex: tokenIndex,
                                                searchBackwards: false,
                                                splitBefore: false,
                                                triggers: splitAfterWordTriggers)
        
        let availableSplits = [backwardsBefore, forewardsBefore, backwardsAfter, forewardsAfter].compactMap({ $0 })
        
        guard !availableSplits.isEmpty else { return nil }
        
        let sortedSplits = availableSplits.sorted { $0.distanceFromProposedPosition < $1.distanceFromProposedPosition }
        return sortedSplits.first?.splitPosition
    }
    
    func searchForSplitWord(in text: String,
                            lowerBound: String.Index,
                            tokens: [Range<String.Index>],
                            startAtIndex: Int,
                            searchBackwards: Bool,
                            splitBefore: Bool,
                            triggers: [String],
                            maxDistance: Int = 2) -> SplitCandidate? {
        //print("Check Words backwards: \(searchBackwards)")
        for step in (1..<maxDistance) {
            let tokenIndex = startAtIndex + step * (searchBackwards ? -1:1)
            guard tokens.indices.contains(tokenIndex) else { return nil }
            let word = String(text[tokens[tokenIndex]])
            //print("Check word: \(word)")
            if triggers.contains(word) {
                //print("Triggered")
                if splitBefore {
                    guard tokens[tokenIndex].lowerBound > lowerBound else { return nil }
                    return SplitCandidate(splitPosition: tokens[tokenIndex].lowerBound, distanceFromProposedPosition: step)
                } else {
                    guard tokens[tokenIndex].upperBound > lowerBound else { return nil }
                    return SplitCandidate(splitPosition: tokens[tokenIndex].upperBound, distanceFromProposedPosition: step)
                }
            }
        }
        
        return nil
    }
    
}

// MARK: - Helpers
struct SplitCandidate {
    let splitPosition: String.Index
    let distanceFromProposedPosition: Int
}

extension BidirectionalCollection where Element: Equatable {
    func isLastElement(_ element: Element) -> Bool {
        last == element
    }
}
