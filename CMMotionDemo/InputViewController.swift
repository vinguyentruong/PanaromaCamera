//
//  InputViewController.swift
//  CMMotionDemo
//
//  Created by David Nguyen Truong on 9/18/18.
//  Copyright © 2018 David Nguyen Truong. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {
    
    @IBOutlet weak var verticalDegreeInput: UITextField!
    @IBOutlet weak var horizontalDegreeTextField: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func nextAction(_ sender: Any) {
        guard
            let horizontalDegree = Double(horizontalDegreeTextField.text ?? ""),
            let verticalDegree = Double(verticalDegreeInput.text ?? ""),
            horizontalDegree < 360.0,
            horizontalDegree > 0,
            verticalDegree < 360.0,
            verticalDegree > 0,
            let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as? ViewController else {
            return
        }
        mainView.verticalDegreeUnit = verticalDegree
        mainView.horizontalDegreeUnit = horizontalDegree
        navigationController?.pushViewController(mainView, animated: true)
    }
}
