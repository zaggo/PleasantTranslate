//
//  DeeplTranslator.swift
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

class DeeplTranslator: Translator {    
    static var displayName: String { NSLocalizedString("DeepL", comment: "") }
    static var identifier: TranslatorIdentifier { "deepl" }
    
    // MARK: - Initialization
    required init(apiKey: String,
                  sourceLanguage: String,
                  targetLanguage: String,
                  glossary: [String: String],
                  progress: Progress) throws {
        self.apiKey = apiKey
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.glossary = glossary
        self.progress = progress
        
        guard let apiUrl = URL(string: apiURLString) else {
            throw TranslatorError.cannotComposeUrl
        }
        self.apiUrl = apiUrl
    }
    

    // MARK: - Service
    func translate(batch: TranslationBatch) async throws -> TranslationBatch {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "target_lang", value: targetLanguage.uppercased()))
        queryItems.append(URLQueryItem(name: "source_lang", value: sourceLanguage.uppercased()))
        for request in batch {
            queryItems.append(URLQueryItem(name: "text", value: request.sentence.text))
        }
        
        var urlRequest = URLRequest(url: apiUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setFormURLEncoded(queryItems)
        
        logger.debug("\(urlRequest.curlString())")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let response = response as? HTTPURLResponse else {
            throw TranslatorError.invalidHTTPResponse
        }
        
        switch response.statusCode {
        case (200 ..< 300):
            let deeplResponse = try self.jsonDecoder.decode(DeeplResponse.self, from: data)
            var result = TranslationBatch()
            for (translation, request) in zip(deeplResponse.translations, batch) {
                let translatedSentence = request.sentence.translate(with: translation.text)
                result.append(.init(index: request.index,
                                    sentence: translatedSentence,
                                    originalCharacterCount: request.originalCharacterCount))
            }
            return result
        default:
            throw TranslatorError.invalidHTTPStatus(response.statusCode)
        }
        
    }

    // MARK: - iVars
    private let apiUrl: URL
    private let apiKey: String
    private let sourceLanguage: String
    private let targetLanguage: String
    let progress: Progress
    var glossary: [String: String]
    
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    // MARK: - Constants
    private let apiURLString = "https://api-free.deepl.com/v2/translate"
    let maxTranslationsPerRequest = 25
    
    lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: Self.self))

    // MARK: - Helpers
    
    private struct DeeplResponse: Decodable {
        let translations: [TranslationWrapper]
    }
    
    private struct TranslationWrapper: Decodable {
        let text: String
    }
}
