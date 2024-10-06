//
//  AppConfiguration.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 06.10.2024.
//


import SwiftUI
import Combine

class AppConfiguration: ObservableObject {
    @Published var fontSize: Int = 16
    @Published var applyMarkdown: Bool = true
    @Published var fontType: FontType = .cormorant
    @Published var animateCursor: Bool = false

    
    init() {
        // Load saved settings from UserDefaults if available
        fontSize = UserDefaults.standard.integer(forKey: "fontSize")
        if UserDefaults.standard.object(forKey: "applyMarkdown") != nil {
            applyMarkdown = UserDefaults.standard.bool(forKey: "applyMarkdown")
        }
        if UserDefaults.standard.object(forKey: "animateCursor") != nil {
            animateCursor = UserDefaults.standard.bool(forKey: "animateCursor")
        }
        if let savedFontType = UserDefaults.standard.string(forKey: "fontType"),
                   let font = FontType(rawValue: savedFontType) {
                    fontType = font
                }

    }
    
    func save() {
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(applyMarkdown, forKey: "applyMarkdown")
        UserDefaults.standard.set(fontType.rawValue, forKey: "fontType")
        UserDefaults.standard.set(animateCursor, forKey: "animateCursor")

    }
}

enum FontType: String, CaseIterable {
    case cormorant = "cormorant"
    case im_fell_english = "im_fell_english"
    case special_elite = "special_elite"
    case c_prime = "c_prime"
    var description: String {
        switch self {
        case .cormorant:
            return "Cormorant"
        case .im_fell_english:
            return "IM Fell English"
        case .c_prime:
            return "Courier Prime"
        case .special_elite:
            return "Special Elite"
        }
    }
}
