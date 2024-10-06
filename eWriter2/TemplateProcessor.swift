import Foundation

struct TemplateProcessor {
    let data: [String: [String: [String: String]]]
    let config: [String: String]
    
    init(data: [String: [String: [String: String]]], config: [String: String]) {
        self.data = data
        self.config = config
    }
    
    func process(template: String) -> String {
        var result = template
        
        let regexPattern = #"\$\{(\w+):(\w+)\}"#
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        
        let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.utf16.count))
        
        for match in matches.reversed() {
            guard match.numberOfRanges == 3 else { continue }
            
            let keyRange = Range(match.range(at: 1), in: template)!
            let subKeyRange = Range(match.range(at: 2), in: template)!
            
            let key = String(template[keyRange])
            let subKey = String(template[subKeyRange])
            
            if let selectedValue = config[key],
               let subDictionary = data[key]?[selectedValue],
               let value = subDictionary[subKey] {
                let placeholderRange = Range(match.range, in: template)!
                result.replaceSubrange(placeholderRange, with: value)
            }
        }
        
        return result
    }
}

// Example usage
//let data: [String: [String: [String: String]]] = [
//    "person": [
//        "guy1": ["name": "James", "lastname": "Jones"],
//        "girl1": ["name": "Julia", "lastname": "Jameson"]
//    ],
//    "movie": [
//        "matrix": ["title": "The Matrix", "year": "1999"],
//        "inception": ["title": "Inception", "year": "2010"]
//    ]
//]
//
//let config: [String: String] = ["person": "guy1", "movie": "matrix"]
//
//let template = "Hello, ${person:name} ${person:lastname}! Your favorite movie is ${movie:title} released in ${movie:year}."
//
//let processor = TemplateProcessor(data: data, config: config)
//let result = processor.process(template: template)
