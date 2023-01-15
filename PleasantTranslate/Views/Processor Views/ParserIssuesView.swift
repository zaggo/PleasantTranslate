//
//  ParserIssuesView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 12.05.21.
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

struct ParserIssuesView: View {
    var body: some View {
        if processor.issues.isEmpty {
            Text("No Issues")
                .font(.headline)
                .foregroundColor(.secondary)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(processor.issues) { issue in
                        Group {
                            if let sourceText = issue.sourceText,
                               let offset = issue.lineRange.first {
                                DecoratedTextView(text: sourceText,
                                                  lineOffset: offset - 5,
                                                  issue: issue)
                            } else {
                                Text(issue.description)
                            }
                        }
                        .padding(.bottom)
                    }
                }
                .padding()
            }
        }
    }
    
    @ObservedObject var processor: ParserProcessor
}

#if DEBUG
struct ParserIssuesView_Previews: PreviewProvider {
    static var previews: some View {
        ParserIssuesView(processor: .sample)
    }
}
#endif
