//
//  PleasantTranslateDocument.swift
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
import UniformTypeIdentifiers
import os
import Combine

class PleasantTranslateDocument: FileDocument, ObservableObject {
    // MARK: - Initialization
    required init() {
        self.sourceLanguage = sourceLanguageHandlers
            .first(where: { $0.twoLetterCode == Self.lastSourceLanguage }) ?? EnglishSourceLanguageHandler.self
        self.targetLanguage = targetLanguageHandlers
            .first(where: { $0.twoLetterCode == Self.lastTargetLanguage }) ?? JapaneseTargetLanguageHandler.self
        self.translationService = translators
            .first(where: { $0.identifier == Self.lastTranslationService }) ?? DeeplTranslator.self

        selectedProcessorId = .none
        
        var previousProcessor: Processor?
        var processors = [Processor]()
        for processorType in availableProcessors {
            let processor = processorType.init(inputProvider: previousProcessor, document: self)
            previousProcessor = processor
            processors.append(processor)
        }
        self.processors = processors
        addBindings()
        logger.info("Document initialized with \(self.processors.count) processors")
    }
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        let dto = try decoder.decode(PleasantTranslateDocumentDTO.self, from: data)
        
        self.sourceLanguage = sourceLanguageHandlers
            .first(where: { $0.twoLetterCode == dto.sourceLanguage }) ?? EnglishSourceLanguageHandler.self
        self.targetLanguage = targetLanguageHandlers
            .first(where: { $0.twoLetterCode == dto.targetLanguage }) ?? JapaneseTargetLanguageHandler.self
        self.translationService = translators
            .first(where: { $0.identifier == dto.translationService }) ?? DeeplTranslator.self
                
        selectedProcessorId = .none
        
        var previousProcessor: Processor?
        var processors = [Processor]()
        for processorType in availableProcessors {
            if let data = dto.processorSettings[processorType.id],
               let processor = try? decoder.decode(processorType, from: data) {
                processor.initalSetup(inputProvider: previousProcessor, document: self)
                previousProcessor = processor
                processors.append(processor)
            } else {
                let processor = processorType.init(inputProvider: previousProcessor, document: self)
                previousProcessor = processor
                processors.append(processor)
            }
        }
        self.processors = processors
        addBindings()
        logger.info("Document loaded with \(self.processors.count) processors")
    }
    
    private func addBindings() {
        $selectedProcessorId
            .map { [weak self] selectedProcessorId in
                switch selectedProcessorId {
                case .none:
                    return nil
                case .processorId(let id):
                    return self?.processors.first(where: { $0.id == id })
                }
            }
            .assign(to: &$selectedProcessor)
    }
    
    // MARK: - Lifecycle
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let dto = PleasantTranslateDocumentDTO(from: self)
        let data = try JSONEncoder().encode(dto)
        return .init(regularFileWithContents: data)
    }
    
    // MARK: - API
    func sourceLanguageHandler(for twoLetterCode: LanguageTwoLetterCode) -> (any SourceLanguageHandler.Type)? {
        return sourceLanguageHandlers.first(where: { $0.twoLetterCode == twoLetterCode })
    }
    
    var sourceLanguageHandler: any SourceLanguageHandler { sourceLanguage.init() }
    var targetLanguageHandler: any TargetLanguageHandler { targetLanguage.init() }

    var currentSourceUrl: URL? {
        guard let importProcessor = processors.first(where: { $0 is ImportProcessor }) as? ImportProcessor else { return nil }
        return importProcessor.sourceFileUrl
    }
    
    // MARK: - ViewModel
    lazy var availableSourceLanguages: [DisplayableOption] = {
        sourceLanguageHandlers.map({ DisplayableOption(displayName: $0.displayName,
                                                       id: $0.twoLetterCode,
                                                       payload: $0)  })
    }()

    lazy var availableTargetLanguages: [DisplayableOption] = {
        targetLanguageHandlers.map({ DisplayableOption(displayName: $0.displayName,
                                                       id: $0.twoLetterCode,
                                                       payload: $0)  })
    }()

    lazy var availableTranslators: [DisplayableOption] = {
        translators.map({ DisplayableOption(displayName: $0.displayName,
                                            id: $0.identifier,
                                            payload: $0)  })
    }()

    // MARK: - Publishers
    @Published var sourceLanguage: any SourceLanguageHandler.Type {
        didSet { Self.lastSourceLanguage = sourceLanguage.twoLetterCode }
    }
    @Published var targetLanguage: any TargetLanguageHandler.Type {
        didSet { Self.lastTargetLanguage = targetLanguage.twoLetterCode }
    }
    @Published var translationService: any Translator.Type {
        didSet { Self.lastTranslationService = translationService.identifier }
    }
    
    @Published var selectedProcessorId: ProcessorSelection
    @Published var selectedProcessor: Processor?

    // MARK: - UserDefaults
    @LocalUserDefault(key: "lastSourceLanguage", defaultValue: EnglishSourceLanguageHandler.twoLetterCode)
    private static var lastSourceLanguage: LanguageTwoLetterCode
    
    @LocalUserDefault(key: "lastTargetLanguage", defaultValue: JapaneseTargetLanguageHandler.twoLetterCode)
    private static var lastTargetLanguage: LanguageTwoLetterCode
    
    @LocalUserDefault(key: "lastTranslationService", defaultValue: DeeplTranslator.identifier)
    private static var lastTranslationService: TranslatorIdentifier
    
    // MARK: - iVars
    private(set) var processors: [Processor] = []

    // MARK: - Constants
    static var readableContentTypes: [UTType] { [.subtitleProject] }
    
    private let availableProcessors: [Processor.Type] = [
        ImportProcessor.self,
        ParserProcessor.self,
        PurgeCCProcessor.self,
        PrewashProcessor.self,
        ParseSentencesProcessor.self,
        TranslationProcessor.self,
        SplitTranslationsProcessor.self,
        MergeProcessor.self,
        TimeshiftProcessor.self,
        ExportProcessor.self
    ]

    private let translators: [any Translator.Type] = [
        GoogleTranslator.self,
        DeeplTranslator.self,
    ]
    
    private let sourceLanguageHandlers: [any SourceLanguageHandler.Type] = [
        EnglishSourceLanguageHandler.self,
        GermanSourceLanguageHandler.self,
        FrenchSourceLanguageHandler.self,
        SwedishSourceLanguageHandler.self,
        DutchSourceLanguageHandler.self,
    ]

    private let targetLanguageHandlers: [any TargetLanguageHandler.Type] = [
        JapaneseTargetLanguageHandler.self,
        EnglishTargetLanguageHandler.self,
        GermanTargetLanguageHandler.self,
    ]
    
    enum ProcessorSelection: Equatable {
        case none
        case processorId(ProcessorId)
    }

    lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: Self.self))
}
