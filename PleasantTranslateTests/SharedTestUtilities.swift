//
//  SharedTestUtilities.swift
//  PleasantTranslateTests
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

import XCTest

extension StringProtocol {
    var trimmed: String { self.trimmingCharacters(in: .whitespaces) }
}


extension RandomAccessCollection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}

extension Result {
    func extractSuccessResult<T>() throws -> T {
        switch self {
        case .failure(let error): throw error
        case .success(let success):
            guard let result = success as? T else {
                throw ResultError.wrongResultType
            }
            return result
        }
    }
    
    enum ResultError: Error {
        case wrongResultType
    }
}

extension XCTest {
    func extractProcessorResult<T>(from result: Result<Any, Error>) throws -> T {
        guard case .success(let rawData) = result else {
            if case .failure(let error) = result {
                throw ProcessorTestError.processorFailed(error)
            } else {
                throw ProcessorTestError.invalidProcessorResult
            }
        }
        
        guard let data = rawData as? T else {
            throw ProcessorTestError.invalidResultType
        }
        
        return data
    }
    
    enum ProcessorTestError: Error {
        case invalidResultType
        case invalidProcessorResult
        case processorFailed(Error)
    }
}
