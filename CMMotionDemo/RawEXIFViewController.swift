//
//  RawEXIFViewController.swift
//  photo-investigator
//
//  Created by Bá Anh Nguyễn on 5/30/18.
//  Copyright © 2018 naApps. All rights reserved.
//

import UIKit
import Photos

class RawEXIFViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    var rawEXIF: String?
    private var fileUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Raw data"
        textView.text = rawEXIF ?? "No Data"
        prepareNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        guard let url = fileUrl else {
            return
        }
        do {
            try FileManager.default.removeItem(at: url)
        }catch(let err){
            print(err.localizedDescription)
        }
    }
}

extension RawEXIFViewController {
    
    private func prepareNavigationBar() {
        let rightItemButton = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handelRightBarButton))
        navigationItem.rightBarButtonItem = rightItemButton
    }
    
    @objc private func handelRightBarButton() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM_dd_yyyy_hh_mm_aa"
        let file = "\(dateFormatter.string(from: date)).txt"
        guard let text = rawEXIF else { return  }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else{
            return
        }
        fileUrl = dir.appendingPathComponent(file)
        do {
            try text.write(to: fileUrl!, atomically: false, encoding: .utf8)
        }
        catch {
            print(error.localizedDescription)
        }
        let sharer = UIActivityViewController(activityItems: [fileUrl!], applicationActivities: nil)
        sharer.popoverPresentationController?.sourceView = self.view
        self.present(sharer, animated: true, completion: nil)
    }
}
