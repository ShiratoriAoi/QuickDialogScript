//
//  QDScriptNavigationController.swift
//
//  Created by ShiratoriAoi on 2018/04/07.
//  Copyright © 2018年 ShiratoriAoi. All rights reserved.
//

import UIKit
import QuickDialog
import FootlessParser

@objc public protocol QDSDelegate : AnyObject{
    func actionFired(tag: Int)
    func generateElement(tag: Int) -> QElement
    func generateSection(key: String) -> QSection?
    func valueChanged(element: QElement, tag: Int)
    @objc optional func willMove(to quickDialogController: QuickDialogController, key: String)
}

extension QDSDelegate {
    func actionFired(tag: Int) {
        //no process
    }
    
    func generateElement(tag: Int) -> QElement {
        let elm = QLabelElement(title: "QDSDelegate.generateElement tag=\(tag)", value: nil)!
        return elm
    }
    
    func generateSection(nav: UINavigationController, key: String) -> QSection? {
        return nil
    }

    func valueChanged(element: QElement, tag: Int) {
        print(element, tag)
    }
}

public class QDSNavigationControllerManager {
    //private variables
    private let qds: [QDSRoot]
    private var elementDic: [Int: QElement] = [:]
    private var _navigationController: UINavigationController? = nil
    
    //variables
    public weak var delegate: QDSDelegate? = nil

    //accessor
    public var navigationController: UINavigationController {
        if let nav = _navigationController {
            return nav
        } else {
            let qdc = generateDialog(key: "launch")
            let nav = UINavigationController(rootViewController: qdc)
            _navigationController = nav
            return nav
        }
    }

    public var rootQDC : QuickDialogController {
        return navigationController.viewControllers[0] as! QuickDialogController
    }

    //accessor
    public func element(tag: Int) -> QElement? {
        return elementDic[tag]
    }
    
    //initliaze
	public init(scriptFilename: String) {
        if let path = Bundle.main.path(forResource: scriptFilename, ofType: "qds"){
            let fileURL = URL(fileURLWithPath: path)
            print("fileURL: \(fileURL)")
            do {
                let manager = QDSParserManager()
                
                let text = try String(contentsOf: fileURL, encoding: .utf8)
                let words = try parse(manager.wordParser, text)
                print("successed word parsing, filename: \(scriptFilename)")
                
                qds = try parse(manager.qdsParser, words)
            } catch {
                qds = []
                print("failed reading \(scriptFilename) in QDSParserManager.init")
            }
        } else {
            qds = []
            print("failed in QDSParserManager.init")
        }
	}

    //dialog generator
    //fukusayou: elementDic ni element wo touroku 
    fileprivate func generateDialog(key: String) -> QuickDialogController {
        let rootdataOrNil = qds.filter(){ $0.key == key }.first
        guard let rootdata = rootdataOrNil else {
            print("key \(key) is not found in generateDialog")
            return QuickDialogController()
        }
        let root = QRootElement()!
        root.title = rootdata.title
        root.grouped = true
        
        //quick dialog controller
        let qdc = QuickDialogController(forRoot: root)!

        //element generator
        func generateElement(data: QDSElement) -> (QElement, Int) {
            switch data {
            case .Button(let title, let action, let tag):
                let btn = QButtonElement(title: title)!

                btn.onSelected = { [unowned self] in
                    self.actionFired(action: action, tag: tag)
                }
                return (btn, tag)
            case .Label(let title, let action, let tag):
                let lbl = QLabelElement(title: title, value: nil)!
                if case QDSAction.none = action {
                    //no process
                } else {
                    lbl.onSelected = { [unowned self] in
                        self.actionFired(action: action, tag: tag)
                    }
                }
                return (lbl, tag)
            case .Arrow(let title, let action, let tag):
                let lbl = QLabelElement(title: title, value: nil)!
                lbl.accessoryType = .disclosureIndicator
                if case QDSAction.none = action {
                    //no process
                } else {
                    lbl.onSelected = { [unowned self] in
                        self.actionFired(action: action, tag: tag)
                    }
                }
                return (lbl, tag)
            case .Icon(let title, let filename, let action, let tag):
                let btn = QLabelElement(title: title, value: nil)!
                btn.imageNamed = filename as NSString
                btn.onSelected = { [unowned self] in
                    self.actionFired(action: action, tag: tag)
                }
                return (btn, tag)
            case .Bool(let title, let manipulation, let tag):
                if case QDSManipulation.ud(let key) = manipulation {
                    let ud = UserDefaults.standard
                    let old = ud.bool(forKey: key)
                    let bool = QBooleanElement(title: title, boolValue: old)!
                    bool.onSelected = { 
                        let new = bool.boolValue
                        ud.set(new, forKey: key)
                    }
                    return (bool, tag)
                } else if case QDSManipulation.user = manipulation {
                    let bool = QBooleanElement(title: title, boolValue: false)!
                    bool.onSelected = {
                        self.delegate?.valueChanged(element: bool, tag: tag)
                    }
                    return (bool, tag)
                }
            case .Float(let title, let manipulation, let tag):
                if case QDSManipulation.ud(let key) = manipulation {
                    let ud = UserDefaults.standard
                    let old = ud.float(forKey: key)
                    let float = QFloatElement(title: title, value: old)!
                    float.minimumValue = 0
                    float.maximumValue = 1.0
                    float.onValueChanged = { (_: QRootElement?) in
                        let new = float.floatValue
                        ud.set(new, forKey: key)
                        print(new)
                    }
                    return (float, tag)
                } else if case QDSManipulation.user = manipulation {
                    let float = QFloatElement(title: title, value: Float(0))!
                    float.minimumValue = 0
                    float.maximumValue = 1.0
                    float.onValueChanged = { _ in
                        self.delegate?.valueChanged(element: float, tag: tag)
                    }
                    return (float, tag)
                }
            case .Text(let filename):
                let tmp = filename.components(separatedBy: ".")
                if let path = Bundle.main.path(forResource: tmp[0], ofType: tmp[1]){
                    do {
                        let url = URL(fileURLWithPath: path)
                        let text = try String(contentsOf: url)
                        let elm = QTextElement(text: text)!
                        return (elm, 0)
                    } catch {
                        let err = QLabelElement(title: "filename error", value: nil)!
                        return (err, 0)
                    }
                }
            case .TextPage(let title, let filename):
                let tmp = filename.components(separatedBy: ".")
                if let path = Bundle.main.path(forResource: tmp[0], ofType: tmp[1]){
                    do {
                        let url = URL(fileURLWithPath: path)
                        let text = try String(contentsOf: url)
                        let elm = QTextElement(text: text)!

                        let root = QRootElement()!
                        root.grouped = true
                        let sec = QSection(title: "")!
                        root.addSection(sec)
                        sec.addElement(elm)
                        let qdc = QuickDialogController(forRoot: root)!

                        let lbl = QLabelElement(title: title, value: nil)!
                        lbl.accessoryType = .disclosureIndicator
                        lbl.onSelected = { [unowned self] in
                            self._navigationController?.pushViewController(qdc, animated: true)
                        }
                        return (lbl, 0)
                    } catch {
                        let err = QLabelElement(title: "filename error", value: nil)!
                        return (err, 0)
                    }
                }
            case .User(let tag):
                var elm = delegate?.generateElement(tag: tag)
                if elm == nil {
                    elm = QLabelElement(title: "sqdnc delegate nil", value: nil)!
                }
                return (elm!, tag)
            }
            
            let err = QLabelElement(title: "unknown error", value: nil)!
            return (err, 0)
        }

        //generate process
        for aSection in rootdata.sections {
            switch aSection{
            case .Script(let title, let elements):
                let sec = QSection(title: "")!
                sec.title = title
                root.addSection(sec)
                for aElementData in elements {
                    let (elm, tag) = generateElement(data: aElementData)
                    sec.addElement(elm)
                    if tag != 0 {
                        elementDic[tag] = elm
                    }
                }
            case .User(let key):
                if delegate != nil {
                    if let sec = delegate!.generateSection(key: key) {
                        root.addSection(sec)
                    } else {
                        print("sqdnc section undefined key: \(key)")
                    }
                }else{
                    print("sqdnc delegate nil: user section failed")
                }
            }
        }

        return qdc
    }

    //callback for action
    fileprivate func actionFired(action: QDSAction, tag: Int) {
        switch action {
        case .url(let str):
            let url = URL(string: str)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .dismiss:
            _navigationController?.dismiss(animated: true, completion: nil)
        case .none:
            break
        case .sub(let str):
            let qdc = generateDialog(key: str)
            delegate?.willMove?(to: qdc, key: str)
            _navigationController?.pushViewController(qdc, animated: true)
        case .user:
            delegate?.actionFired(tag: tag)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


