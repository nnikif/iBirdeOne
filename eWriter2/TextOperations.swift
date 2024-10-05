//
//  TextOperations.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 04.10.2024.
//
import SwiftDiff
import Foundation

func convertDiffToJSON(oldText: String, newText: String) -> [[String: Any]] {
    let diffs = diff(text1: oldText, text2: newText).cleaningUpSemantics()
    var result = [[String: Any]]()
    var currentPosition = 0

    for diff in diffs {
        switch diff {
        case .equal(let equalText):
            // Move the current position forward by the length of the equal text
            currentPosition += equalText.count
            
        case .delete(let deletedText):
            result.append([
                "position": currentPosition,
                "delete": deletedText.count,
                "insert": ""
            ])
            // Do not advance currentPosition, as text is deleted
            
        case .insert(let insertedText):
            result.append([
                "position": currentPosition,
                "delete": 0,
                "insert": insertedText
            ])
            // Advance currentPosition by the length of the inserted text
            currentPosition += insertedText.count
        
        }
    }
    
    return result
}

func convertDiffToJSONString(oldText: String, newText: String) -> String? {
    let diffArray = convertDiffToJSON(oldText: oldText, newText: newText)
    
    // Convert the array of dictionaries to JSON data
    if let jsonData = try? JSONSerialization.data(withJSONObject: diffArray, options: []) {
        // Convert the JSON data to a string
        return String(data: jsonData, encoding: .utf8)
    } else {
        print("Failed to convert diffs to JSON")
        return nil
    }
}
