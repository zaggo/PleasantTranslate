//
//  ApiKeyStorage.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 08.01.23.
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
import KeychainAccess

typealias ApiKeyId = String
struct ApiKey: Codable, Identifiable {
    // MARK: - Initialization
    init(serviceIdentifier: TranslatorIdentifier, name: String) {
        self.id = UUID().uuidString
        self.serviceIdentifier = serviceIdentifier
        self.name = name
    }
    
    // MARK: - API
    var displayableApiKey: String? {
        guard let apiKey = apiKey else { return nil }
        guard apiKey.count > 8 else { return "•••" }
        return apiKey.prefix(4) + "•••" + apiKey.suffix(4)
    }
    
    var apiKey: String? {
        guard let keychain = ApiKeyStorage.shared.keychain else { return nil }
        return keychain[id]
    }
    
    func storeApiKey(_ apiKey: String) -> Bool {
        guard let keychain = ApiKeyStorage.shared.keychain else { return false }
        keychain[id] = apiKey
        return true
    }

    // MARK: - iVars
    let id: ApiKeyId
    let serviceIdentifier: TranslatorIdentifier
    var name: String
}

struct ApiKeyStorage {
    // MARK: - Initialization
    static let shared = ApiKeyStorage()
    private init() {
        if let bundleId = Bundle.main.bundleIdentifier {
            keychain = Keychain(service: bundleId)
        } else {
            keychain = nil // Should never happen, yada, yada, yada…
        }
    }
    
    // MARK: - API
    func apiKeys(for serviceIdentifier: TranslatorIdentifier) -> [ApiKey] {
        allApiKeys.filter({ $0.serviceIdentifier == serviceIdentifier})
    }
    
    mutating func createApiKey(for serviceIdentifier: TranslatorIdentifier, name: String) -> ApiKey {
        let apiKey = ApiKey(serviceIdentifier: serviceIdentifier, name: name)
        var allKeys = allApiKeys
        allKeys.append(apiKey)
        allApiKeys = allKeys
        return apiKey
    }
    
    @discardableResult
    mutating func deleteApiKey(_ apiKey: ApiKey) -> Bool {
        guard let keychain else { return false }
        var allKeys = allApiKeys
        allKeys.removeAll(where: { $0.id == apiKey.id })
        allApiKeys = allKeys
        var selectedKeys = selectedApiKeys
        selectedKeys.removeAll(where: { $0.serviceIdentifier == apiKey.serviceIdentifier })
        selectedApiKeys = selectedKeys

        keychain[apiKey.id] = nil
        return true
    }
    
    func selectedApiKey(for serviceIdentifier: TranslatorIdentifier) -> ApiKey? {
        selectedApiKeys.first(where: { $0.serviceIdentifier == serviceIdentifier})
    }

    mutating func setSelectedApiKey(_ apiKey: ApiKey) {
        var selectedKeys = selectedApiKeys
        selectedKeys.removeAll(where: { $0.serviceIdentifier == apiKey.serviceIdentifier })
        selectedKeys.append(apiKey)
        selectedApiKeys = selectedKeys
    }
    
    mutating func deleteSelectedApiKey(for serviceIdentifier: TranslatorIdentifier) {
        var selectedKeys = selectedApiKeys
        selectedKeys.removeAll(where: { $0.serviceIdentifier == serviceIdentifier })
        selectedApiKeys = selectedKeys
    }
    
    // MARK: - UserDefaults
    @LocalUserDefault(key: "APIKeyStorage", defaultValue: [])
    private var allApiKeys: [ApiKey]

    @LocalUserDefault(key: "SelectedAPIKey", defaultValue: [])
    private var selectedApiKeys: [ApiKey]

    // MARK: - Constants
    let keychain: Keychain?
}
