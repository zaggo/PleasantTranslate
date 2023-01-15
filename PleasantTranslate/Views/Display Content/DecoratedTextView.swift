//
//  DecoratedTextView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 05.01.23.
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

struct DecoratedTextView: View {
    init(text: String,
         lineOffset: Int = 0,
         issue: ParserProcessor.Issue? = nil) {
        self.text = text
        self.lineOffset = lineOffset
        self.issue = issue
    }
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            let lines = text.components(separatedBy: CharacterSet.newlines)
            let maxDigits = "\(lines.count + lineOffset)".count
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                let isIssueLine = isIssueLine(index)
                HStack(alignment: .top, spacing: 10) {
                    Text(String(format: "%\(maxDigits)d", index+1+lineOffset))
                        .font(.body.monospaced())
                        .lineLimit(1)
                        .padding([.leading, .trailing], 3)
                        .foregroundColor(isIssueLine ? .white : Color(.tertiaryLabelColor))
                        .background(isIssueLine ? .red : .clear)
                    Text(line)
                        .font(.headline)
                    if let issue, isFirstIssueLine(index) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Image(systemSymbol: .arrowtriangleLeftFill)
                                .imageScale(.small)
                            Text(issue.reason.description)
                        }.padding([.leading, .trailing], 5)
                            .foregroundColor(.white)
                            .background(.red)
                    }
                }
            }
        }
    }
    
    private func isIssueLine(_ index: Int) -> Bool {
        issue?.lineRange.contains(index+lineOffset) ?? false
    }
    
    private func isFirstIssueLine(_ index: Int) -> Bool {
        issue?.lineRange.first == index+lineOffset
    }
    
    let text: String
    let lineOffset: Int
    let issue: ParserProcessor.Issue?
}

#if DEBUG
struct NumberedTextView_Previews: PreviewProvider {
    static var previews: some View {
        let text =
        """
        Es ist gut, dass die Leben
        in mehreren Kreisen verlaufen.

        Unexpected
        2
        00:03:06,080 --> 00:03:11,560
        Aber mein Leben ist nur einmal herumgelaufen,
        und nicht einmal ganz.
        """
        
        DecoratedTextView(text: text,
                         lineOffset: 2,
                         issue: .sample)
    }
}
#endif
