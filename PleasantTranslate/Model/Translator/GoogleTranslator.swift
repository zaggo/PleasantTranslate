//
//  GoogleTranslator.swift
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

class GoogleTranslator: Translator {    
    static var displayName: String { NSLocalizedString("Google Translate", comment: "") }
    static var identifier: TranslatorIdentifier { "google" }

    // MARK: - Initialization
    required init(apiKey: String, sourceLanguage: String, targetLanguage: String, glossary: [String: String], progress: Progress) throws {
        self.apiKey = apiKey
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.progress = progress
        self.glossary = glossary
    }
    
    // This implementation uses the Translate API v2!
    func translate(batch: TranslationBatch) async throws -> TranslationBatch {
        guard var urlComponents = URLComponents(string: apiURLString) else {
            throw TranslatorError.cannotComposeUrl
        }

        var result = TranslationBatch()
        for request in batch {
            var queryItems = [URLQueryItem]()
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
            queryItems.append(URLQueryItem(name: "q", value: request.sentence.text))
            queryItems.append(URLQueryItem(name: "target", value: targetLanguage))
            queryItems.append(URLQueryItem(name: "source", value: sourceLanguage))
            queryItems.append(URLQueryItem(name: "format", value: "text"))
            queryItems.append(URLQueryItem(name: "model", value: "base"))
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                throw TranslatorError.cannotComposeUrl
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            
            logger.debug("\(urlRequest.curlString())")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let response = response as? HTTPURLResponse else {
                throw TranslatorError.invalidHTTPResponse
            }
            
            switch response.statusCode {
            case (200 ..< 300):
                let googleResponse = try jsonDecoder.decode(GoogleResponse.self, from: data)
                guard let translation = googleResponse.data.translations.first?.translatedText else {
                    throw TranslatorError.noTranslation
                }
                
                let translatedSentence = request.sentence.translate(with: translation)
                result.append(.init(index: request.index,
                                    sentence: translatedSentence,
                                    originalCharacterCount: request.originalCharacterCount))
            default:
                throw TranslatorError.invalidHTTPStatus(response.statusCode)
            }
        }
        return result
    }

    private struct GoogleResponse: Decodable {
        let data: TranslationsWrapper
    }

    private struct TranslationsWrapper: Decodable {
        let translations: [TranslationWrapper]
    }

    private struct TranslationWrapper: Decodable {
        let translatedText: String
    }

    private struct TranslationInput: Encodable {
        let q: String
        let source: String
        let target: String
        let format: String
    }

    // MARK: - iVars
    private let apiKey: String
    private let sourceLanguage: String
    private let targetLanguage: String
    var glossary: [String: String]
    let progress: Progress
    
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    // MARK: - Constants
    private let apiURLString = "https://translation.googleapis.com/language/translate/v2"
    
    let maxTranslationsPerRequest = 25
    
    lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: Self.self))
}
