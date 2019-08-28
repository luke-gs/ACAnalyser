//
//  TextAnalyser.swift
//  ACAnalyser
//
//  Created by QHMW64 on 28/8/19.
//  Copyright © 2019 Gridstone. All rights reserved.
//

import Foundation
import NaturalLanguage
import UIKit

public class NarrativeAnalyser {

    public enum Error: LocalizedError {
        case emptyText

    }

    private let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
    private let classifier = NLTokenizer(unit: .document)
    private let model = NLModel()

    func classify(scheme: NLTagScheme, from text: String) throws -> Result<String, Error> {
        let model = try NLModel(mlModel: ReportClassifier().model)
        return .success(model.predictedLabel(for: text) ?? "Fuck")
    }

    func analyse(scheme: NLTagScheme, from text: String) -> Result<Analysis, Error> {
        guard text.isEmpty == false else { return .failure(Error.emptyText) }
        let fullRange = text.startIndex..<text.endIndex
        tagger.string = text
        tagger.setLanguage(.english, range: fullRange)

        let options: NLTagger.Options =  [
            .joinNames,
            .omitWhitespace,
            .omitPunctuation,
            .joinContractions,
            .omitOther]

        let tags: [Tag] = tagger.tags(in: fullRange, unit: .word, scheme: .nameTypeOrLexicalClass, options: options)
            .compactMap {
                guard let tag = $0.0 else { return nil }
                switch tag {
                case .personalName, .organizationName, .placeName, .noun, .adverb, .verb, .particle:
                    return Tag(result: (tag, $0.1), from: text, unit: .word)
                default:
                    return nil
                }
            }

        return .success(Analysis(tags: tags))
    }

    func associate(analysis: Analysis, from text: String) -> [Association] {
        let people = analysis.tags.filter({ $0.tag == .personalName })

        return people.map { person in

            let delimiters = [".", "?"]

            let startOfSentence = text[..<person.range.lowerBound].lastIndex(where: {
                delimiters.contains(String($0))
            }) ?? text.startIndex
            let endOfSentence = text[person.range.upperBound...].firstIndex(where: {
                delimiters.contains(String($0))
            }) ?? text.endIndex

            let entityClassifier = try! NLModel(mlModel: EntityClassifier().model)
            let range = text.rangeOfComposedCharacterSequences(for: startOfSentence..<endOfSentence)
            let foundText = String(text[range])

            let classifcation = entityClassifier.predictedLabel(for: foundText) ?? "Unclassified"
            return Association(name: person.value, type: classifcation)
        }
    }
}

public struct Association: CustomStringConvertible {
    let name: String
    let type: String

    public var description: String {
        return "\(name.capitalized) is the \(type.capitalized)"
    }
}

public struct Tag: CustomStringConvertible {
    public typealias TagResult = (tag: NLTag, range: Range<String.Index>)

    let value: String
    let tag: NLTag
    let unit: NLTokenUnit
    let range: Range<String.Index>

    init(result: TagResult, from text: String, unit: NLTokenUnit) {
        self.tag = result.tag
        self.value = String(text[result.range])
        self.unit = unit
        self.range = result.range
    }

    public var description: String {
        return "Tag: \(tag.rawValue.capitalized): - Value: \(value)\n"
    }
}

public struct Classification {

}

public struct Analysis {
    let tags: [Tag]
    
    public func colour(for tag: NLTag) -> UIColor? {
        switch tag {
        case .personalName: return UIColor.green.withAlphaComponent(0.3)
        case .placeName: return UIColor.blue.withAlphaComponent(0.3)
        case .organizationName: return UIColor.orange.withAlphaComponent(0.3)
        case .noun: return UIColor.red.withAlphaComponent(0.3)
        default: return nil
        }
    }

    public func font(for tag: NLTag) -> UIFont {
        switch tag {
        case .personalName: return UIFont.boldSystemFont(ofSize: 30.0)
        case .placeName: return UIFont.boldSystemFont(ofSize: 25.0)
        case .organizationName: return UIFont.boldSystemFont(ofSize: 22.0)
        case .noun: return UIFont.boldSystemFont(ofSize: 20.0)
        default: return UIFont.boldSystemFont(ofSize: 17.0)
        }
    }

    func attributedText(from text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text, attributes: [.font : UIFont.systemFont(ofSize: 17)])
        tags.forEach {
            if let colour = colour(for: $0.tag) {
                let range = $0.range
                let nsRange = NSRange(range.lowerBound..<range.upperBound, in: text)
                attributed.addAttributes([
                    .backgroundColor : colour,
                    .font : font(for: $0.tag)
                ], range: nsRange)
            }
        }
        return attributed
    }
}

