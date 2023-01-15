//
//  Processor.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 09.05.21.
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
import os

typealias ProcessorId = String
class Processor: ObservableObject, Codable, Identifiable {
    // MARK: - Initialization
    required init(inputProvider: Processor?, document: PleasantTranslateDocument) {
        self.inputProvider = inputProvider
        self.document = document
        self.actionName = Self.defaultActionName
        addBindings()
        addBindings(for: inputProvider)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isUIExpanded = try container.decode(.isUIExpanded)
        self.actionName = Self.defaultActionName
        addBindings()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isUIExpanded, forKey: .isUIExpanded)
    }
    
    func addBindings() {
        // Update `processState` according to `cachedResult` changes
        Publishers.CombineLatest($cachedResult, $isProcessing)
            .map({ cachedResult, isProcessing in
                guard !isProcessing else { return .processing }
                if let cachedResult {
                    switch cachedResult.processingResult {
                    case .failure(let error):
                        return .error(error)
                    case .success:
                        return .processed
                    }
                } else {
                    if case .success = self.inputProvider?.cachedResult?.processingResult {
                        return .readyToProcess
                    } else {
                        return .waitingForInput
                    }
                }
            })
            .assign(to:&$processorState)
    }
    
    // MARK: - API
    func initalSetup(inputProvider: Processor?, document: PleasantTranslateDocument) {
        self.document = document
        self.inputProvider = inputProvider
    }
    
    func defaultAction() {
        Task.detached {
            await self.process()
        }
    }

    @discardableResult
    func process() async -> VersionedProcessingResult? {
        await process(ifOutdated: nil)
    }
    
    func processedOutput(from processorId: String) -> VersionedProcessingResult? {
        guard id != processorId else {
            return cachedResult
        }
        
        guard let inputProvider else {
            return nil
        }
        
        return inputProvider.processedOutput(from: processorId)
    }
    
    @MainActor
    func resetProcessor() {
        self.cachedResult = nil
    }
    
    // MARK: - Service
    private func addBindings(for inputProvider: Processor?) {
        inputProviderBindings.removeAll()
        
        guard let inputProvider else { return }
        
        Publishers.CombineLatest(inputProvider.$cachedResult, $lastInputVersion)
            .map({
                guard let lastResult = $0,
                      let lastVersion = $1,
                      lastResult.version == lastVersion else { return true }
                return false
            })
            .sink { [weak self] (needsUpdate: Bool) in
                guard needsUpdate, let self, self.cachedResult != nil else { return }
                Task {
                    await self.resetProcessor()
                }
            }
            .store(in: &inputProviderBindings)
    }

    @discardableResult
    private func process(ifOutdated version: Int?) async -> VersionedProcessingResult {
        
        // Check if we can reuse the last processed result
        if let cachedResult, version == cachedResult.version {
            logger.debug("Recycle result: \(self)")
            return cachedResult
        }
        
        // Check if we have an inputProvider
        guard let inputProvider else {
            return await process(nil)
        }
        
        // Get input from inputProvider
        let result = await inputProvider.process(ifOutdated: lastInputVersion)
        await setLastInputVersion(result.version)
        
        switch result.processingResult {
        case .failure(let error):
            return await publish(processingResult: .failure(error))
        case .success(let input):
            return await process(input)
        }
    }

    private func process(_ input: Any?) async -> VersionedProcessingResult {
        await resetProcessor()
        
        guard await startProcessing() else {
            return await publish(processingResult: .failure(ProcessorError.notReady))
        }
        
        let result =  await publish(processingResult: process(input: input))
        
        await stopProcessing()
        
        return result
    }

    @MainActor
    private func publish(processingResult: Result<Any, Error>) -> VersionedProcessingResult {
        let versionedProcessResult = VersionedProcessingResult(processingResult: processingResult,
                                                               following: self.cachedResult)
        self.cachedResult = versionedProcessResult
        logger.debug("Did process: \(self)")
        return versionedProcessResult
    }
    
    @MainActor
    private func setLastInputVersion(_ version: Int) {
        self.lastInputVersion = version
    }

    @MainActor
    private func startProcessing() -> Bool {
        guard processorState.isReadyToProcess else { return false }
        self.isProcessing = true
        return true
    }

    @MainActor
    private func stopProcessing() {
        self.isProcessing = false
    }

    @MainActor
    func autoexpand() {
        guard !isUIExpanded else { return }
        isAutoexpanded = true
        isUIExpanded = true
    }
    
    @MainActor
    func autocollapse() {
        guard isAutoexpanded else { return }
        isUIExpanded = false
    }
    
    // MARK: - Abstracts for override
    var processorName: String { "<abstract>" }
    class var defaultActionName: String { NSLocalizedString("Process", comment: "") }
    var noResultString: String { NSLocalizedString("Not processed", comment: "") }

    var settingsView: AnyView { AnyView(EmptyView()) }
    var resultsView: AnyView { AnyView(EmptyView()) }
    var alternativeResultsView: AnyView { AnyView(EmptyView()) }
    var alternativeResultsTitle: String? { nil }

    func process(input: Any?) async -> Result<Any, Error> {
        .failure(ProcessorError.notImplemented)
    }
    
    // MARK: - Publishers
    @Published private(set) var cachedResult: VersionedProcessingResult?
    @Published private(set) var lastInputVersion: Int?
    @Published private(set) var processorState: ProcessorState = .waitingForInput
    @Published private var isProcessing: Bool = false
    @Published var isEnabled: Bool = true {
        didSet { Task{ await resetProcessor() } }
    }
    @Published var isUIExpanded: Bool = false {
        didSet {
            if !isUIExpanded {
                isAutoexpanded = false
            }
        }
    }
    @Published var isAutoexpanded: Bool = false
    @Published var actionName: String = "Ulet"

    // MARK: - iVars
    private(set) weak var document: PleasantTranslateDocument?
    private(set) var inputProvider: Processor? {
        didSet { addBindings(for: inputProvider) }
    }
    private var inputProviderBindings: [AnyCancellable] = []
    
    // MARK: - Constants
    static var id: ProcessorId { String(describing: self) }
    var id: ProcessorId { Self.id }
    private enum CodingKeys: CodingKey {
        case isUIExpanded
    }

    lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: Self.self))
}

// MARK: - CustomStringConvertible
extension Processor: CustomStringConvertible {
    var description: String {
        let versionString: String
        if let version = cachedResult?.version {
            versionString = "\(version)"
        } else {
            versionString = "-"
        }
        
        let resultString: String
        if let result = cachedResult?.processingResult {
            switch result {
            case .success:
                resultString = "valid"
            case .failure(let error):
                resultString = error.localizedDescription
            }
        } else {
            resultString = "-"
        }
        
        return"Processor \(id) - lastResult: \(resultString) [v\(versionString)]"
    }
}

extension Processor: Hashable {
    static func == (lhs: Processor, rhs: Processor) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
