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
    @Published var autoCorrection: AutoCorrectionConfigType = .no
    @Published var inlinePrediction: InlinePredictionConfigType = .no

    
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
        if let savedAutoCorrection = UserDefaults.standard.string(forKey: "autoCorrection"),
                  let autoCorrectionType = AutoCorrectionConfigType(rawValue: savedAutoCorrection) {
                   autoCorrection = autoCorrectionType
               }
        if let savedInlinePrediction = UserDefaults.standard.string(forKey: "inlinePrediction"),
                  let inlinePredictionType = InlinePredictionConfigType(rawValue: savedInlinePrediction) {
                    inlinePrediction = inlinePredictionType
               }

    }
    
    func save() {
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(applyMarkdown, forKey: "applyMarkdown")
        UserDefaults.standard.set(fontType.rawValue, forKey: "fontType")
        UserDefaults.standard.set(animateCursor, forKey: "animateCursor")
        UserDefaults.standard.set(autoCorrection.rawValue, forKey: "autoCorrection")
        UserDefaults.standard.set(inlinePrediction.rawValue, forKey: "inlinePrediction")
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

enum AutoCorrectionConfigType: String, CaseIterable {
    case `default` = "default"
    case yes = "yes"
    case no = "no"

    var uiTextAutocorrectionType: UITextAutocorrectionType {
        switch self {
        case .default:
            return .default
        case .yes:
            return .yes
        case .no:
            return .no
        }
    }
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .yes:
            return "Yes"
        case .no:
            return "No"
        }
    }
}

enum InlinePredictionConfigType: String, CaseIterable {
    case `default` = "default"
    case yes = "yes"
    case no = "no"

    var uiTextInlinePredictionType: UITextInlinePredictionType {
        switch self {
        case .default:
            return .default
        case .yes:
            return .yes
        case .no:
            return .no
        }
    }
    var description: String {
        switch self {
        case .default:
            return "Default"
        case .yes:
            return "Yes"
        case .no:
            return "No"
        }
    }
}
