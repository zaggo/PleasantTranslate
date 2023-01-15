//
//  DocumentView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 02.01.23.
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

struct DocumentView: View {
    var body: some View {
        NavigationSplitView {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ProjectSettingsView(document: document)
                        ForEach(document.processors) { processor in
                            VStack {
                                DataflowIndicator(processor: processor)
                                let isSelected = processor == document.selectedProcessor
                                let backgroundColor = isSelected ? Color(.unemphasizedSelectedContentBackgroundColor) : Color(.alternatingContentBackgroundColors[1])
                                processor.settingsView
                                    .frame(maxWidth: .infinity)
                                    .background(backgroundColor)
                                    .cornerRadius(5)
                                    .padding(5)
                                    .onTapGesture {
                                        withAnimation {
                                            document.selectedProcessorId = .processorId(processor.id)
                                            document.autoexpand(processor)
                                        }
                                    }
                            }
                        }
                    }
                }
                .onChange(of: document.selectedProcessorId) { newValue in
                    guard case .processorId(let id) = newValue else { return }
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        withAnimation {
                            scrollViewProxy.scrollTo(id)
                        }
                    }
                }
            }
            .frame(minWidth: 250, idealWidth: 250)
        } detail: {
            Group {
                if let selectedProcessor = document.selectedProcessor {
                    if selectedProcessor.alternativeResultsTitle == nil
                        || selectedOutput == .primary {
                        selectedProcessor.resultsView
                    } else {
                        selectedProcessor.alternativeResultsView
                    }
                } else {
                    Text("Select a processor in the sidebar")
                }
            }
            .toolbar {
                if let selectedProcessor = document.selectedProcessor,
                   let alternativeTitle = selectedProcessor.alternativeResultsTitle {
                    ToolbarItem(placement: .principal) {
                        Picker(selection: $selectedOutput) {
                            Text("Result").tag(ProcessorOutput.primary)
                            Text(alternativeTitle).tag(ProcessorOutput.alternative)
                        } label: {
                            Text("Processor Output")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
        }
    }
    
    @State private var selectedOutput: ProcessorOutput = .primary
    @ObservedObject var document: PleasantTranslateDocument
    
    enum ProcessorOutput: Hashable {
        case primary
        case alternative
    }
}

#if DEBUG
struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentView(document: .sample)
    }
}
#endif
