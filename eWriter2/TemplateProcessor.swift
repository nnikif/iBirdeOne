import Foundation

import SwiftUI
import Combine


struct TemplateProcessor {
    let data: [String: [String: [String: String]]] = [
        "fontType":
            [
                "cormorant": [
                    "url":"<link href='https://fonts.googleapis.com/css2?family=Cormorant:ital,wght@0,300..700;1,300..700&display=swap' rel='stylesheet'>"
                        ,
                    "fontName":"'Cormorant', serif"
                ],
                "im_fell_english":[
                    "url":"<link href='https://fonts.googleapis.com/css2?family=IM+Fell+English:ital@0;1&display=swap' rel='stylesheet'>",
                    "fontName":"'IM Fell English', system-ui"
                ],
                "c_prime": [
                    "url":"<link href='https://fonts.googleapis.com/css2?family=Courier+Prime:ital,wght@0,400;0,700;1,400;1,700&display=swap' rel='stylesheet'>",
                    "fontName":"'Courier Prime', monospace"
                ],
                "special_elite": [
                    "url":"<link href='https://fonts.googleapis.com/css2?family=Special+Elite&display=swap' rel='stylesheet'>",
                    "fontName":"'Special Elite', system-ui"
                ]
            ]
    ]
    
    let config: AppConfiguration // Use AppConfiguration instead of a plain dictionary

    init(config: AppConfiguration) {
        self.config = config
    }

    func process(template: String) -> String {
        var result = template

        // First process the existing pattern ${key:subKey}
        let regexPattern1 = #"\$\{(\w+):(\w+)\}"#
        let regex1 = try! NSRegularExpression(pattern: regexPattern1, options: [])

        let matches1 = regex1.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))

        for match in matches1.reversed() {
            guard match.numberOfRanges == 3 else { continue }

            let keyRange = Range(match.range(at: 1), in: template)!
            let subKeyRange = Range(match.range(at: 2), in: template)!

            let key = String(template[keyRange])
            let subKey = String(template[subKeyRange])

            if let selectedValue = configValue(forKey: key),
               let subDictionary = data[key]?[selectedValue],
               let value = subDictionary[subKey] {
                let placeholderRange = Range(match.range, in: template)!
                result.replaceSubrange(placeholderRange, with: value)
            }
        }

        // Now process the new pattern %{key}
        let regexPattern2 = #"%\{(\w+)\}"#
        let regex2 = try! NSRegularExpression(pattern: regexPattern2, options: [])

        let matches2 = regex2.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))

        for match in matches2.reversed() {
            guard match.numberOfRanges == 2 else { continue }

            let keyRange = Range(match.range(at: 1), in: result)!

            let key = String(result[keyRange])

            if let value = configValue(forKey: key) {
                let placeholderRange = Range(match.range, in: result)!
                result.replaceSubrange(placeholderRange, with: value)
            }
        }

        return result
    }

    // Helper function to get the value from AppConfiguration as String
    private func configValue(forKey key: String) -> String? {
        switch key {
        case "fontSize":
            return "\(config.fontSize)"
        case "applyMarkdown":
            return config.applyMarkdown ? "true" : "false"
        case "fontType":
            return config.fontType.rawValue
        case "animateCursor":
            return config.animateCursor ? "animation: blink 1s step-start infinite;" : ""
        default:
            return nil
        }
    }
}


