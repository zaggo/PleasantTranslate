//
//  ApiKeyManagementViewModel.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 14.01.23.
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

class ApiKeyManagementViewModel: ObservableObject {
    // MARK: - Initialization
    required init(with transaltionService: any Translator.Type) {
        self.transaltionService = transaltionService
        
        allApiKeys = ApiKeyStorage.shared.apiKeys(for: transaltionService.identifier)
        selectedApiKey = ApiKeyStorage.shared.selectedApiKey(for: transaltionService.identifier)
    }
    
    // MARK: - API
    var translationServiceDisplayName: String {
        transaltionService.displayName
    }
    
    func isSelectedApiKey(_ apiKey: ApiKey) -> Bool {
        selectedApiKey?.id == apiKey.id
    }
    
    func delete(_ apiKey: ApiKey) {
        // The Keychain access should't be on the MainActor!
        Task {
            var storage = ApiKeyStorage.shared
            guard storage.deleteApiKey(apiKey) else { return }
            await select(allApiKeys.first)
        }
    }
    
    func addApiKey(name: String, apiKey: String) {
        // The Keychain access should't be on the MainActor!
        Task {
            var storage = ApiKeyStorage.shared
            let newApiKey = storage.createApiKey(for: transaltionService.identifier,
                                             name: name)
            guard newApiKey.storeApiKey(apiKey) else {
                storage.deleteApiKey(newApiKey)
                return
            }
            await select(newApiKey)
        }
    }
    
    @MainActor
    func select(_ apiKey: ApiKey?) {
        var storage = ApiKeyStorage.shared
        if let apiKey {
            storage.setSelectedApiKey(apiKey)
        } else {
            storage.deleteSelectedApiKey(for: transaltionService.identifier)
        }
        selectedApiKey = apiKey
        refreshAllApiKeys()
    }
    
    // MARK: - Service
    @MainActor
    private func refreshAllApiKeys() {
        allApiKeys = ApiKeyStorage.shared.apiKeys(for: transaltionService.identifier)
    }
    
    // MARK: - Publishers
    @Published var allApiKeys: [ApiKey]
    @Published var selectedApiKey: ApiKey?

    // MARK: - iVars
    private let transaltionService: any Translator.Type
}
