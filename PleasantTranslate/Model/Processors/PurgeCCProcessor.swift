//
//  PurgeCCProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 10.05.21.
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

class PurgeCCProcessor: Processor, DisabledSubtitleIdsProvider, OptionalProcessor {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        super.init(inputProvider: inputProvider, document: document)
        enabledCCSubstitutionIds = AvailableCCPatterns.shared.substitutions.map({ $0.id })
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabledCCSubstitutionIds = try container.decode(.enabledCCSubstitutionIds)
        isEnabled = try container.decode(.isEnabled)
        disabledSubtitleIds = try container.decode(.disabledSubtitleIds)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabledCCSubstitutionIds, forKey: .enabledCCSubstitutionIds)
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
    }

    // MARK: - UI
    override var processorName: String { NSLocalizedString("Purge CC", comment: "") }
    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
                PurgeCCSettingsView(processor: self)
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
        AnyView(PurgeCCChangesView(processor: self))
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
                
        let enabledSubstitutions = AvailableCCPatterns
            .shared
            .substitutions
            .filter({ enabledCCSubstitutionIds.contains($0.id) })
        
        let (processedSubtitles, changeHistory) = purge(subtitles: originalSubtitles,
              substitutions: enabledSubstitutions,
              disabledSubtitleIds: disabledSubtitleIds)

        await setChangedSubtitles(changeHistory)
        
        return .success(processedSubtitles)
    }
    
    // Could/Should be private, but then we cannot use it for UnitTests…
    func purge(subtitles: [Subtitle],
               substitutions: [CCPattern],
               disabledSubtitleIds: Set<SubtitleId>) -> ([Subtitle], [ChangedSubtitle]) {
        
        var changeHistory: [ChangedSubtitle] = []
        let processedSubtitles = subtitles
            .compactMap {
                let processedLines = $0.lines
                    .map { substitutions.processLine($0) } // Process the substitutions
                    .compactMap({ $0.isEmpty ? nil : $0 }) // Remove empty lines
                
                let processedSubtitle = Subtitle(id: $0.id, timecode: $0.timecode, lines: processedLines)
                
                if processedLines != $0.lines { // Remember all actual changes
                    changeHistory.append(ChangedSubtitle(original: $0, processed: processedSubtitle))
                }
                
                guard !disabledSubtitleIds.contains($0.id) else { // Ignore subtitles which are disabled for changes
                    return $0
                }
                
                // Remove empty subtitles
                return processedLines.isEmpty ? nil : processedSubtitle
            }
        return (processedSubtitles, changeHistory)
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
    @Published var enabledCCSubstitutionIds: [CCPatternId] = [] {
        didSet { Task{ await resetProcessor() } }
    }
    
    // MARK: - Constants
    private enum CodingKeys: CodingKey {
        case enabledCCSubstitutionIds
        case isEnabled
        case disabledSubtitleIds
    }
}
