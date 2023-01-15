//
//  ProcessingStepView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 08.05.21.
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

struct ProcessingStepView<Content: View>: View {
    init(processor: Processor, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.processor = processor
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $processor.isUIExpanded,
            content: {
                content
                    .padding(.top, 10)
                    .padding(.bottom)
            }, label: {
                VStack {
                    HStack {
                        if processor is OptionalProcessor {
                            Toggle(processor.processorName, isOn: $processor.isEnabled)
                        } else {
                            Text(processor.processorName)
                        }
                        Spacer()
                        switch processor.processorState {
                        case .error:
                            Image(systemSymbol: .exclamationmarkTriangle)
                                .foregroundColor(Color(.systemRed))
                        case .waitingForInput, .readyToProcess: EmptyView()
                        case .processing: ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 2)
                        case .processed:
                            Image(systemSymbol: .checkmarkCircleFill)
                                .foregroundColor(Color(.systemGreen))
                        }
                        Button(processor.actionName) {
                            processor.defaultAction()
                        }
                        .disabled((processor is OptionalProcessor) && !processor.isEnabled)
                    }
                    .font(.subheadline)
                }
            })
        .padding([.leading, .trailing])
    }
    
    // MARK: - iVars
    @ObservedObject var processor: Processor
    let content: Content
}

#if DEBUG
struct ProcessingStepView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingStepView(processor: ImportProcessor.sample) {
            Text("Hier")
            // ImportSettingsView(processor: .sample)
        }
        .frame(width: 300)
    }
}
#endif
