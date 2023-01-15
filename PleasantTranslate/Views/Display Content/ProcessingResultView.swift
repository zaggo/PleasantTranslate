//
//  ProcessingResultView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 08.01.23.
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

struct ProcessingResultView<Content: View, T>: View {
    init(processor: Processor, @ViewBuilder content: @escaping (T) -> Content) {
        self.content = content
        self.processor = processor
    }

    var body: some View {
        switch processor.processorState {
        case .error(let error):
            ErrorView(text: error.localizedDescription)
        case .waitingForInput, .readyToProcess:
            VStack {
                Text(processor.noResultString)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Button(processor.actionName) {
                    processor.defaultAction()
                }
            }

        case .processing:
            VStack {
                Text("Processing…")
                    .font(.headline)
                    .foregroundColor(.secondary)
                ProgressView()
                    .controlSize(.large)
            }
        case .processed:
            if case .success(let processed) = processor.cachedResult?.processingResult {
                if let result = processed as? T {
                    content(result)
                } else {
                    ErrorView(text: "Processor result are in the wrong format")
                }
            } else {
                ErrorView(text: "Processor doesn't provide result")
            }
        }
    }
    
    @ObservedObject var processor: Processor
    let content: (T) -> Content
}

#if DEBUG
struct ProcessingResultView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingResultView(processor: ImportProcessor.sample) { (content: String) in
            Text(content)
        }
    }
}
#endif
