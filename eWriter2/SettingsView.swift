//
//  SettingsView.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 06.10.2024.
//
import SwiftUI



struct SettingsView: View {
    @EnvironmentObject var config: AppConfiguration
    @Environment(\.presentationMode) var presentationMode
    @State private var fontSizeInput: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Server Settings")) {
                HStack {
                                    Text("Font Size: ")
                                    TextField("Enter value", text: $fontSizeInput)
                                        .keyboardType(.numberPad)
                                        .onChange(of: fontSizeInput) { oldValue, newValue in
                                            // Only allow numeric characters in the input
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered != newValue {
                                                fontSizeInput = filtered
                                            }
                                            
                                            // Update the config if the input is valid and within range
                                            if let fontSize = Int(filtered), (10...56).contains(fontSize) {
                                                config.fontSize = fontSize
                                            }
                                        }
                                }
                                .onAppear {
                                    // Set initial value for the font size input field
                                    fontSizeInput = "\(config.fontSize)"
                                }
                Picker("Font Type", selection: $config.fontType) {
                                    ForEach(FontType.allCases, id: \.self) { font in
                                        Text(font.description).tag(font)
                                    }
                                }

                
                Toggle(isOn: $config.applyMarkdown) {
                    Text("Apply Markdown")
                }
                Toggle(isOn: $config.animateCursor) {
                    Text("Animate Cursor")
                }
                Picker("AutoCorrection Settings", selection: $config.autoCorrection) {
                                   ForEach(AutoCorrectionConfigType.allCases, id: \.self) { autoCorrectionConfig in
                                       Text(autoCorrectionConfig.description).tag(autoCorrectionConfig)
                                       
                                   }
                               }
                               Picker("InlinePrediction Settings", selection: $config.inlinePrediction) {
                                   ForEach(InlinePredictionConfigType.allCases, id: \.self) { inlinePredictionConfig in
                                       Text(inlinePredictionConfig.description).tag(inlinePredictionConfig)
                                       
                                   }
                               }
            }
            
            Button(action: {
                config.save()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save Settings")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .navigationTitle("Settings")
    }
}
