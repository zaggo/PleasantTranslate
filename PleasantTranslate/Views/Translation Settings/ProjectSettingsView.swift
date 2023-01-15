//
//  ProjectSettingsView.swift
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
import SFSafeSymbols

struct ProjectSettingsView: View {
    var body: some View {
        DisclosureGroup(
            isExpanded: $expandedSettings,
            content: {
                VStack {
                    SourceLanguageMenu(document: document)
                    Image(systemSymbol: .arrowDown)
                    TranslatorMenu(document: document)
                    Image(systemSymbol: .arrowDown)
                    TargetLanguageMenu(document: document)
                }
                .controlSize(.small)
                .padding()
                .background(Color.secondaryBackground)
            }, label: {
                HStack(spacing: 2) {
                    Text(document.sourceLanguage.displayName)
                    Image(systemSymbol: .arrowRight)
                    Text(document.translationService.displayName)
                    Image(systemSymbol: .arrowRight)
                    Text(document.targetLanguage.displayName)
                }
                .font(.footnote)
                .padding(.leading, 3)
                .onTapGesture {
                    withAnimation {
                        expandedSettings.toggle()
                    }
                }
            })
        .padding([.leading, .trailing])
    }
    
    @AppStorage("expandedProjectSettings", store: .standard) var expandedSettings = false
    @ObservedObject var document: PleasantTranslateDocument
}

#if DEBUG
struct ProjectSettingsView_Previews: PreviewProvider {
    static var previews: some View {
    ProjectSettingsView(document: .sample)
        .frame(width: 200)
    }
}
#endif
