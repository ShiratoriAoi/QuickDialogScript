//
//  ViewController.swift
//  QuickDialogScript
//
//  Created by Aoi SHIRATORI on 04/15/2022.
//  Copyright (c) 2022 Aoi SHIRATORI. All rights reserved.
//

import UIKit
import QuickDialogScript
import QuickDialog

class ViewController: UIViewController {
    var manager: QDSNavigationControllerManager! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let rect = CGRect(x: 20, y: 50, width: 300, height: 100)
        let btn = UIButton(frame: rect)
        let sel = #selector(pushed) 
        btn.setTitle("Open QuickDialog by text.", for: .normal)
        btn.setTitleColor(UIColor.blue, for: .normal)
        btn.addTarget(self, action: sel, for: .touchUpInside)
        view.addSubview(btn)
    }

    @objc func pushed() {
        manager = QDSNavigationControllerManager(scriptFilename: "Example")
        manager.delegate = self
        let vc = manager.navigationController
        modalPresentationStyle = .pageSheet
        present(vc, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController : QDSDelegate {
    func valueChanged(element: QElement, tag: Int) {
        if tag == 200 {
            print(element)
        }
    }
    
    func actionFired(tag: Int) {
        print("user \(tag) pushed.")
    }
    
    //return QElement
    //see documentation for QuickDialog
    func generateElement(tag: Int) -> QElement {
        if tag == 200 {
            let bool = QBooleanElement(title:"This value is ignored.", boolValue: false)!
            return bool
        } else {
            let elm = QLabelElement(title: "user \(tag)", value: nil)!
            return elm
        }
    }
    
    //return QSection
    //see documentation for QuickDialog
    func generateSection(key: String) -> QSection? {
        if key == "user_section" {
            let section = QSection(title: "User Section")!
            let elm = QLabelElement(title: "This label is created dynamically by delegatee.", value: nil)!
            section.addElement(elm)
            return section
        }
        return nil
    }
    
    func willMove(to quickDialogController: QuickDialogController, key: String) {
        //no process
    }
}
