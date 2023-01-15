//
//  ImportSettingsView.swift
//  PleasantTranslate
//
//  Created by Eberhard Rensch on 06.05.21.
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

struct ImportSettingsView: View {
    var body: some View {
        Group {
            HStack {
                VStack {
                    if let fileName = processor.sourceFileUrl?.lastPathComponent {
                        Text(fileName)
                            .font(.subheadline)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    VStack {
                        Text("Drop SRT File here")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 10)
                        
                        VStack(alignment: .leading) {
                            Toggle("Replace `cr` `nl`",
                                   isOn: $processor.replaceCRNL)
                            Toggle("Purge HTML Tags",
                                   isOn: $processor.purgeHtml)
                        }
                        .controlSize(.small)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(dragOver ? Color(.selectedContentBackgroundColor) : Color.clear)
                        )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [10]
                                )
                            )
                            .foregroundColor(Color(.separatorColor))
                    )
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $dragOver, perform: { providers in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, error in
                guard let data = data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)  else { return }
                DispatchQueue.main.async {
                    Task.detached {
                        await self.processor.resetSourceFileUrl(url)
                        await self.processor.process()
                    }
                }
            }
            return true
        })
    }
    
    @ObservedObject var processor: ImportProcessor
    @State private var dragOver: Bool = false
}

#if DEBUG
struct ImportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ImportSettingsView(processor: .sample)
    }
}
#endif
