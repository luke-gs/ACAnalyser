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

        navigationItem.largeTitleDisplayMode = .always
        let analyseButton = UIBarButtonItem(title: "Analyse", style: .plain, target: self, action: #selector(analyse))
        analyseButton.isEnabled = false
        navigationItem.rightBarButtonItem = analyseButton
    }

    @objc private func analyse() {

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

    func setupIntents() {
        let activity = NSUserActivity(activityType: "createReport")
    }

}

extension TextInputViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        navigationItem.rightBarButtonItem?.isEnabled = textView.text.isEmpty == false
    }

}
