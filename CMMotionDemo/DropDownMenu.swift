//
//  DropDownMenu.swift
//  CMMotionDemo
//
//  Created by Admin on 20/09/2018.
//  Copyright © 2018 PJTechGroup. All rights reserved.
//

import Foundation
import UIKit

public protocol DropDownMenuDelegate:class{
    func dropDownMenu(_ menu:DropDownMenu!, didInput text:String!)
    func dropDownMenu(_ menu:DropDownMenu!, didChoose index:Int)
}

@IBDesignable open class DropDownMenu: UIView, UITableViewDataSource ,UITableViewDelegate,UITextFieldDelegate{
    
    public weak var delegate:DropDownMenuDelegate?
    
    public var inputClosure: ((DropDownMenu , _ text: String) ->Void )?
    
    public var chooseClosure: ((DropDownMenu , _ index: Int) ->Void )?
    
    public var options:Array<String> = [] {
        didSet {
            reload()
        }
    }
    
    private var _rowHeight:CGFloat = 0
    public var rowHeight:CGFloat {
        get{
            if _rowHeight == 0{
                return self.frame.size.height
            }
            return _rowHeight
        }
        set{
            _rowHeight = newValue
            reload()
        }
    }
    
    private var _menuMaxHeight:CGFloat = 300
    public var menuHeight : CGFloat{
        get {
            if _menuMaxHeight == 0{
                return CGFloat(self.options.count) * self.rowHeight
            }
            return min(_menuMaxHeight, CGFloat(self.options.count) * self.rowHeight)
        }
        set {
            _menuMaxHeight = newValue
            reload()
        }
    }
    
    @IBInspectable public var editable:Bool = false {
        didSet {
            contentTextField.isEnabled = editable
        }
    }
    
    @IBInspectable public var buttonImage:UIImage?{
        didSet {
            pullDownButton.setImage(buttonImage, for: UIControlState())
        }
    }
    
    @IBInspectable public var placeholder:String? {
        didSet {
            contentTextField.placeholder = placeholder
        }
    }
    
    @IBInspectable public var defaultValue:String? {
        didSet {
            contentTextField.text = defaultValue
        }
    }
    
    @IBInspectable public var textColor:UIColor?{
        didSet {
            contentTextField.textColor = textColor
        }
    }
    
    public var font:UIFont?{
        didSet {
            contentTextField.font = font
        }
    }
    
    public var showBorder:Bool = true {
        didSet {
            if showBorder {
                layer.borderColor = UIColor.lightGray.cgColor
                layer.borderWidth = 0.5
                layer.masksToBounds = true
                layer.cornerRadius = 2.5
            }else {
                layer.borderColor = UIColor.clear.cgColor
                layer.masksToBounds = false
                layer.cornerRadius = 0
                layer.borderWidth = 0
            }
        }
    }
    
    private lazy var optionsList:UITableView = {
        let table = UITableView(frame: CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.size.height, width: self.frame.size.width, height: 0), style: .plain)
        table.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        table.dataSource = self
        table.delegate = self
        table.layer.borderColor = UIColor.lightGray.cgColor
        table.layer.borderWidth = 0.5
        self.superview?.addSubview(table)
        return table
    }()
    
    private var isShown:Bool = false
    
    public var contentTextField:UITextField!
    
    private var pullDownButton:UIButton!
    public var hiddenButton : UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        contentTextField = UITextField(frame: CGRect.zero)
        contentTextField.delegate = self
        contentTextField.isEnabled = false
        addSubview(contentTextField)
        
        pullDownButton = UIButton(type: .custom)
        pullDownButton.addTarget(self, action: #selector(DropDownMenu.showOrHide), for: .touchUpInside)
        addSubview(pullDownButton)
        
        hiddenButton = UIButton(type: .custom)
        hiddenButton.addTarget(self, action: #selector(DropDownMenu.showOrHide), for: .touchUpInside)
        addSubview(hiddenButton)
        
        self.showBorder = true
        self.textColor = UIColor.black
        self.font = UIFont.boldSystemFont(ofSize: 12)
    }
    
    @objc func showOrHide() {
        if isShown {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.pullDownButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi*2))
                self.optionsList.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.size.height-0.5, width: self.frame.size.width, height: 0)
            }, completion: { (finished) -> Void in
                if finished{
                    self.pullDownButton.transform = CGAffineTransform(rotationAngle: 0.0)
                    self.isShown = false
                }
            })
        } else {
            contentTextField.resignFirstResponder()
            optionsList.reloadData()
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.pullDownButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                self.optionsList.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.size.height-0.5, width: self.frame.size.width, height:self.menuHeight)
            }, completion: { (finished) -> Void in
                if finished{
                    self.isShown = true
                }
            })
        }
    }
    
    func reload() {
        if !self.isShown {
            return
        }
        optionsList.reloadData()
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.pullDownButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            self.optionsList.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.size.height-0.5, width: self.frame.size.width, height:self.menuHeight)
        })
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        contentTextField.frame = CGRect(x: 15, y: 5, width: self.frame.size.width - 50, height: self.frame.size.height - 10)
        pullDownButton.frame = CGRect(x: self.frame.size.width - 35, y: 5, width: 30, height: 30)
        hiddenButton.frame = CGRect(x: 15, y: 5, width: self.frame.size.width - 50, height: self.frame.size.height - 10)
        
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text {
            self.delegate?.dropDownMenu(self, didInput: text)
            self.inputClosure?(self, text)
        }
        return true
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = font
        cell.textLabel?.textColor = textColor
        
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.rowHeight
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        contentTextField.text = options[indexPath.row]
        self.delegate?.dropDownMenu(self, didChoose:indexPath.row)
        self.chooseClosure?(self, indexPath.row)
        showOrHide()
    }
    
}
