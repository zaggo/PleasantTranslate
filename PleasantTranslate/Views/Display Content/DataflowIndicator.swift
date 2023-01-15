//
//  DataflowIndicator.swift
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

struct DataflowIndicator: View {
    var body: some View {
        if let state = processor.inputProvider?.processorState {
            Group {
                switch state {
                case .processed:
                    Image(systemSymbol: .arrowtriangleDownFill)
                default:
                    Image(systemSymbol: .arrowtriangleDown)
                }
            }
            .imageScale(.small)
        } else {
            EmptyView()
        }
    }
    @ObservedObject var processor: Processor
}

#if DEBUG
struct DataflowIndicator_Previews: PreviewProvider {
    static var previews: some View {
        DataflowIndicator(processor: ParserProcessor.sample)
    }
}
#endif
