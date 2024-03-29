//
//  MergeSettingsView.swift
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

struct TimeshiftSettingsView: View {
    var body: some View {
        VStack {
            Text("Processed Subtitles:")
            Text("\(processor.processedSubtitlesCount)")
            HStack {
                TextField("Timeshift", value: $processor.timeshift, format: .number, prompt: Text("Shift in seconds"))
                    .multilineTextAlignment(.trailing)
                    .disabled(!processor.isEnabled)
                Text("s")
            }
        }
    }
    
    @ObservedObject var processor: TimeshiftProcessor
}

#if DEBUG
struct TimeshiftSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TimeshiftSettingsView(processor: TimeshiftProcessor(inputProvider: nil, document: .sample))
    }
}
#endif
