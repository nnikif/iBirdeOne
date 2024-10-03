//
//  ContentView.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 03.10.2024.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: eWriter2Document

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(eWriter2Document()))
}
