//
//  InputViewController.swift
//  CMMotionDemo
//
//  Created by Admin on 9/18/18.
//  Copyright © 2018 PJTechGroup. All rights reserved.
//

import UIKit

class InputViewController: UIViewController, DropDownMenuDelegate {
    
    @IBOutlet weak var verticalDegreeInput: UITextField! {
        didSet { verticalDegreeInput?.addDoneCancelToolbar() }
    }
    @IBOutlet weak var horizontalDegreeTextField: UITextField! {
        didSet { horizontalDegreeTextField?.addDoneCancelToolbar() }
    }
    
    @IBOutlet weak var nextButton: UIButton!
    
    
    @IBOutlet var hdrSwitchView: UISwitch!
    @IBOutlet var exposureDropDownMenu: DropDownMenu!
    @IBOutlet var whitebalanceDropDownMenu: DropDownMenu!
    @IBOutlet var focusDropDownMenu: DropDownMenu!
    
    var exposureOptions = [String]()
    var whitebalanceOptions = [String]()
    var focusOptions = [String]()
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exposureOptions =  ["locked", "autoExpose", "continuousAutoFocus", "custom"]
        exposureDropDownMenu.options = exposureOptions
        exposureDropDownMenu.showBorder = true
        exposureDropDownMenu.delegate = self
        exposureDropDownMenu.hiddenButton.isEnabled = false
        exposureDropDownMenu.contentTextField.adjustsFontSizeToFitWidth = true
        
        whitebalanceOptions = ["locked", "autoWhiteBalance", "continuousAutoWhiteBalance"]
        whitebalanceDropDownMenu.options = whitebalanceOptions
        whitebalanceDropDownMenu.showBorder = true
        whitebalanceDropDownMenu.delegate = self
        whitebalanceDropDownMenu.hiddenButton.isEnabled = false
        whitebalanceDropDownMenu.contentTextField.adjustsFontSizeToFitWidth = true
        
        focusOptions = ["locked", "autoFocus", "continuousAutoFocus"]
        focusDropDownMenu.options = focusOptions
        focusDropDownMenu.showBorder = true
        focusDropDownMenu.delegate = self
        focusDropDownMenu.hiddenButton.isEnabled = false
        focusDropDownMenu.contentTextField.adjustsFontSizeToFitWidth = true
        
        
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
    
    
    // MARK: - DropdownMenu Delegate
    func dropDownMenu(_ menu: DropDownMenu!, didChoose index: Int) {
        if menu == exposureDropDownMenu {
            menu.contentTextField.text = self.exposureOptions[index]
            appDelegate.Exposure = self.exposureOptions[index]
        } else if menu == whitebalanceDropDownMenu {
            menu.contentTextField.text = self.whitebalanceOptions[index]
            appDelegate.WhiteBalance = self.whitebalanceOptions[index]
        } else if menu == focusDropDownMenu {
            menu.contentTextField.text = self.focusOptions[index]
            appDelegate.Focus = self.focusOptions[index]
        }
    }
    
    func dropDownMenu(_ menu: DropDownMenu!, didInput text: String!) {
        //        print("\(menu) input text \(text)")
    }
    
    // MARK: - Switch Action
    
    @IBAction func isChanged(_ sender: UISwitch) {
        appDelegate.hdr = sender.isOn
    }
    
    
}


extension UITextField {
    func addDoneCancelToolbar(onDone: (target: Any, action: Selector)? = nil, onCancel: (target: Any, action: Selector)? = nil) {
        let onCancel = onCancel ?? (target: self, action: #selector(cancelButtonTapped))
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))
        
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            //            UIBarButtonItem(title: "Cancel", style: .plain, target: onCancel.target, action: onCancel.action),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    // Default actions:
    @objc func doneButtonTapped() { self.resignFirstResponder() }
    @objc func cancelButtonTapped() { self.resignFirstResponder() }
}

