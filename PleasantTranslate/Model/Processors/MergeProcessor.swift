//
//  MergeProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 27.05.21.
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

import Foundation
import SwiftUI
import Combine

class MergeProcessor: Processor, OptionalProcessor {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        super.init(inputProvider: inputProvider, document: document)
        isEnabled = false
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isEnabled = try container.decode(.isEnabled)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
    }

    // MARK: - UI
    override var processorName: String { NSLocalizedString("Merge", comment: "") }
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                MergeSettingsView(processor: self)
            }
        )
    }
    
    override var resultsView: AnyView {
        AnyView(
            ProcessingResultView(
                processor: self,
                content: { (content: [Subtitle]) in
                    SubtitlesView(subtitles: content)
                })
        )
    }

    // MARK: - API
    @MainActor
    override func resetProcessor() {
        super.resetProcessor()
        processedSubtitlesCount = 0
    }

    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let translatedSubtitles = input as? [Subtitle] else {
            return .failure(ProcessorError.wrongInputFormat)
        }
        
        guard isEnabled else {
            return .success(translatedSubtitles)
        }
                
        guard let versionedProcessingResults = inputProvider?.processedOutput(from: PurgeCCProcessor.id),
              case .success(let result) = versionedProcessingResults.processingResult,
              let originalSubtitles = result as? [Subtitle] else {
            return .failure(ProcessorError.wrongInputFormat)
        }

        var processedSubtitles: [Subtitle] = []
        for (translated, original) in zip(translatedSubtitles, originalSubtitles) {
            let merged = translated.copyByReplacing(lines: translated.lines + original.lines)
            processedSubtitles.append(merged)
        }
        
        await setProcessedSubtitlesCount(processedSubtitles.count)

        return .success(processedSubtitles)
    }

    @MainActor
    private func setProcessedSubtitlesCount(_ count: Int) {
        self.processedSubtitlesCount = count
    }
    
    // MARK: - Publishers
    @Published var processedSubtitlesCount: Int = 0
    
    // MARK: - Constants
    private enum CodingKeys: CodingKey {
        case isEnabled
    }
}
