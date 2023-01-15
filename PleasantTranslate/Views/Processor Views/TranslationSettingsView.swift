//
//  TranslationProcessorView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 15.05.21.
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

struct TranslationSettingsView: View {
    var body: some View {
        VStack(spacing: 5) {
            Text("Service: \(processor.translationServiceName)")
            Button("API Key") {
                showApiKeyManager.toggle()
            }
            .popover(isPresented: $showApiKeyManager) {
                if let transaltionService = processor.document?.translationService {
                    let vm = ApiKeyManagementViewModel(with: transaltionService)
                    ApiKeyManagementView(viewModel: vm)
                }
            }
            Text("Glossary contains \(processor.glossary.count) translations")
            if let progress = processor.progress {
                ProgressView(progress)
            }
            if let time = processor.processingTime {
                VStack(spacing: 0) {
                    Text("Translation finished after")
                    Text(time)
                }
            }
            if processor.processorState.didProcess {
                Text("\(processor.translatedCharacterCount) characters translated with \(processor.translationServiceName), \(processor.toTranslateCharacterCount-processor.translatedCharacterCount) translated with glossary")
            }
        }
        .multilineTextAlignment(.leading)
    }
    
    @ObservedObject var processor: TranslationProcessor
    @State private var showApiKeyManager: Bool = false
}

#if DEBUG
struct TranslationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationSettingsView(processor: .sample)
    }
}
#endif
