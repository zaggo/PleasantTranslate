//
//  SentencesView.swift
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

struct SentencesView: View {
    var sentences: [Sentence]
    var subtitles: [Subtitle]

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(sentences) { sentence in
                    VStack {
                        SentenceView(sentence: sentence, subtitles: subtitles)
                        Divider()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct SentencesView_Previews: PreviewProvider {
    static var previews: some View {
        SentencesView(sentences: [.sample, .sample],
                      subtitles: [.sample, .sample])
    }
}
#endif
