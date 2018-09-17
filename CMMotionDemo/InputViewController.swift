//
//  InputViewController.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/18/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {

    @IBOutlet weak var verticalDegreeTextField: UITextField!
    @IBOutlet weak var horizontalDegreeTextField: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func nextAction(_ sender: Any) {
        guard
        let verticalDegree = Double(verticalDegreeTextField.text ?? ""),
        let horizontalDegree = Double(horizontalDegreeTextField.text ?? "") else {
            return
        }
        guard let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController else {
            return
        }
        mainView.verticalDegreeUnit = verticalDegree
        mainView.horizontalDegreeUnit = horizontalDegree
        navigationController?.pushViewController(mainView, animated: true)
    }
}
