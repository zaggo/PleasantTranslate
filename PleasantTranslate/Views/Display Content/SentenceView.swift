//
//  SentenceView.swift
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

struct SentenceView: View {
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 0) {
                Group {
                    if sentence.extras.contains(.hyphened) {
                        Text("– ")
                    }
                    if sentence.extras.contains(.startEllipsis) {
                        Text("…")
                    }
                }
                .foregroundColor(Color(NSColor.tertiaryLabelColor))

                Text(sentence.text)
                    .bold()
            }
            Text("extracted from")
                .italic()
                .font(.caption)
            ForEach(sentence.sourcesByEntryIndex, id: \.0) { section in
                
                if subtitles.indices.contains(section.0) {
                    SubtitleView(subtitle: subtitles[section.0],
                                 sources: section.1)
                } else {
                    Text("Original Subtitle doesn't exist (anymore)!?")
                }
            }
        }
    }
    
    let sentence: Sentence
    let subtitles: [Subtitle]
}

#if DEBUG
struct SentenceView_Previews: PreviewProvider {
    static var previews: some View {
        SentenceView(sentence: .sample, subtitles: [.sample])
    }
}
#endif
