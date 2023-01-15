//
//  Translator.swift
//  
//
//  Created by Eberhard Rensch on 04.05.21.
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
import os

typealias TranslatorIdentifier = String

protocol Translator: AnyObject, Identifiable {
    static var displayName: String { get }
    static var identifier: TranslatorIdentifier { get }

    init(apiKey: String,
         sourceLanguage: String,
         targetLanguage: String,
         glossary: [String: String],
         progress: Progress) throws

    func translate(sentences: [Sentence]) async throws -> ([Sentence], Int)
    func translate(batch: TranslationBatch) async throws -> TranslationBatch 

    var glossary: [String: String] { get set }
    var progress: Progress { get }
    var logger: Logger { get }
    
    var maxTranslationsPerRequest: Int { get }
}

// MARK: Identifiable Protocol
extension Translator {
    var id: TranslatorIdentifier { Self.identifier }
}

// MARK: Base translation algorithm
extension Translator {
    func translate(sentences: [Sentence]) async throws -> ([Sentence], Int) {        
        var glosarTranslations: TranslationBatch = []
        
        var translationBatch: TranslationBatch = []
        var translationBatches: [TranslationBatch] = []
        
        for (index, sentence) in sentences.enumerated() {
            if let translation = glossary[sentence.text] {
                glosarTranslations.append(TranslationRequest(index: index,
                                                             sentence: sentence.translate(with: translation),
                                                             originalCharacterCount: sentence.text.count))
                progress.completedUnitCount += 1
            } else {
                translationBatch.append(TranslationRequest(index: index,
                                                           sentence: sentence,
                                                           originalCharacterCount: sentence.text.count))
                if translationBatch.count >= maxTranslationsPerRequest {
                    translationBatches.append(translationBatch)
                    translationBatch.removeAll()
                }
            }
        }
        translationBatches.append(translationBatch)
        translationBatch.removeAll()
        
        if progress.isCancelled {  throw TranslatorError.translationCancelled }
        
        let translatedRequests = try await withThrowingTaskGroup(of: TranslationBatch.self) { group -> TranslationBatch in
            guard translationBatches.reduce(0, { $0 + $1.count }) > 0 else { return [] }
            for batch in translationBatches {
                group.addTask { try await self.translate(batch: batch) }
            }
            
            var translatedRequests = TranslationBatch()
            for try await translatedBatch in group {
                translatedRequests.append(contentsOf: translatedBatch)
                self.progress.completedUnitCount += Int64(translatedBatch.count)
                logger.debug("Update progess completion \(self.progress.completedUnitCount) by \(translatedBatch.count)")
                if progress.isCancelled {
                    throw TranslatorError.translationCancelled
                }
            }
            return translatedRequests
        }

        let allTranslations = glosarTranslations + translatedRequests
        let sortedTranslations = allTranslations.sorted(by: { $0.index < $1.index }).map({ $0.sentence })
        for (original, translation) in zip(sentences, sortedTranslations) {
            self.glossary[original.text] = translation.text
        }

        return (sortedTranslations, translatedRequests.reduce(0, { $0 + $1.originalCharacterCount }))
    }
}

enum TranslatorError: Error {
    case cannotComposeUrl
    case invalidHTTPResponse
    case invalidHTTPStatus(Int)
    case noTranslation
    case translationCancelled
}

// MARK: - Helper
typealias TranslationBatch = [TranslationRequest]
struct TranslationRequest {
    let index: Int
    let sentence: Sentence
    let originalCharacterCount: Int
}
