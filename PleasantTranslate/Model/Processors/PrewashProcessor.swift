//
//  PrewashProcessor.swift
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

class PrewashProcessor: Processor, DisabledSubtitleIdsProvider, OptionalProcessor {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        super.init(inputProvider: inputProvider, document: document)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(.isEnabled)
        disabledSubtitleIds = try container.decode(.disabledSubtitleIds)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(disabledSubtitleIds, forKey: .disabledSubtitleIds)
    }

    override func addBindings() {
        super.addBindings()
                
        Publishers.CombineLatest3($changedSubtitles, $disabledSubtitleIds, $processorState)
            .map({
                guard $2.didProcess else { return "-" }
                let changedCount = Swift.max(0, $0.count - $1.count)
                if changedCount < $0.count {
                    return String(format: NSLocalizedString("%d (%d ignored)", comment: ""), changedCount, $1.count)
                }
                return "\(changedCount)"
            })
            .assign(to: &$changeCountString)

        document?.$targetLanguage
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                Task { await self.resetProcessor() }
            })
            .store(in: &bindings)
    }

   // MARK: - UI
    override var processorName: String { NSLocalizedString("Prewash", comment: "") }
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                PrewashSettingsView(processor: self)
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

    override var alternativeResultsView: AnyView {
        AnyView(PrewashChangesView(processor: self))
    }

    override var alternativeResultsTitle: String? { NSLocalizedString("Changes", comment: "") }

    // MARK: - API
    @MainActor
    override func resetProcessor() {
        super.resetProcessor()
        changedSubtitles.removeAll()
    }

    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let originalSubtitles = input as? [Subtitle] else {
            return .failure(ProcessorError.wrongInputFormat)
        }
        
        guard isEnabled else {
            return .success(originalSubtitles)
        }
        
        guard let document else {
            return .failure(ProcessorError.noDocument)
        }
        
        let (processedSubtitles, changedIndexes) = document.sourceLanguageHandler.prewash(subtitles: originalSubtitles, disabledSubtitleIds: disabledSubtitleIds)
        
        await setChangedSubtitles(changedIndexes.map({ ChangedSubtitle(original: originalSubtitles[$0], processed: processedSubtitles[$0]) }))

        // Remove empty subtitles
        let outSubtitles = processedSubtitles.compactMap({ $0.lines.isEmpty ? nil : $0 })

        return .success(outSubtitles)
    }
    
    // MARK: - Service
    @MainActor
    private func setChangedSubtitles(_ newValue: [ChangedSubtitle]) {
        self.changedSubtitles = newValue
    }

    // MARK: - Publishers
    @Published var changedSubtitles: [ChangedSubtitle] = []
    @Published var disabledSubtitleIds: Set<SubtitleId> = []
    @Published var changeCountString: String = "-"
    
    // MARK: - iVars
    private var bindings: [AnyCancellable] = []

    // MARK: - Constants
    private enum CodingKeys: CodingKey {
        case isEnabled
        case disabledSubtitleIds
    }
}
