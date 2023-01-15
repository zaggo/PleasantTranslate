//
//  ImportProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 03.01.23.
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
import Combine

class ImportProcessor: Processor {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        super.init(inputProvider: inputProvider, document: document)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceFileUrl = try container.decode(.sourceFileUrl)
        rawSubtitles = try container.decodeIfPresent(.rawSubtitles)
        
        if rawSubtitles != nil {
            Task { await process() }
        }
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sourceFileUrl, forKey: .sourceFileUrl)
        try container.encode(rawSubtitles, forKey: .rawSubtitles)
    }

    // MARK: - UI
    override var processorName: String { NSLocalizedString("Import SRT", comment: "") }
    override class var defaultActionName: String { NSLocalizedString("Import", comment: "") }
    override var noResultString: String { NSLocalizedString("No subtitles imported", comment: "") }

    override func defaultAction() {
        Task{ await selectFile() }
    }
    
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                ImportSettingsView(processor: self)
            }
        )
    }
    
    override var resultsView: AnyView {
        AnyView(
            ProcessingResultView(
                processor: self,
                content: { (content: String) in
                    ScrollView {
                        DecoratedTextView(text: content)
                            .padding()
                    }
                })
        )
    }

    // MARK: - API
    @MainActor
    func resetSourceFileUrl(_ url: URL) {
        let languageKey = url.deletingPathExtension().pathExtension
        if !languageKey.isEmpty,
           let handlerType = document?.sourceLanguageHandler(for: languageKey) {
            document?.sourceLanguage = handlerType
        }
        sourceFileUrl = url
        rawSubtitles = nil
        resetProcessor()
    }

    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let url = sourceFileUrl else {
            await selectFile()
            return .failure(ProcessorError.missingInput)
        }

        var processedString: String
        if let rawSubtitles {
            processedString = rawSubtitles
        } else {
            do {
                processedString = try readSrtFile(from: url)
                await setRawSubtitles(processedString)
            } catch {
                return .failure(error)
            }
        }
        
        if purgeHtml {
            processedString = processedString.replacingOccurrences(of: "<[^>]+>", with: "",
                                                                   options: .regularExpression,
                                                                   range: nil)
        }
        
        if replaceCRNL {
            processedString = processedString.replacingOccurrences(of: "\r\n", with: "\n")
        }
        
        return .success(processedString)
    }

    // MARK: - Service
    @MainActor
    private func selectFile() {
        NSOpenPanel.chooseSrt { (result) in
            guard case let .success(url) = result else { return }
            Task.detached {
                await self.resetSourceFileUrl(url)
                await self.process()
            }
        }
    }

    private func readSrtFile(from url: URL) throws -> String {
        var encoding = String.Encoding(rawValue: 0)
        do {
            let rawString = try String(contentsOf: url, usedEncoding: &encoding)
            guard encoding != .utf8 else { return rawString }
            return try rawString.convertedToUtf8()
        } catch {
            if (error as NSError).domain == "NSCocoaErrorDomain"
                && (error as NSError).code == 264
                && encoding != .windowsCP1252 {
                
                return try String(contentsOf: url, encoding: .windowsCP1252).convertedToUtf8()
            }
            logger.error("\(error)")
            throw error
        }
    }

    @MainActor
    func setRawSubtitles(_ content: String?) {
        rawSubtitles = content
    }
    
    // MARK: - Publishers
    @Published var rawSubtitles: String?
    @Published var sourceFileUrl: URL?
    
    @Published var replaceCRNL: Bool = true {
        didSet { Task{ await resetProcessor() } }
    }
    @Published var purgeHtml: Bool = true {
        didSet { Task{ await resetProcessor() } }
    }

    // MARK: - Constants
    private enum CodingKeys: CodingKey {
        case sourceFileUrl, rawSubtitles
    }
}

extension String {
    var purgeHTMLTags: String {
        self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
