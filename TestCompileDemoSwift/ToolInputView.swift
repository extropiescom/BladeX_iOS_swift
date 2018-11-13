//
//  ToolInputView.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/5.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit

extension UIView {
    var top: CGFloat {
        get {
            return self.frame.origin.y
        }
        
        set {
            self.frame.origin.y = newValue
        }
    }
    
    var height: CGFloat {
        get {
            return self.frame.size.height
        }
        
        set {
            self.frame.size.height = newValue
        }
    }
}


class ToolInputView: UIView {

    let SCREEN_WIDTH = UIScreen.main.bounds.width
    let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    
    var bgView:UIView
    var inputtingView:UIView
    var confirmButton:UIButton
    var inputTextField:UITextField
    
    var inputViewCallBack:((_ text: String) -> () )?
    
    class func toolInputViewWithCallback(callback: ((_ text: String) -> () )?) -> ToolInputView {
        let view = ToolInputView.init(inputViewCallBack: callback)
        return view
    }
    
    private init(inputViewCallBack : ((_ text: String) -> () )?) {
        self.inputViewCallBack = inputViewCallBack
        bgView = UIView.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        
        
        inputtingView = UIView.init(frame: CGRect.init(x: CGFloat(0), y: SCREEN_HEIGHT - 200, width: SCREEN_WIDTH, height: CGFloat(50)))
        
        
        inputTextField = UITextField.init(frame: CGRect.init(x: CGFloat(10), y: CGFloat(10), width: SCREEN_WIDTH - 90, height: CGFloat(30)))
        
        confirmButton = UIButton.init(type: .custom)
        
        
        
        
        
        super.init(frame: CGRect.zero)
        
        bgView.backgroundColor = UIColor.init(white: CGFloat(0), alpha: CGFloat(0.3))
        UIApplication.shared.keyWindow?.addSubview(bgView)
        bgView.addSubview(inputtingView)
        
        inputtingView.backgroundColor = UIColor.white
        
        confirmButton.frame = CGRect.init(x: SCREEN_WIDTH - 80, y: CGFloat(5), width: CGFloat(70), height: CGFloat(40))
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.backgroundColor = UIColor.blue
        confirmButton.addTarget(self, action: #selector(confirmButtonPressed(_:)), for: .touchUpInside)
        
        inputtingView.addSubview(inputTextField)
        inputtingView.addSubview(confirmButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillAppear(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        inputTextField.becomeFirstResponder()
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func keyBoardWillAppear(notification: Notification) {
        let userInfo = notification.userInfo! as NSDictionary
        let keyboardEndingUncorrectedFrame = (userInfo[UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue
        let keyboardEndingFrame = convert(keyboardEndingUncorrectedFrame!, from: nil)
        
        self.inputtingView.top = SCREEN_HEIGHT-self.inputtingView.height-keyboardEndingFrame.size.height
    }
    
    @objc func confirmButtonPressed(_ sender: UIButton) {
        if let callback = inputViewCallBack {
            callback(inputTextField.text!)
        }
        self.bgView.removeFromSuperview()
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    

}
