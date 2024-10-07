//
//  TextOperations.swift
//  eWriter2
//
//  Created by Nikolay Nikiforov on 04.10.2024.
//
import SwiftDiff
import Foundation

struct MessageObject {
    let messageType: String
    let details: String?
    let cursorPositon: String?
    
    func toDictionary() -> [String: String] {
            var dict: [String: String] = ["messageType": messageType]
            if let cursorPositon {
                dict["cursorPosition"] = cursorPositon
            }
            if let details = details {
                        dict["details"] = details
            }
            return dict
        }
}

struct CursorParagraphInfo {
    let paragraphIndex: Int
    let positionInParagraph: Int
    let selectionInfo: String?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "paragraphIndex": paragraphIndex,
            "positionInParagraph": positionInParagraph
        ]
        if let selectionInfo {
            dict["selectionInfo"] = selectionInfo
        }
        return dict
    }
}


func convertDiffToJSON(oldText: String, newText: String) -> [[String: Any]] {
//    guard oldText.count != newText.count else   {
//        print("Seening same text length, no diff")
//        return []
//    }
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

func convertDiffToJSONString(oldText: String, newText: String) -> String {
    let diffArray = convertDiffToJSON(oldText: oldText, newText: newText)
    return convertDiffToJSONString(diffArray: diffArray)
}

func convertDiffToJSONString(diffArray: [[String: Any]]) -> String {
    if let jsonData = try? JSONSerialization.data(withJSONObject: diffArray, options: []) {
        // Convert the JSON data to a string
        return String(data: jsonData, encoding: .utf8) ?? String(data: try! JSONSerialization.data(withJSONObject: [], options: []), encoding: .utf8)!
    } else {
        print("Failed to convert diffs to JSON")
        return String(data: try! JSONSerialization.data(withJSONObject: [], options: []), encoding: .utf8)!
    }
}

func splitTextIntoParagraphs(text: String) -> [String] {
    // Split the text by newlines to get paragraphs
    let paragraphs = text.components(separatedBy: "\n")
    return paragraphs
}

func convertJSONToString(jsonObject: Any) -> String {
    guard JSONSerialization.isValidJSONObject(jsonObject) else {
        print("Invalid JSON object")
        return "{}"
    }
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    } catch {
        print("Failed to convert JSON object to string: \(error)")
        return "{}"
    }
}

func convertParagraphsToDiffs(oldParagraphs: [String], newParagraphs: [String]) -> [[String: Any]]? {
    var diffs: [[String: Any]] = []
    
    if oldParagraphs.count != newParagraphs.count {
        return nil;
    }
    
    // Define the length of the loop - we iterate over the maximum number of paragraphs in either array
    let maxLength = max(oldParagraphs.count, newParagraphs.count)
    
    for index in 0..<maxLength {
        let oldParagraph = index < oldParagraphs.count ? oldParagraphs[index] : ""
        let newParagraph = index < newParagraphs.count ? newParagraphs[index] : ""
        guard oldParagraph.count != newParagraph.count else {
//            print("Paragraphs at index \(index) are same lenght. Skipping...")
            continue
        }
        
        // Get the diff for the current paragraphs
        let diff = convertDiffToJSONString(oldText: oldParagraph, newText: newParagraph)
        if diff != "[]" {
            // Append the diff and corresponding index to the results
            diffs.append(["index": index, "diff": diff])
        }
        if diffs.count > 1 {
            return nil
        }
    }
//    print("the diffs are: \(diffs)")
    return diffs
}

func stringifyArrayofString(arrayData: [String]) -> String {
    if let jsonData = try? JSONSerialization.data(withJSONObject: arrayData, options: []) {
        // Convert the JSON data to a string
        return String(data: jsonData, encoding: .utf8) ?? String(data: try! JSONSerialization.data(withJSONObject: [], options: []), encoding: .utf8)!
    } else {
        print("Failed to convert diffs to JSON")
        return String(data: try! JSONSerialization.data(withJSONObject: [], options: []), encoding: .utf8)!
    }
    
}

func calculateDiffResponse(oldText: String, newText: String, cursorPosition: Int) -> MessageObject{
    let oldParagraphs = splitTextIntoParagraphs(text: oldText)
    let newParagraphs = splitTextIntoParagraphs(text: newText)
    guard let diffs = convertParagraphsToDiffs(oldParagraphs: oldParagraphs, newParagraphs: newParagraphs) else {
        let cursorParagraphInfo = getCursorParagraphInfo(text: newText, cursorPosition: cursorPosition, selectionStart: nil, selectionEnd: nil)
        let cursorPositionResponse: String? = cursorParagraphInfo != nil ? convertJSONToString(jsonObject: cursorParagraphInfo!.toDictionary()) : nil
        return MessageObject(messageType:"paragraphReset", details: stringifyArrayofString(arrayData: newParagraphs), cursorPositon: cursorPositionResponse)
    }
    if diffs.count == 1 {
        let cursorParagraphInfo = getCursorParagraphInfo(text: newText, cursorPosition: cursorPosition, selectionStart: nil, selectionEnd: nil)
        let cursorPositionResponse: String? = cursorParagraphInfo != nil ? convertJSONToString(jsonObject: cursorParagraphInfo!.toDictionary()) : nil
        return MessageObject(messageType:"paragraphDiff", details: convertJSONToString(jsonObject: diffs[0]), cursorPositon: cursorPositionResponse)
    } else {
        let cursorParagraphInfo = getCursorParagraphInfo(text: newText, cursorPosition: cursorPosition, selectionStart: nil, selectionEnd: nil)
        let cursorPositionResponse: String? = cursorParagraphInfo != nil ? convertJSONToString(jsonObject: cursorParagraphInfo!.toDictionary()) : nil
        return MessageObject(messageType:"paragraphReset", details: stringifyArrayofString(arrayData: newParagraphs), cursorPositon: cursorPositionResponse)
    }
}

func getCursorParagraphInfo(text: String, cursorPosition: Int, selectionStart: Int?, selectionEnd: Int?) -> CursorParagraphInfo? {
    let paragraphs = splitTextIntoParagraphs(text: text)
    var paragraphIndex = 0;
    var currentPos = 0
    var positionInParagraph = 0
    var cursorParagraphInfo: CursorParagraphInfo
    var selectionInfo: [(paragraphIndex: Int, start: Int, end: Int)] = []
    var lastParagraphLength = 0
    var lastIndex = 0
    
    for (index, paragraph) in paragraphs.enumerated() {
        let paragraphLength = paragraph.count
        lastParagraphLength = paragraphLength
        lastIndex = index
        // Check if the cursor is within the current paragraph
        if cursorPosition >= currentPos && cursorPosition <= currentPos + paragraphLength {
            positionInParagraph = cursorPosition - currentPos
            paragraphIndex = index
            break
        }
        
        // Move to the start of the next paragraph (+1 for the newline character)
        currentPos += paragraphLength + 1
    }
    if let selectionStart = selectionStart, let selectionEnd = selectionEnd, selectionStart < selectionEnd {
        currentPos = 0;
        for (index, paragraph) in paragraphs.enumerated() {
                let paragraphLength = paragraph.count
                
                // Check if the selection intersects with the current paragraph
                if selectionEnd > currentPos && selectionStart < currentPos + paragraphLength {
                    let startInParagraph = max(selectionStart - currentPos, 0)
                    let endInParagraph = min(selectionEnd - currentPos, paragraphLength)
                    
                    selectionInfo.append((paragraphIndex: index, start: startInParagraph, end: endInParagraph))
                }
                
                // Move to the start of the next paragraph (+1 for the newline character)
                currentPos += paragraphLength + 1
            }
        
    }
    
    guard !(paragraphIndex == 0 && positionInParagraph == 0) else {
        cursorParagraphInfo = CursorParagraphInfo(paragraphIndex: lastIndex, positionInParagraph: lastParagraphLength, selectionInfo: convertSelectionInfoToJSONString(selectionInfo: selectionInfo))
        return cursorParagraphInfo
    }
    cursorParagraphInfo = CursorParagraphInfo(paragraphIndex: paragraphIndex, positionInParagraph: positionInParagraph, selectionInfo: convertSelectionInfoToJSONString(selectionInfo: selectionInfo))
    return cursorParagraphInfo
}

func convertSelectionInfoToJSONString(selectionInfo: [(paragraphIndex: Int, start: Int, end: Int)]) -> String? {
    guard !selectionInfo.isEmpty else {
            return nil
        }
    
    let jsonArray = selectionInfo.map { info in
        [
            "paragraphIndex": info.paragraphIndex,
            "start": info.start,
            "end": info.end
        ]
    }
    
    guard JSONSerialization.isValidJSONObject(jsonArray) else {
        print("Invalid JSON object")
        return nil
    }
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
        return String(data: jsonData, encoding: .utf8)
    } catch {
        print("Failed to convert selection info to JSON string: \(error)")
        return nil
    }
}

func recalculateCursorPosition(text: String, position: Int) -> Int {
    guard position >= 0 && position <= text.count else {
            print("Position out of bounds.")
            return position
        }
        
        // Get the substring up to the given position
        let index = text.index(text.startIndex, offsetBy: position)
        let substring = text[text.startIndex..<index]
        
        // Count the occurrences of '\n' in the substring
        let numberOfLineBreaks = substring.filter { $0 == "\n" }.count
        
        return position + numberOfLineBreaks
    
}
