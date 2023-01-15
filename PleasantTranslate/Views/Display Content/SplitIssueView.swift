//
//  SplitIssueView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 23.05.21.
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
import SFSafeSymbols

struct SplitIssueView: View {
    var sentence: Sentence
    var originalSubtitles: [Subtitle]
    var translatedSubtitles: [Subtitle]
    
    var body: some View {
        VStack {
//            let splitInfos = sentence.calculateSplits(subtitles: originalSubtitles)
//            ForEach(splitInfos) { splitInfo in
//                
//                HStack {
//                    Text(splitInfo.line)
//                    Text("\(splitInfo.percentageString) (\(splitInfo.line.count) characters)")
//                        .foregroundColor(.secondary)
//                }
//            }
//            Spacer()
//                .frame(height: 10)
//            if splitInfos.count == 1 {
//                Text(sentence.textForSplitting)
//                    .bold()
//                    .foregroundColor(Color(Sentence.lineSplitColors[0]))
//            } else {
//                Text(sentence.attributedString(for: splitInfos))
//                    .bold()
//            }
//
//            Spacer()
//                .frame(height: 10)

            VStack(spacing: 10) {
                let resultingSubtitleEntries = Set<Int>(sentence.sources.map({ $0.subtitleIndex }))
                ForEach(resultingSubtitleEntries.sorted(), id:\.self) { index in
                    HStack {
                        Spacer()
                        SubtitleView(subtitle: originalSubtitles[index])
                        Image(systemSymbol: .arrowRight)
                        SubtitleView(subtitle: translatedSubtitles[index])
                        Spacer()
                    }
                    .fixedSize()
                }
            }
        }
    }
}

#if DEBUG
struct SplitIssueView_Previews: PreviewProvider {
    static var previews: some View {
        SplitIssueView(sentence: .sample,
                       originalSubtitles: [.sample],
                       translatedSubtitles: [.sample])
    }
}
#endif
