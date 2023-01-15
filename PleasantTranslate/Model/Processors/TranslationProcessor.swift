//
//  TranslationProcessor.swift
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
//import AnyCodable
import Combine
import NaturalLanguage

class TranslationProcessor: Processor {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        translationServiceName = document.translationService.displayName
        super.init(inputProvider: inputProvider, document: document)
    }
    
    required init(from decoder: Decoder) throws {
        translationServiceName = "Decoded"
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        glossarySource = try container.decode(.glossarySource)
        glossaryTarget = try container.decode(.glossaryTarget)
        glossary = try container.decode(.glossary)
    }
    
    override func initalSetup(inputProvider: Processor?, document: PleasantTranslateDocument) {
        super.initalSetup(inputProvider: inputProvider, document: document)
        translationServiceName = document.translationService.displayName
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(glossarySource, forKey: .glossarySource)
        try container.encode(glossaryTarget, forKey: .glossaryTarget)
        try container.encode(glossary, forKey: .glossary)
    }
    
    override func addBindings() {
        super.addBindings()
        
        document?.$translationService
            .map({ $0.displayName })
            .assign(to: &$translationServiceName)
                
        document?.$translationService
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                Task { await self.resetProcessor() }
            })
            .store(in: &bindings)

        document?.$targetLanguage
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                Task { await self.resetProcessor() }
            })
            .store(in: &bindings)
    }
    
    // MARK: - UI
    override var processorName: String { NSLocalizedString("Translate", comment: "") }
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                TranslationSettingsView(processor: self)
            }
        )
    }
    
    override var resultsView: AnyView {
        AnyView(
            ProcessingResultView(
                processor: self,
                content: { (content: ([Sentence], [Sentence])) in
                    ScrollView {
                        LazyVStack {
                            ForEach(Array(zip(content.0, content.1)), id: \.0.id) { translation in
                                VStack {
                                    TranslationView(original: translation.1, translation: translation.0)
                                    Divider()
                                }
                            }
                        }
                    }
                }
            )
        )
    }
    
    @MainActor
    override func resetProcessor() {
        super.resetProcessor()
        translatedCharacterCount = 0
        self.processingTime = nil
    }
    
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let originalSentences = input as? [Sentence] else {
            return .failure(ProcessorError.wrongInputFormat)
        }
        
        guard let document else {
            return .failure(ProcessorError.noDocument)
        }
        
        do {
            let progress = Progress(totalUnitCount: Int64(originalSentences.count))

            guard let apiKeyRecord = ApiKeyStorage.shared.selectedApiKey(for: document.translationService.identifier),
                  let apiKey = apiKeyRecord.apiKey else {
                throw ProcessorError.noApiKey
            }

            let translator = try document.translationService.init(apiKey: apiKey,
                                                                  sourceLanguage: document.sourceLanguage.twoLetterCode,
                                                                  targetLanguage: document.targetLanguage.twoLetterCode,
                                                                  glossary: glossary,
                                                                  progress: progress)

            await MainActor.run {
                self.originalSentences = originalSentences
            }
            
            if glossarySource != document.sourceLanguage.twoLetterCode
                || glossaryTarget != document.targetLanguage.twoLetterCode {
                await MainActor.run {
                    glossary = [:]
                    glossarySource = document.sourceLanguage.twoLetterCode
                    glossaryTarget = document.targetLanguage.twoLetterCode
                }
            }
            
            let startTranslationAt = Date()
            
            await MainActor.run {
                self.progress = progress
                self.toTranslateCharacterCount = originalSentences.reduce(0, { $0 + $1.text.count })
            }
                        
            let (translatedSentences, translatedCharacters) = try await translator.translate(sentences: originalSentences)
            
            let endTranslationAt = Date()
            
            let duration = endTranslationAt.timeIntervalSince(startTranslationAt)
            let formattedDuration = durationFormatter.string(from: duration)
            
            await MainActor.run {
                self.glossary = translator.glossary
                self.processingTime = formattedDuration ?? String(format: NSLocalizedString("%1.1lf s", comment: ""), duration)
                self.progress = nil
                self.translatedCharacterCount = translatedCharacters
            }
            return .success((translatedSentences, originalSentences))
        } catch {
            await MainActor.run {
                self.progress = nil
            }
            return .failure(error)
        }
    }
    
    // MARK: - Publishers
    @Published var changedSubtitles: [ChangedSubtitle] = []
    @Published var translationServiceName: String
    @Published var progress: Progress?
    @Published var toTranslateCharacterCount: Int = 0
    @Published var translatedCharacterCount: Int = 0
    @Published var processingTime: String? = nil
    @Published var glossary: [String: String] = [:]

    // MARK: - iVars
    private var glossarySource: String = ""
    private var glossaryTarget: String = ""
    private var originalSentences: [Sentence]?
    private var bindings: [AnyCancellable] = []
    
    // MARK: - Constants
    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [ .hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        return formatter
    }()

    private enum CodingKeys: CodingKey {
        case disabledSubtitleIds
        case glossarySource
        case glossaryTarget
        case glossary
    }
}
