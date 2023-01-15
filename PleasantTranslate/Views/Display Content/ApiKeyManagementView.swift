//
//  ApiKeyManagementView.swift
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

import SwiftUI

struct ApiKeyManagementView: View {
    var body: some View {
        VStack {
            Text("Api Keys for \(viewModel.translationServiceDisplayName)")
            List(viewModel.allApiKeys) { apiKey in
                VStack {
                    HStack {
                        Button {
                            viewModel.select(apiKey)
                        } label: {
                            Image(systemSymbol: viewModel.isSelectedApiKey(apiKey) ? .circleInsetFilled : .circle)
                        }
                        .buttonStyle(.plain)
                        HStack {
                            Text(apiKey.name)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        Group {
                            if let key = apiKey.displayableApiKey {
                                Text(key)
                            } else {
                                Text("<No Api Key>")
                            }
                        }
                        .frame(width: 100)
                        Button {
                            viewModel.delete(apiKey)
                        } label: {
                            Image(systemSymbol: .minusCircleFill)
                                .foregroundColor(Color(.systemRed))
                        }
                        .buttonStyle(.plain)
                    }
                    Divider()
                }
            }
            HStack {
                TextField("Name:", text: $name, prompt: Text("Name"))
                TextField("ApiKey:", text: $apiKey, prompt: Text("ApiKey"))
                Button("Add") {
                    viewModel.addApiKey(name: name, apiKey: apiKey)
                    name = ""
                    apiKey = ""
                }
                .disabled(name.isEmpty || apiKey.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
    
    @State private var name: String = ""
    @State private var apiKey: String = ""
    
    @ObservedObject var viewModel: ApiKeyManagementViewModel
}

#if DEBUG
struct ApiKeyManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ApiKeyManagementView(viewModel: .sample)
    }
}
#endif
