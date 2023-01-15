//
//  ProcessorError.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 04.01.23.
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

enum ProcessorError: Error {
    case notImplemented
    case missingInput
    case wrongInputFormat
    case notReady
    case noDocument
    case noApiKey
}

extension ProcessorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return NSLocalizedString("This processor is not implemented, yet", comment: "")
        case .missingInput:
            return NSLocalizedString("Processer input is missing", comment: "")
        case .wrongInputFormat:
            return NSLocalizedString("This input provided for this processor has the wrong format", comment: "")
        case .notReady:
            return NSLocalizedString("This processor is not ready for processing", comment: "")
        case .noDocument:
            return NSLocalizedString("The processor cannot access the document", comment: "")
        case .noApiKey:
            return NSLocalizedString("API Key is not set", comment: "")
        }
    }
}
