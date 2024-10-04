//
//  eWriter2Document.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var exampleText: UTType {
        UTType(importedAs: "com.example.plain-text")
    }
}

class eWriter2Document: ObservableObject, FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

        @Published var text: String

        init(text: String = "Hello, world!") {
            self.text = text
        }

        required init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents,
                  let text = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            self.text = text
        }

        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            let data = text.data(using: .utf8)!
            return FileWrapper(regularFileWithContents: data)
        }
}
