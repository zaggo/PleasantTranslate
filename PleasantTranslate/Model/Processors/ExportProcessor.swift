//
//  ExportProcessor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 13.05.21.
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

class ExportProcessor: Processor {
    
    // MARK: - Initialization
    override func addBindings() {
        super.addBindings()
        inputProvider?.$cachedResult
            .map({
                if $0 == nil {
                   return NSLocalizedString("Process", comment: "")
                } else {
                    return NSLocalizedString("Export", comment: "")
                }
            })
            .assign(to: &$actionName)
    }
    
    // MARK: - UI
    override var processorName: String { NSLocalizedString("Export", comment: "") }
    override class var defaultActionName: String { NSLocalizedString("Export", comment: "") }

    override func defaultAction() {
        Task {
            if inputProvider?.cachedResult == nil {
                await self.process()
            } else {
                await exportFile()
            }
        }
    }

    override var settingsView: AnyView {
        AnyView(
            ProcessingStepView(processor: self) {
               ExportSettingsView(processor: self)
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
    
    // MARK: - Processor
    @MainActor
    override func resetProcessor() {
        super.resetProcessor()
        self.writtenState = nil
    }

    // MARK: - Processor
    override func process(input: Any?) async -> Result<Any, Error> {
        guard let inSubtitles = input as? [Subtitle] else {
            return .failure(ProcessorError.wrongInputFormat)
        }
                        
        let renumberedSubtitles = inSubtitles.enumerated()
            .map { (index, subtitle) in
                var renumbered = subtitle
                renumbered.id = "\(index+1)"
                return renumbered
            }
                        
        let output: String = renumberedSubtitles.map({ $0.description }).joined(separator: "\n\n")
        
        await MainActor.run {
            characterCount = output.count
        }
        
        return .success(output)
    }

    // MARK: - Service
    @MainActor
    private func exportFile() {
        guard let targetUrl = proposedTargetUrl else { return }
        NSOpenPanel.chooseOutputDir(url: targetUrl) { (result) in
            if case let .success(url) = result {
                Task {
                    await MainActor.run {  self.targetUrl = url }
                    await self.process()
                    self.writeResults()
                }
            }
        }
    }

    private func writeResults() {
        if let processResult = cachedResult?.processingResult {
            switch processResult {
            case .success(let result):
                guard let string = result as? String else {
                    Task { await MainActor.run { writtenState = .failure(SaveSrtProcessor.invalidOutputFormat) } }
                    writtenState = .failure(SaveSrtProcessor.invalidOutputFormat)
                    logger.error("Result is no String")
                    return
                }
                guard let saveUrl = targetUrl else {
                    Task { await MainActor.run { writtenState = .failure(SaveSrtProcessor.noOutputUrl) } }
                    
                    logger.error("No SaveUrl")
                    return
                }
                do {
                    try string.write(to: saveUrl, atomically: false, encoding: .utf8)
                    logger.debug("Did Save to \(saveUrl)")
                    Task { await MainActor.run { writtenState = .success(()) } }
                } catch {
                    logger.error("Error: \(error)")
                    Task { await MainActor.run { writtenState = .failure(error) } }
                }
            case .failure(let error):
                logger.error("Error: \(error)")
                Task { await MainActor.run { writtenState = .failure(error) } }
                
            }
        } else {
            logger.error("Not Processed Yet")
        }
    }
    
    private var proposedTargetUrl: URL? {
        guard let document,
              var url = document.currentSourceUrl else {
            Task.detached {
                await self.process()
            }
            return nil
        }
        let pathExtension = url.pathExtension
        url.deletePathExtension()
        if url.pathExtension == document.sourceLanguage.twoLetterCode {
            url.deletePathExtension()
        }
        return url.appendingPathExtension(document.targetLanguage.twoLetterCode)
            .appendingPathExtension(pathExtension)
    }
    
    // MARK: - Publishers
    @Published var targetUrl: URL? = nil
    @Published var writtenState: Result<Void, Error>? = nil
    @Published var characterCount: Int = 0

    // MARK: - iVars
    private var bindings: [AnyCancellable] = []
    
    // MARK: - Constants
    enum SaveSrtProcessor: Error {
        case invalidOutputFormat
        case noOutputUrl
    }
}
