//
//  eWriter2App.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//

import SwiftUI

@main
struct eWriter2App: App {
    var body: some Scene {
        DocumentGroup(newDocument: eWriter2Document()) { file in
            ContentView(document: file.$document)
        }
    }
}
