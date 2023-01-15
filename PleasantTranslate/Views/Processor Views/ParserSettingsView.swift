//
//  ParserSettingsView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 09.05.21.
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

struct ParserSettingsView: View {
    var body: some View {
        VStack {
            Text("Number of Subtitles: \(processor.numberOfSubtitles)")
            HStack {
                Text("Issues: \(processor.issues.count)")
//                if !processor.issues.isEmpty {
//                    Button("Show issues", action: { showIssueSheet = true })
//                        .popover(isPresented: $showIssueSheet) {
//                            ParserIssuesView(issues: processor.issues)
//                                .background(Color(NSColor.windowBackgroundColor))
//                        }
//                }
            }
            VStack(alignment: .leading) {
                HStack {
                    Picker(
                        selection: $processor.numberOfDropFromBeginningSubtitles) {
                            ForEach(0..<11) { i in
                                Text("\(i)").tag(i)
                            }
                        } label: {
                            Text("Drop")
                        }
                        .fixedSize()

                    Text("Subtitles from Beginning")
                }
                HStack {
                    Picker("Drop", selection: $processor.numberOfDropFromEndSubtitles, content: {
                        ForEach(0..<11) { i in
                            Text("\(i)").tag(i)
                        }
                    })
                    .fixedSize()
                    Text("Subtitles from End")
                }
            }
            .controlSize(.small)
            .font(.subheadline)
        }
    }
    
    @ObservedObject var processor: ParserProcessor
}

#if DEBUG
struct SrtParserProcessorView_Previews: PreviewProvider {
    static var previews: some View {
        ParserSettingsView(processor: .sample)
    }
}
#endif
