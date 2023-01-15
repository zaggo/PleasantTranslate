//
//  DocumentViewModel.swift
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

import Foundation

extension PleasantTranslateDocument {

    // MARK: - API
    var canSelectNextProcessor: Bool {
        selectedProcessor != processors.last
    }
    
    @MainActor
    func selectNextProcessor() {
        guard let selectedProcessor,
              let currentIndex = processors.firstIndex(of: selectedProcessor) else {
            selectProcessor(processors.first)
            processors.first?.isUIExpanded = true
            return
        }
        guard processors.indices.contains(currentIndex+1) else { return }
        processors[currentIndex].autocollapse()
        selectProcessor(processors[currentIndex+1])
        self.selectedProcessor?.autoexpand()
    }
    
    var canSelectPreviousProcessor: Bool {
        selectedProcessor != processors.first
    }
    
    @MainActor
    func selectPreviousProcessor() {
        guard let selectedProcessor,
              let currentIndex = processors.firstIndex(of: selectedProcessor) else {
            selectProcessor(processors.last)
            processors.last?.isUIExpanded = true
            return
        }
        guard processors.indices.contains(currentIndex-1) else { return }
        processors[currentIndex].autocollapse()
        selectProcessor(processors[currentIndex-1])
        self.selectedProcessor?.autoexpand()
    }
    
    @MainActor
    func selectProcessor(_ processor: Processor?) {
        guard let processor else {
            selectedProcessorId = .none
            return
        }
        selectedProcessorId = .processorId(processor.id)
    }
    
    @MainActor
    func autoexpand(_ processor: Processor) {
        for p in processors where p != processor {
            p.autocollapse()
        }
        processor.autoexpand()
    }
}
