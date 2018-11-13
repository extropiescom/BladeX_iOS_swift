//
//  PickerViewAlert.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/5.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit

class PickerViewAlert: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var selectedRow:Int
    var buttonPressed:Bool
    var picker:UIPickerView
    var currentRunLoop:CFRunLoop
    var myDataSource:Array<String>
    
    class func doModal(parent:UIViewController, title:String, dataSource:Array<String>) -> Int {
        var result:Int = 0
        let message = "\n\n\n\n\n\n\n"
        let sheet = UIAlertController.init(title: title, message: message, preferredStyle: .actionSheet)
        let pickerX = CGFloat(0)
        let pickerY = CGFloat(60)
        let pickerW = sheet.view.frame.size.width - 20
        let pickerH = CGFloat(7*20+10)
        let view = PickerViewAlert.init(dataSource: dataSource, frame: CGRect.init(x: pickerX, y: pickerY, width: pickerW, height: pickerH))
        sheet.addAction(UIAlertAction.init(title: "Confirm", style: .default, handler: { (action: UIAlertAction) in
            view.buttonPressed = true
            result = view.selectedRow
            CFRunLoopStop(view.currentRunLoop)
        }))
        sheet.addAction(UIAlertAction.init(title: "Cancel", style: .default, handler: { (action: UIAlertAction) in
            result = -1
            view.buttonPressed = true
            CFRunLoopStop(view.currentRunLoop)
        }))
        
        //let label = UILabel.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: pickerW, height: CGFloat(40)))
        //label.text = title
        //sheet.view.addSubview(label)
        view.picker.backgroundColor = UIColor.init(red: CGFloat(247/255.0), green:  CGFloat(247/255.0), blue:  CGFloat(247/255.0), alpha: CGFloat(1))
        view.picker.delegate = view
        view.picker.dataSource = view
        sheet.view.addSubview(view.picker)
        view.picker.selectRow(0, inComponent: 0, animated: true)
        parent.present(sheet, animated: true, completion: nil)
        while !(view.buttonPressed) {
            CFRunLoopRun()
        }
        
        return result
    }
    
    init(dataSource:Array<String>, frame:CGRect) {
        selectedRow = 0
        buttonPressed = false
        myDataSource = dataSource
        picker = UIPickerView.init(frame: frame)
        currentRunLoop = CFRunLoopGetCurrent()
        super.init()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return myDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return myDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
    }
    

}
