//
//  ViewController.swift
//  ACAnalyser
//
//  Created by QHMW64 on 28/8/19.
//  Copyright © 2019 Gridstone. All rights reserved.
//

import IntentsUI
import UIKit

class TextInputViewController: UIViewController {

    private let analyser = NarrativeAnalyser()

    @IBOutlet weak var textView: UITextView!

    private var text: String {
        return textView.text
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = self

        let intent = CreateReportIntent()
        intent.suggestedInvocationPhrase = "Create Report"

        let interaction = INInteraction(intent: intent, response: nil)

        interaction.donate { (error) in
            if error != nil {

            }
            print("wooo")
        }
    }

    private func analyse() {

        let classification = try! analyser.classify(scheme: .nameType, from: text)
        print(try! classification.get())

        let result = analyser.analyse(scheme: .nameType, from: text)
        switch result {
        case .success(let analysis):
            textView.attributedText = analysis.attributedText(from: text)
            print(analyser.associate(analysis: analysis, from: text))
        case .failure(let error):
            let alertController = UIAlertController(title: "Shit", message: "Something went wrong!\n\(error.localizedDescription)", preferredStyle: .alert)
            let action = UIAlertAction(title: "Thanks for nothing.", style: .default, handler: nil)
            alertController.addAction(action)
            present(alertController, animated: true, completion: nil)
        }
    }

}

extension TextInputViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        guard textView.text.isEmpty != true else { return }
        analyse()
    }

}
