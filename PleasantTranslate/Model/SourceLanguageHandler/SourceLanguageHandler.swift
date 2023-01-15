//
//  SourceLanguageHandler.swift
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

import Foundation
import NaturalLanguage

protocol SourceLanguageHandler: Identifiable {
    static var displayName: String { get }
    static var twoLetterCode: LanguageTwoLetterCode { get }
    
    var naturalLanguage: NLLanguage { get }
    
    var continuationPatternPresets: [PrewashLineContinuationPattern] { get }
    var unwantedCharactersPresets: [String] { get }

    init()
    
    func prewash(subtitles: [Subtitle], disabledSubtitleIds: Set<SubtitleId>) -> ([Subtitle], [Int])
}

extension SourceLanguageHandler {
    var id: LanguageTwoLetterCode { Self.twoLetterCode }
    
    func prewash(subtitles: [Subtitle], disabledSubtitleIds: Set<SubtitleId>) -> ([Subtitle], [Int]) {
        // Removing Multiline Continuation Characters
        var (processedSubtitles,  changedSubtitles) = removeContinuationPatterns(subtitles: subtitles,
                                                                                 disabledSubtitleIds: disabledSubtitleIds)
        
        // Remove other unwanted characters
        for index in 0..<processedSubtitles.count {
            let subtitle = processedSubtitles[index]
            
            guard !disabledSubtitleIds.contains(subtitle.id) else { continue }

            var processedLines = subtitle.lines
            
            var deleteIndexes: [Int] = []
            for (row, line) in processedLines.enumerated() {
                for unwanted in unwantedCharactersPresets where line.contains(unwanted) {
                    processedLines[row] = line.replacingOccurrences(of: unwanted, with: "")
                    changedSubtitles.insert(index) // Even if disabled, count the change!
                }
                
                let trimmed = processedLines[row].trimmingCharacters(in: CharacterSet.whitespaces)
                if trimmed.isEmpty || trimmed == "-" {
                    deleteIndexes.append(row)
                }
            }
            
            // Cleanup any empty lines
            for row in deleteIndexes.reversed() {
                processedLines.remove(at: row)
                changedSubtitles.insert(index) // Even if disabled, count the change!
            }

            if changedSubtitles.contains(index) && !disabledSubtitleIds.contains(subtitle.id) {
                processedSubtitles[index] = subtitle.copyByReplacing(lines: processedLines)
            }
        }
 
        return (processedSubtitles, Array(changedSubtitles).sorted())
    }

    private func removeContinuationPatterns(subtitles: [Subtitle], disabledSubtitleIds: Set<SubtitleId>) -> ([Subtitle], Set<Int>) {
        guard subtitles.count > 1 else { return (subtitles, []) }
        
        var processedSubtitles = subtitles
        var changedSubtitles = Set<Int>()
        
        for index in 0..<processedSubtitles.count-1 {
            let preceedingSubtitle = processedSubtitles[index]
            let followingSubtitle = processedSubtitles[index+1]
            
            var preceedingLines = preceedingSubtitle.lines  // Mutable
            var followingLines = followingSubtitle.lines    // Mutable
            
            guard continuationPatternPresets.process(preceedingLines: &preceedingLines, followingLines: &followingLines) else {
                continue
            }
            
            if !disabledSubtitleIds.contains(preceedingSubtitle.id) {
                processedSubtitles[index] = preceedingSubtitle.copyByReplacing(lines: preceedingLines)
            }
            changedSubtitles.insert(index) // Even if disabled, count the change!

            if !disabledSubtitleIds.contains(followingSubtitle.id) {
                processedSubtitles[index+1] = followingSubtitle.copyByReplacing(lines: followingLines)
            }
            changedSubtitles.insert(index+1) // Even if disabled, count the change!
        }
        
        return (processedSubtitles, changedSubtitles)
    }
}
