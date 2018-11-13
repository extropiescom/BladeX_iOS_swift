//
//  TextFieldViewAlert.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/5.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit

class TextFieldViewAlert: NSObject {
    var buttonPressed:Bool = false
    var minLengthRequired:Int = 0
    var maxLengthRequired:Int = 0
    
    var currentRunLoop:CFRunLoop
    var secureTextAlertAction:UIAlertAction?
    
    var result:String? = nil
    
    init(minLengthRequired: Int, maxLengthRequired: Int) {
        self.minLengthRequired = minLengthRequired
        self.maxLengthRequired = maxLengthRequired
        currentRunLoop = CFRunLoopGetCurrent()
        secureTextAlertAction = nil
        super.init()
    }
    
    class func doModal(parent: UIViewController, title: String, message: String, isPassword: Bool, minLengtRequired: Int, maxLengtRequired: Int, keyBoardType: UIKeyboardType) -> String? {
        var result:String? = nil
        let view = TextFieldViewAlert.init(minLengthRequired: minLengtRequired, maxLengthRequired: maxLengtRequired)
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField) in
            NotificationCenter.default.addObserver(view, selector: #selector(handleTextFieldTextDidChangeNotification(notification:)), name: Notification.Name.UITextFieldTextDidChange, object: textField)
            textField.keyboardType = keyBoardType
            textField.isSecureTextEntry = isPassword
        }
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: .cancel) { (action: UIAlertAction) in
            NotificationCenter.default.removeObserver(self, name: Notification.Name.UITextFieldTextDidChange, object: alertController.textFields?.first)
            view.buttonPressed = true
            result = nil
            CFRunLoopStop(view.currentRunLoop)
        }
        let otherAction = UIAlertAction.init(title: otherButtonTitle, style: .default) { (action: UIAlertAction) in
            NotificationCenter.default.removeObserver(self, name: Notification.Name.UITextFieldTextDidChange, object: alertController.textFields?.first)
            view.buttonPressed = true
            result = (alertController.textFields?.first?.text)!
            CFRunLoopStop(view.currentRunLoop)
        }
        otherAction.isEnabled = false
        view.secureTextAlertAction = otherAction
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        parent.present(alertController, animated: true, completion: nil)
        while !(view.buttonPressed) {
            CFRunLoopRun()
        }
        
        
        return result
    }
    
    @objc func handleTextFieldTextDidChangeNotification(notification:Notification) {
        let textField:UITextField = notification.object as! UITextField;
        
        // Enforce a minimum length of >= 5 characters for secure text alerts.
        self.secureTextAlertAction!.isEnabled = (textField.text!.count >= self.minLengthRequired && textField.text!.count <= self.maxLengthRequired)
    }
    

}
