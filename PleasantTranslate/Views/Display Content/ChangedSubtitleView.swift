//
//  ChangedSubtitleView.swift
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

import SwiftUI
import SFSafeSymbols

struct ChangedSubtitleView: View {
    
    var body: some View {
        HStack {
            SubtitleView(subtitle: change.original)
            
            Toggle(isOn: $isEnabled) {
                Image(systemSymbol: .arrowRight)
            }
            
            SubtitleView(subtitle: change.processed)
                .opacity(isEnabled ? 1.0 : 0.2)
        }
        .onAppear(perform: {
            isEnabled = disabledSubtitleIdsProvider.isSubtitleChangeEnabled(for: change.original.id)
        })
        .onChange(of: isEnabled) { newValue in
            guard disabledSubtitleIdsProvider.isSubtitleChangeEnabled(for: change.original.id) != newValue else { return }
            if newValue {
                disabledSubtitleIdsProvider.enableSubtitleChange(for: change.original.id)
            } else {
                disabledSubtitleIdsProvider.disableSubtitleChange(for: change.original.id)
            }
        }
    }
    
    let change: ChangedSubtitle
    let disabledSubtitleIdsProvider: DisabledSubtitleIdsProvider & Processor
    @State private var isEnabled: Bool = true
}

#if DEBUG
struct ChangedSubtitleView_Previews: PreviewProvider {
    static var previews: some View {
        ChangedSubtitleView(change: .sample, disabledSubtitleIdsProvider: PurgeCCProcessor.sample)
    }
}
#endif
