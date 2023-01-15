//
//  OpenPanel+Views.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 14.05.21.
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

import Cocoa
import UniformTypeIdentifiers

extension NSOpenPanel {
    
    static func chooseSrt(completion: @escaping (_ result: Result<URL, Error>) -> ()) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.subtitleFile]
        panel.begin { (result) in
            if result == .OK,
               let url = panel.urls.first {
                completion(.success(url))
            } else {
                completion(.failure(
                    NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file location"])
                ))
            }
        }
    }
    
    static func chooseOutputDir(url: URL, completion: @escaping (_ result: Result<URL, Error>) -> ()) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.prompt = "Export"
        panel.title = "Eport translated Subtitles"
        panel.nameFieldStringValue = url.lastPathComponent
        panel.directoryURL = url.deletingLastPathComponent()
        panel.allowedContentTypes = [UTType.subtitleFile]
        let response = panel.runModal()
        switch response {
        case .OK:
            if let url = panel.url {
                completion(.success(url))
            }
            fallthrough
        default:
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get save location"])))
        }
    }
}
