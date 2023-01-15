//
//  TargetLanguageMenu.swift
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

struct TargetLanguageMenu: View {
    var body: some View {
        Menu {
            ForEach(document.availableTargetLanguages) { option in
                Button(option.displayName, action: {
                    document.targetLanguage = option.payload
                })
            }
        } label: {
            Label(document.targetLanguage.displayName,
                  systemSymbol: .ear)
        }
    }
    
    @ObservedObject var document: PleasantTranslateDocument
}

#if DEBUG
struct LanguageMenu_Previews: PreviewProvider {
    static var previews: some View {
        TargetLanguageMenu(document: .sample)
    }
}
#endif
