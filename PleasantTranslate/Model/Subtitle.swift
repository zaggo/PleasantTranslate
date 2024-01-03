//
//  Subtitle.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 03.01.23.
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

import Cocoa

typealias SubtitleId = String

struct Subtitle: Identifiable, Codable, Equatable {
    // MARK: - Initialization
    init(id: SubtitleId, timecode: SubtitleTimecode, lines: [String]) {
        self.id = id
        self.timecode = timecode
        self.lines = lines
    }
    
    // MARK: - API
    func copyByReplacing(lines newLines: [String]) -> Subtitle {
        .init(id: id, timecode: timecode, lines: newLines)
    }
    
    // MARK: - iVars
    var id: SubtitleId
    let timecode: SubtitleTimecode
    var lines: [String]
}

extension Subtitle: CustomStringConvertible {
    var description: String {
        var text = "\(id)\n\(timecode.description)"
        for line in lines {
            text += "\n\(line)"
        }
        return text+"\n"
    }
}

extension Subtitle {
    func attributedLines(for sources: [SentenceSource]) -> [AttributedString] {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let boldFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        
        let notInvolved = AttributeContainer([.foregroundColor: NSColor.tertiaryLabelColor, .font: font])
        var attributedLines = lines.map({ AttributedString($0, attributes: notInvolved) })
        
        for source in sources {
            guard attributedLines.indices.contains(source.lineIndex) else { continue }
            var line = attributedLines[source.lineIndex]
            guard let aLower = AttributedString.Index(source.range.lowerBound, within: line),
                  let aUpper = AttributedString.Index(source.range.upperBound, within: line) else {
                line.foregroundColor = NSColor.red
                attributedLines[source.lineIndex] = line
                continue
            }
            line[aLower..<aUpper].foregroundColor = NSColor.systemIndigo
            line[aLower..<aUpper].font = .init(boldFont)
            attributedLines[source.lineIndex] = line
        }
        return attributedLines
    }
}
