//
//  ProcessorState.swift
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

import Foundation

enum ProcessorState {
    case waitingForInput
    case readyToProcess
    case processing
    case processed
    case error(Error)
    
    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
    
    var didProcess: Bool {
        if case .processed = self { return true }
        return false
    }

    var isReadyToProcess: Bool {
        if case .readyToProcess = self { return true }
        if case .waitingForInput = self { return true }
        return false
    }
    
    var hadError: Bool {
        if case .error = self { return true }
        return false
    }
}
