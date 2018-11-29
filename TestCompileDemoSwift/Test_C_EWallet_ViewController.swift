//
//  Test_C_EWallet_ViewController.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/2.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit
import Swift

var ewalletClass:Test_C_EWallet_ViewController? = nil
typealias AbortHandelBlock = ((_ abortState: Bool) -> ())

class Test_C_EWallet_ViewController: UIViewController {
    let puiDerivePathEOS: [CUnsignedInt] = [0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000]
    
    let in_outTextView: UITextView
    
    let categoryList: [UIButton]
    let deviceCategoryBtn: UIButton
    let fPrintCategoryBtn: UIButton
    let initCategoryBtn: UIButton
    let walletCategoryBtn: UIButton
    let deviceCategoryList: [UIButton]
    let fPrintCategoryList: [UIButton]
    let initCategoryList: [UIButton]
    let walletCategoryList: [UIButton]
    let allList: [[UIButton]]
    
    let getDevInfoBtn: UIButton
    let initPinBtn: UIButton
    let verifyPinBtn: UIButton
    let changePinBtn: UIButton
    let formatBtn: UIButton
    let clearScreenBtn: UIButton
    let freeContextBtn: UIButton
    let powerOffBtn: UIButton
    
    let getFPListBtn: UIButton
    let enrollFPBtn: UIButton
    let verifyFPBtn: UIButton
    let deleteFPBtn: UIButton
    let calibrateFPBtn: UIButton
    let abortBtn: UIButton
    
    let genSeedBtn: UIButton
    let importMNEBtn: UIButton
    
    let getAddressBtn: UIButton
    let signAbortBtn: UIButton
    let eosSignBtn: UIButton
   
    let clearLogBtn: UIButton
    
    var inputtingView: ToolInputView?
    
    var deviceContext: UnsafeMutableRawPointer?
    
    var logCounter = 0
    var lastSignState: Int32 = PAEW_RET_SUCCESS
    var authTypeCached = false
    var nAuthType: CUnsignedChar = CUnsignedChar(0xFF)
    var authTypeResult: CUnsignedInt = CUnsignedInt(PAEW_RET_SUCCESS)
    var pinCached = false
    var pin = ""
    var pinResult: CUnsignedInt = CUnsignedInt(PAEW_RET_SUCCESS)
    
    var abortBtnState: Bool = false
    var abortCondition: NSCondition

    var abortHandelBlock: AbortHandelBlock? = nil
    
    var examResult: String = ""
    
    var getAuthTypeCallback: tFunc_GetAuthType = {
        var rtn:UInt32 = PAEW_RET_DEV_OP_CANCEL
        if let selfClass = ewalletClass {
            if !(selfClass.authTypeCached) {
                _ = selfClass.getAuthType()
            }
            selfClass.authTypeCached = false
            rtn = selfClass.authTypeResult
            guard rtn == PAEW_RET_SUCCESS else {
                return Int32(bitPattern: rtn)
            }
            $1?.pointee = selfClass.nAuthType
        }
        return Int32(bitPattern: rtn)
    }
    
    var getPINCallback: tFunc_GetPIN = {
        var rtn: UInt32 = PAEW_RET_DEV_OP_CANCEL
        if let selfClass = ewalletClass {
            if !(ewalletClass!.pinCached) {
                _ = ewalletClass!.getPIN()
            }
            selfClass.pinCached = false
            rtn = ewalletClass!.pinResult
            guard rtn == PAEW_RET_SUCCESS else {
                return Int32(bitPattern: rtn)
            }
            $2!.pointee = ewalletClass!.pin.count
            memcpy($1, ewalletClass!.pin.cString(using: String.Encoding.utf8), ewalletClass!.pin.count)
        }
        return Int32(bitPattern: rtn)
    }
    
    var putSignStateCallback: tFunc_PutSignState = {
        var rtn: UInt32 = PAEW_RET_DEV_OP_CANCEL
        guard let selfClass = ewalletClass else {
            return Int32(bitPattern: rtn)
        }
        if ($1 != selfClass.lastSignState) {
            selfClass.printLog(Utils.errorCodeToString($1))
            selfClass.lastSignState = $1
        }
        //here is a good place to canel sign function
        if(selfClass.abortBtnState) {
            selfClass.abortCondition.lock()
            selfClass.abortHandelBlock!(true)
            //abortHandelBlock is a async implement
            //so must wait for signal which is send after PAEW_AbortFP
            selfClass.abortCondition.wait();
            selfClass.abortCondition.unlock()
            selfClass.abortBtnState = false
        }
        rtn = UInt32(PAEW_RET_SUCCESS)
        return Int32(bitPattern: rtn)
    }
    
    init(p:UnsafeMutableRawPointer) {
        deviceContext = p;
        getDevInfoBtn = UIButton.init(type: .custom)
        initPinBtn = UIButton.init(type: .custom)
        verifyPinBtn = UIButton.init(type: .custom)
        changePinBtn = UIButton.init(type: .custom)
        formatBtn = UIButton.init(type: .custom);
        clearScreenBtn = UIButton.init(type: .custom)
        freeContextBtn = UIButton.init(type: .custom)
        powerOffBtn = UIButton.init(type: .custom)
        
        getFPListBtn = UIButton.init(type: .custom)
        enrollFPBtn = UIButton.init(type: .custom)
        verifyFPBtn = UIButton.init(type: .custom)
        deleteFPBtn = UIButton.init(type: .custom)
        calibrateFPBtn = UIButton.init(type: .custom)
        abortBtn = UIButton.init(type: .custom)
        
        genSeedBtn = UIButton.init(type: .custom)
        importMNEBtn = UIButton.init(type: .custom)
        
        getAddressBtn = UIButton.init(type: .custom)
        signAbortBtn = UIButton.init(type: .custom)
        eosSignBtn = UIButton.init(type: .custom)
        
        clearLogBtn = UIButton.init(type: UIButtonType.custom)
        
        fPrintCategoryBtn = UIButton.init(type: .custom)
        initCategoryBtn = UIButton.init(type: .custom)
        walletCategoryBtn = UIButton.init(type: .custom)
        deviceCategoryBtn = UIButton.init(type: .custom)
        in_outTextView = UITextView.init()
        
        deviceCategoryList = [getDevInfoBtn, initPinBtn, verifyPinBtn, changePinBtn, formatBtn, clearScreenBtn, freeContextBtn, powerOffBtn]
        fPrintCategoryList = [getFPListBtn, enrollFPBtn, verifyFPBtn, deleteFPBtn, calibrateFPBtn, abortBtn]
        initCategoryList = [genSeedBtn, importMNEBtn]
        walletCategoryList = [getAddressBtn, eosSignBtn, signAbortBtn]
        categoryList = [deviceCategoryBtn, fPrintCategoryBtn, initCategoryBtn, walletCategoryBtn]
        allList = Array.init(arrayLiteral: deviceCategoryList, fPrintCategoryList, initCategoryList, walletCategoryList)
        
        abortCondition = NSCondition.init()
        
        super.init(nibName: nil, bundle: nil)
        
        ewalletClass = self
        
        deviceCategoryBtn.setTitle("Device", for: UIControlState.normal)
        deviceCategoryBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        deviceCategoryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        deviceCategoryBtn.backgroundColor = UIColor.lightGray
        deviceCategoryBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.categoryAction(sender:)), for: UIControlEvents.touchUpInside)
        
        fPrintCategoryBtn.setTitle("FPrint", for: UIControlState.normal)
        fPrintCategoryBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        fPrintCategoryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        fPrintCategoryBtn.backgroundColor = UIColor.lightGray
        fPrintCategoryBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.categoryAction(sender:)), for: UIControlEvents.touchUpInside)
        
        initCategoryBtn.setTitle("Init", for: UIControlState.normal)
        initCategoryBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        initCategoryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        initCategoryBtn.backgroundColor = UIColor.lightGray
        initCategoryBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.categoryAction(sender:)), for: UIControlEvents.touchUpInside)
        
        walletCategoryBtn.setTitle("Wallet", for: UIControlState.normal)
        walletCategoryBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        walletCategoryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        walletCategoryBtn.backgroundColor = UIColor.lightGray
        walletCategoryBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.categoryAction(sender:)), for: UIControlEvents.touchUpInside)
        
        in_outTextView.font = UIFont.init(name: "Arial", size: 12.5)
        in_outTextView.textColor = UIColor.init(red: CGFloat(51/255.0), green: CGFloat(51/255.0), blue: CGFloat(51/255.0), alpha: CGFloat(1.0))
        in_outTextView.backgroundColor = UIColor.white
        in_outTextView.textAlignment = NSTextAlignment.left
        in_outTextView.autocorrectionType = UITextAutocorrectionType.no
        in_outTextView.layer.borderColor = UIColor.green.cgColor
        in_outTextView.layer.borderWidth = 1;
        in_outTextView.layer.cornerRadius = 5;
        in_outTextView.autocapitalizationType = UITextAutocapitalizationType.none
        in_outTextView.keyboardType = UIKeyboardType.asciiCapable
        in_outTextView.returnKeyType = UIReturnKeyType.default
        in_outTextView.isScrollEnabled = true;
        in_outTextView.autoresizingMask = UIViewAutoresizing.flexibleHeight
        in_outTextView.isEditable = false;
        
        
        getDevInfoBtn.setTitle("GetDevInfo", for: UIControlState.normal)
        getDevInfoBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getDevInfoBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getDevInfoBtn.backgroundColor = UIColor.lightGray
        getDevInfoBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getDevInfoBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        initPinBtn.setTitle("InitPin", for: UIControlState.normal)
        initPinBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        initPinBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        initPinBtn.backgroundColor = UIColor.lightGray
        initPinBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.initPinBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        verifyPinBtn.setTitle("VerifyPin", for: UIControlState.normal)
        verifyPinBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        verifyPinBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        verifyPinBtn.backgroundColor = UIColor.lightGray
        verifyPinBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.verifyPinBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        changePinBtn.setTitle("ChangePin", for: UIControlState.normal)
        changePinBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        changePinBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        changePinBtn.backgroundColor = UIColor.lightGray
        changePinBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.changePinBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        formatBtn.setTitle("Format", for: UIControlState.normal)
        formatBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        formatBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        formatBtn.backgroundColor = UIColor.lightGray
        formatBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.formatBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        clearScreenBtn.setTitle("ClearScreen", for: UIControlState.normal)
        clearScreenBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        clearScreenBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        clearScreenBtn.backgroundColor = UIColor.lightGray
        clearScreenBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.clearScreenBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        freeContextBtn.setTitle("FreeContext", for: UIControlState.normal)
        freeContextBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        freeContextBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        freeContextBtn.backgroundColor = UIColor.lightGray
        freeContextBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.freeContextBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        powerOffBtn.setTitle("PowerOff", for: UIControlState.normal)
        powerOffBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        powerOffBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        powerOffBtn.backgroundColor = UIColor.lightGray
        powerOffBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.powerOffBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getFPListBtn.setTitle("GetFPList", for: UIControlState.normal)
        getFPListBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getFPListBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getFPListBtn.backgroundColor = UIColor.lightGray
        getFPListBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getFPListBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        enrollFPBtn.setTitle("EnrollFP", for: UIControlState.normal)
        enrollFPBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        enrollFPBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        enrollFPBtn.backgroundColor = UIColor.lightGray
        enrollFPBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.enrollFPBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        verifyFPBtn.setTitle("VerifyFP", for: UIControlState.normal)
        verifyFPBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        verifyFPBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        verifyFPBtn.backgroundColor = UIColor.lightGray
        verifyFPBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.verifyFPBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        deleteFPBtn.setTitle("DeleteFP", for: UIControlState.normal)
        deleteFPBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        deleteFPBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        deleteFPBtn.backgroundColor = UIColor.lightGray
        deleteFPBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.deleteFPBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        calibrateFPBtn.setTitle("CalibrateFP", for: UIControlState.normal)
        calibrateFPBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        calibrateFPBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        calibrateFPBtn.backgroundColor = UIColor.lightGray
        calibrateFPBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.calibrateFPBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        abortBtn.setTitle("Abort", for: UIControlState.normal)
        abortBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        abortBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        abortBtn.backgroundColor = UIColor.lightGray
        abortBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.abortBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        
        genSeedBtn.setTitle("GenSeed", for: UIControlState.normal)
        genSeedBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        genSeedBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        genSeedBtn.backgroundColor = UIColor.lightGray
        genSeedBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.genSeedBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        importMNEBtn.setTitle("ImportMNE", for: UIControlState.normal)
        importMNEBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        importMNEBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        importMNEBtn.backgroundColor = UIColor.lightGray
        importMNEBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.importMNEBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getAddressBtn.setTitle("GetAddress", for: UIControlState.normal)
        getAddressBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getAddressBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getAddressBtn.backgroundColor = UIColor.lightGray
        getAddressBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getAddressBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        signAbortBtn.setTitle("Abort", for: UIControlState.normal)
        signAbortBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        signAbortBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        signAbortBtn.backgroundColor = UIColor.lightGray
        signAbortBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.signAbortBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        eosSignBtn.setTitle("EOSSign", for: UIControlState.normal)
        eosSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        eosSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        eosSignBtn.backgroundColor = UIColor.lightGray
        eosSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.eosSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        clearLogBtn.setTitle("ClearLog", for: UIControlState.normal)
        clearLogBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        clearLogBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        clearLogBtn.backgroundColor = UIColor.lightGray
        clearLogBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.clearLogBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        
        self.abortHandelBlock =  { (abortState: Bool) in
            guard abortState else {
                return
            }
            DispatchQueue.global(qos: .default).async {
                let devIdx = 0
                guard let pPAEWContext = self.deviceContext else {
                    self.printLog("Device not connected, connect to device first")
                    return
                }
                self.abortBtnState = false
                self.printLog("ready to call PAEW_AbortFP")
                self.abortCondition.lock()
                let iRtn = PAEW_AbortFP(pPAEWContext, devIdx)
                self.abortCondition.signal()
                self.abortCondition.unlock()
                guard iRtn == PAEW_RET_SUCCESS else {
                    self.printLog("PAEW_AbortFP returns failed \(Utils.errorCodeToString(iRtn))")
                    return
                }
                self.printLog("PAEW_AbortFP returns success")
            }
            return
        }
    }
    
    func addSubViewAfterViewDidLoad() {
        self.view.addSubview(self.in_outTextView)
        self.in_outTextView.mas_makeConstraints({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.view.mas_top)?.offset()(10)
            make.left.mas_equalTo()(self.view.mas_left)?.offset()(10)
            make.right.mas_equalTo()(self.view.mas_right)?.offset()(-10)
            make.height.mas_equalTo()(self.view.mas_height)?.multipliedBy()(0.33)
        })
        self.in_outTextView.layoutManager.allowsNonContiguousLayout = false
        
        self.view.addSubview(deviceCategoryBtn)
        self.view.addSubview(fPrintCategoryBtn)
        self.view.addSubview(initCategoryBtn)
        self.view.addSubview(walletCategoryBtn)
        
        let catArr:NSArray = NSArray.init(arrayLiteral: deviceCategoryBtn, fPrintCategoryBtn, initCategoryBtn, walletCategoryBtn)
        catArr.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(1), leadSpacing: CGFloat(10), tailSpacing: CGFloat(10))
        catArr.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.in_outTextView.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        
        self.view.addSubview(getDevInfoBtn)
        self.view.addSubview(initPinBtn)
        self.view.addSubview(verifyPinBtn)
        self.view.addSubview(changePinBtn)
        self.view.addSubview(formatBtn)
        self.view.addSubview(clearScreenBtn)
        self.view.addSubview(freeContextBtn)
        self.view.addSubview(powerOffBtn)
        
        self.view.addSubview(getFPListBtn)
        self.view.addSubview(enrollFPBtn)
        self.view.addSubview(verifyFPBtn)
        self.view.addSubview(deleteFPBtn)
        self.view.addSubview(calibrateFPBtn)
        self.view.addSubview(abortBtn)
        
        self.view.addSubview(genSeedBtn)
        self.view.addSubview(importMNEBtn)
        
        self.view.addSubview(getAddressBtn)
        self.view.addSubview(signAbortBtn)
        self.view.addSubview(eosSignBtn)
        
        let cat1Arr1:NSArray = NSArray.init(arrayLiteral: getDevInfoBtn, initPinBtn, verifyPinBtn)
        cat1Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        let cat1Arr2:NSArray = NSArray.init(arrayLiteral: changePinBtn, formatBtn, clearScreenBtn)
        cat1Arr2.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr2.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.getDevInfoBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        let cat1Arr3:NSArray = NSArray.init(arrayLiteral: self.freeContextBtn, self.powerOffBtn)
        cat1Arr3.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr3.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.changePinBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        
        let cat2Arr1:NSArray = NSArray.init(arrayLiteral: self.getFPListBtn, self.enrollFPBtn, self.verifyFPBtn)
        cat2Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat2Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        let cat2Arr2:NSArray = NSArray.init(arrayLiteral: self.deleteFPBtn, self.calibrateFPBtn, self.abortBtn)
        cat2Arr2.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat2Arr2.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.getDevInfoBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        
        let cat3Arr1:NSArray = NSArray.init(arrayLiteral: self.genSeedBtn, self.importMNEBtn)
        cat3Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat3Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        
        let cat4Arr1:NSArray = NSArray.init(arrayLiteral: self.getAddressBtn, self.eosSignBtn, self.signAbortBtn)
        cat4Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat4Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
        })
        
        self.view.addSubview(self.clearLogBtn)
        clearLogBtn.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.freeContextBtn.mas_bottom)?.offset()(20)
            make.height.mas_equalTo()(30)
            make.width.mas_equalTo()(100);
            make.right.mas_equalTo()(self.initPinBtn.mas_right);
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        self.extendedLayoutIncludesOpaqueBars = false
        self.modalPresentationCapturesStatusBarAppearance = false
        
        self.addSubViewAfterViewDidLoad()
        self.categoryAction(sender: deviceCategoryBtn)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getAuthType() -> UInt32 {
        let selectedType = PickerViewAlert.doModal(parent: self, title: "Please choose signature verify method:", dataSource: ["fingerprint", "PIN"])
        self.authTypeCached = true
        var rtn: UInt32 = PAEW_RET_DEV_OP_CANCEL
        if (selectedType >= 0) {
            switch (selectedType) {
            case 0:
                self.nAuthType = CUnsignedChar(PAEW_SIGN_AUTH_TYPE_FP)
                rtn = UInt32(bitPattern: PAEW_RET_SUCCESS)
                break;
            case 1:
                self.nAuthType = CUnsignedChar(PAEW_SIGN_AUTH_TYPE_PIN)
                rtn = UInt32(bitPattern: PAEW_RET_SUCCESS)
                break;
            default:
                self.nAuthType = 0xFF;
                rtn = PAEW_RET_DEV_OP_CANCEL
            }
        }
        self.authTypeResult = rtn
        return rtn
    }
    
    func getPIN() -> UInt32 {
        let pin = TextFieldViewAlert.doModal(parent: self, title: "Input PIN:", message: "Please input your PIN", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        self.pinCached = true
        var rtn: UInt32 = PAEW_RET_DEV_OP_CANCEL
        guard let aPin = pin else {
            return rtn
        }
        self.pin = aPin
        rtn = UInt32(bitPattern: PAEW_RET_SUCCESS)
        self.pinResult = rtn
        return rtn
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    override func viewWillDisappear(_ animated: Bool) {
        freeContextBtnAction(sender: freeContextBtn)
    }
    
    func showCategory(_ categoryList:[UIButton]) {
        for list in allList {
            for btn in list {
                btn.isHidden = categoryList == list ? false : true
            }
        }
    }
    
    @IBAction func categoryAction(sender: UIButton) {
        for btn in categoryList {
            if (sender == btn) {
                btn.backgroundColor = UIColor.white
            } else {
                btn.backgroundColor = UIColor.brown
            }
        }
        
        switch sender {
        case deviceCategoryBtn:
            self.showCategory(deviceCategoryList)
        case fPrintCategoryBtn:
            self.showCategory(fPrintCategoryList)
        case initCategoryBtn:
            self.showCategory(initCategoryList)
        case walletCategoryBtn:
            self.showCategory(walletCategoryList)
        default:
            return
        }
    }
    
    /*
     // MARK: - Device actions
     */
    
    @IBAction func getDevInfoBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            self.printLog("ready to call PAEW_GetDevInfo")
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            //these types could be combined freely
            let devInfoType: CUnsignedInt = CUnsignedInt(PAEW_DEV_INFOTYPE_COS_TYPE | PAEW_DEV_INFOTYPE_COS_VERSION | PAEW_DEV_INFOTYPE_SN | PAEW_DEV_INFOTYPE_CHAIN_TYPE | PAEW_DEV_INFOTYPE_PIN_STATE | PAEW_DEV_INFOTYPE_LIFECYCLE)
            var devInfo = PAEW_DevInfo.init()
            let iRtn = PAEW_GetDevInfo(pPAEWContext, devIdx, devInfoType, &devInfo)
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetDevInfo returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            self.printLog("ucPINState: \(Utils.ewallet_pinstate2string(devInfo.ucPINState))")
            
            let namePtr = UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(devInfo.pbSerialNumber), {return $0}).bindMemory(to: byte.self).baseAddress)!
            
            for i in 0..<PAEW_DEV_INFO_SN_LEN {
                if namePtr.advanced(by: Int(i)).pointee == 0xFF {
                    namePtr.advanced(by: Int(i)).pointee = 0
                }
            }
            self.printLog("Serial Number: \(String.init(cString: namePtr))")
            self.printLog("PAEW_GetDevInfo returns success")
        }
    }
    
    @IBAction func initPinBtnAction(sender: UIButton) {
        let newPin = TextFieldViewAlert.doModal(parent: self, title: "Input new PIN", message: "Please input your new PIN", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let newpin = newPin else {
            return
        }
        
        let newPinAgain = TextFieldViewAlert.doModal(parent: self, title: "Input new PIN again", message: "Please input your new PIN again", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let newpinagain = newPinAgain else {
            return
        }
        
        guard newpin == newpinagain else {
            self.printLog("pin not match")
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Device not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_InitPIN")
            let iRtn = PAEW_InitPIN(pPAEWContext, devIdx, newpin.cString(using: String.Encoding.utf8))
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_InitPIN returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_InitPIN returns success")
        }
    }
    
    @IBAction func verifyPinBtnAction(sender: UIButton) {
        let Pin = TextFieldViewAlert.doModal(parent: self, title: "Input PIN", message: "Please input your PIN", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let pin = Pin else {
            return
        }
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_VerifyPIN")
            let iRtn = PAEW_VerifyPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_VerifyPIN returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_VerifyPIN returns success")
        }
    }
    
    @IBAction func changePinBtnAction(sender: UIButton) {
        let oldPin = TextFieldViewAlert.doModal(parent: self, title: "Input current PIN", message: "Please input your current PIN", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let oldpin = oldPin else {
            return
        }
        
        let newPin = TextFieldViewAlert.doModal(parent: self, title: "Input new PIN", message: "Please input your new PIN", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let newpin = newPin else {
            return
        }
        
        let newPinAgain = TextFieldViewAlert.doModal(parent: self, title: "Input new PIN again", message: "Please input your new PIN again", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let newpinagain = newPinAgain else {
            return
        }
        
        guard newpin == newpinagain else {
            self.printLog("new pin not match")
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            self.printLog("ready to call PAEW_ChangePIN_Input")
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let iRtn = PAEW_ChangePIN_Input(pPAEWContext, devIdx, oldpin.cString(using: String.Encoding.utf8), newpin.cString(using: String.Encoding.utf8))
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ChangePIN_Input returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_ChangePIN_Input returns success")
        }
    }
    
    @IBAction func formatBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_Format")
            let iRtn = PAEW_Format(pPAEWContext, devIdx)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_Format returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_Format returns success")
        }
    }
    
    //PAEW_FreeContext MUST be called finally when all work were done
    @IBAction func freeContextBtnAction (sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_FreeContext")
            let iRtn = PAEW_FreeContext(pPAEWContext)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_FreeContext returns failed: %@", Utils.errorCodeToString(iRtn))
                return
            }
            self.deviceContext = nil
            self.printLog("PAEW_FreeContext returns success")
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func clearScreenBtnAction (sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_ClearLCD")
            let iRtn = PAEW_ClearLCD(pPAEWContext, devIdx)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ClearLCD returns failed: %@", Utils.errorCodeToString(iRtn))
                return
            }
            self.printLog("PAEW_ClearLCD returns success")
        }
    }
    
    @IBAction func powerOffBtnAction (sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_PowerOff")
            let iRtn = PAEW_PowerOff(pPAEWContext, devIdx)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_PowerOff returns failed: %@", Utils.errorCodeToString(iRtn))
                return
            }
            self.printLog("PAEW_PowerOff returns success")
            //it will be a good practice to call freecontext after poweroff
            self.freeContextBtnAction(sender: self.freeContextBtn)
        }
    }
    
    @IBAction func writeSNBtnAction (sender: UIButton) {
        let result = TextFieldViewAlert.doModal(parent: self, title: "Please input SN", message: "Please input SN", isPassword: false, minLengtRequired: 10, maxLengtRequired: 16, keyBoardType: .numberPad)
        guard let sn = result else {
            self.printLog("Invalid SN input")
            return
        }
        
        for c in sn {
            guard ((c >= "0" && c <= "9") || (c >= "a" && c <= "z") || (c >= "A" && c <= "Z")) else {
                self.printLog("Invalid SN input")
                return
            }
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            var bytes: [CChar] = sn.cString(using: String.Encoding.utf8)!
            let count = sn.count
            var buffer = Array<byte>.init(repeating: 0, count: Int(PAEW_DEV_INFO_SN_LEN))
            memcpy(&buffer, &bytes, count)
            self.printLog("ready to call PAEW_WriteSN")
            let iRtn = PAEW_WriteSN(pPAEWContext, devIdx, buffer, Int(PAEW_DEV_INFO_SN_LEN))
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_WriteSN returns failed: %@", Utils.errorCodeToString(iRtn))
                return
            }
            self.printLog("PAEW_WriteSN returns success")
        }
    }
    
    /*
     // MARK: - Fingerprint actions
     */
    
    @IBAction func getFPListBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            var listLen: size_t = 0
            self.printLog("ready to call PAEW_GetFPList")
            var iRtn = PAEW_GetFPList(pPAEWContext, devIdx, nil, &listLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetFPList for get count returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            var fpArray = Array<FingerPrintID>.init(repeating: FingerPrintID.init(), count: listLen)
            iRtn = PAEW_GetFPList(pPAEWContext, devIdx, &fpArray, &listLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetFPList returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            let strIndex: NSMutableString = ""
            for i in 0..<listLen {
                strIndex.appendFormat(i == 0 ? "No.%hhd" : ", No.%hhd", fpArray[i].data/*fpListPtr.advanced(by: i).pointee.data*/)
            }
            let result:String = strIndex as String
            self.printLog(listLen == 1 ?  "\(listLen) fingerprint exists at index: \(result)" : "\(listLen) fingerprints exist at index: \(result)")
            self.printLog("PAEW_GetFPList returns success")
        }
    }
    
    @IBAction func enrollFPBtnAction(sender: UIButton) {
        self.abortBtnState = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_EnrollFP, during the whole enroll process, you can tap Abort button to abort at any time")
            var iRtn:CUnsignedInt = CUnsignedInt(bitPattern: PAEW_EnrollFP(pPAEWContext, devIdx))
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_EnrollFP returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            var lastRtn: CUnsignedInt = CUnsignedInt(bitPattern: PAEW_RET_SUCCESS)
            repeat {
                iRtn = CUnsignedInt(bitPattern: PAEW_GetFPState(pPAEWContext, devIdx))
                if lastRtn != iRtn {
                    self.printLog("fpstate: \(Utils.errorCodeToString(iRtn))")
                    lastRtn = iRtn
                }
                if self.abortBtnState {
                    self.abortCondition.lock()
                    self.abortHandelBlock!(true)
                    self.abortCondition.wait()
                    self.abortCondition.unlock()
                    self.abortBtnState = false
                }
            } while ((iRtn == PAEW_RET_DEV_WAITING) || (iRtn == PAEW_RET_DEV_FP_GOOG_FINGER) || (iRtn == PAEW_RET_DEV_FP_REDUNDANT) || (iRtn == PAEW_RET_DEV_FP_BAD_IMAGE) || (iRtn == PAEW_RET_DEV_FP_NO_FINGER) || (iRtn == PAEW_RET_DEV_FP_NOT_FULL_FINGER))
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_EnrollFP failed due to PAEW_GetFPState returns: \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            self.printLog("PAEW_EnrollFP returns success")
        }
    }
    
    @IBAction func verifyFPBtnAction(sender: UIButton) {
        self.abortBtnState = false
        DispatchQueue.global(qos: .default).async {
            self.printLog("ready to call PAEW_VerifyFP")
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            var iRtn = CUnsignedInt(bitPattern: PAEW_VerifyFP(pPAEWContext, devIdx))
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_VerifyFP returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            var lastRtn:CUnsignedInt = CUnsignedInt(PAEW_RET_SUCCESS)
            repeat {
                iRtn = CUnsignedInt(bitPattern: PAEW_GetFPState(pPAEWContext, devIdx))
                if lastRtn != iRtn {
                    self.printLog("\(Utils.errorCodeToString(iRtn))")
                    lastRtn = iRtn
                }
                if self.abortBtnState {
                    self.abortCondition.lock()
                    self.abortHandelBlock!(true)
                    self.abortCondition.wait()
                    self.abortCondition.unlock()
                    self.abortBtnState = false
                }
            } while (lastRtn == PAEW_RET_DEV_WAITING)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_VerifyFP failed due to PAEW_GetFPState returns:  \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var fpListCount: size_t = 1
            var fpIDList = FingerPrintID.init()
            iRtn = CUnsignedInt(PAEW_GetVerifyFPList(pPAEWContext, devIdx, &fpIDList, &fpListCount))
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_VerifyFP failed due to PAEW_GetVerifyFPList returns:  \(Utils.errorCodeToString(iRtn))")
                return
            }
            if fpListCount != 1 {
                self.printLog("PAEW_VerifyFP successe but nFPListCount is: \(fpListCount)")
            } else {
                self.printLog("PAEW_VerifyFP successe with No.\(fpIDList.data) fingerprint verified")
            }
        }
    }
    
    @IBAction func deleteFPBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_DeleteFP")
            //1. delete all fingerprints
            let fpCount = 0
            let iRtn = PAEW_DeleteFP(pPAEWContext, devIdx, nil, fpCount)
            
            //            2. delete single fingerprint at position 1(index starts from 0)
            //            var localFP = FingerPrintID.init()
            //            localFP.data = 1
            //            let fpCount = 1
            //            let iRtn = PAEW_DeleteFP(pPAEWContext, devIdx, &localFP, fpCount)
            
            //            3. delete multiple fingerprints
            //            let fpCount = 3
            //            var fpData = Data.init(count: fpCount * MemoryLayout<FingerPrintID>.size)
            //            let fpPtr = fpData.withUnsafeBytes({ (ptr: UnsafePointer<byte>) -> UnsafePointer<byte> in
            //                return ptr
            //            })
            //            for i in 0..<fpCount {
            //                fpPtr.advanced(by: i).pointee.data = i
            //            }
            //            let iRtn = PAEW_DeleteFP(pPAEWContext, devIdx, fpPtr, fpCount)
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_DeleteFP returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_DeleteFP returns success")
        }
    }
    
    @IBAction func abortBtnAction (sender: UIButton) {
        self.abortBtnState = true
    }
    
    //the best practice is calibrate ervery time when the device power on
    @IBAction func calibrateFPBtnAction (sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_CalibrateFP")
            let iRtn = PAEW_CalibrateFP(pPAEWContext, devIdx)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_CalibrateFP returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_CalibrateFP returns success")
        }
    }
    
    /*
     // MARK: - Init actions
     */
    
    @IBAction func genSeedBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let seedLen:byte = 32
            var mneLen:size_t = size_t(PAEW_MNE_MAX_LEN)
            var mneData = Data.init(count: mneLen)
            let mnePtr = mneData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            var checkIndexData = Data.init(count: Int(PAEW_MNE_INDEX_MAX_COUNT) * MemoryLayout<size_t>.size)
            var checkIndexCount: size_t = size_t(PAEW_MNE_INDEX_MAX_COUNT)
            let checkIndexPtr = checkIndexData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<size_t>) -> UnsafeMutablePointer<size_t> in
                return ptr
            })
            self.printLog("ready to call PAEW_GenerateSeed_GetMnes")
            var iRtn = PAEW_GenerateSeed_GetMnes(pPAEWContext, devIdx, seedLen, mnePtr, &mneLen, checkIndexPtr, &checkIndexCount)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GenerateSeed_GetMnes returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            self.printLog("PAEW_GenerateSeed_GetMnes returns success")
            
            //mnePtr is a C-style string, so it can be simply output like this:
            //self.printLog("seed generated, mnemonics are: %s", mnePtr)
            let mneOriginalStr = String.init(cString: mnePtr)
            var mneStr = ""
            let singleWords = mneOriginalStr.components(separatedBy: " ")
            for (index, value) in singleWords.enumerated() {
                mneStr.append(value)
                //6 words in one line
                if index % 6 == 5 {
                    if index != (singleWords.count - 1) {
                        mneStr.append("\n")
                    }
                } else {
                    mneStr.append(" ")
                }
            }
            self.printLog("seed generated, mnemonics are:\n\(mneStr)")
            
            var examWords = ""
            for i in 0..<checkIndexCount {
                examWords.append(String.init(format: i == 0 ? "word%lu" : ", word%lu", checkIndexPtr.advanced(by: i).pointee + 1))
            }
            self.printLog("please input the words exactly as this sequence with ONE WHITESPACE between each words: \(examWords)")
            
            var inputWords = ""
            for i in 0..<checkIndexCount {
                inputWords.append(singleWords[checkIndexPtr.advanced(by: i).pointee]);
                if i != checkIndexCount - 1 {
                    inputWords.append(" ")
                }
            }
            
            self.printLog("words to input are: \(inputWords)")
            
            var wordsCString = inputWords.cString(using: String.Encoding.utf8)
            let wordsPtr = wordsCString?.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> UnsafeMutablePointer<byte> in
                return ptr.bindMemory(to: byte.self).baseAddress!
            })

            self.printLog("ready to call PAEW_GenerateSeed_CheckMnes")
            iRtn = PAEW_GenerateSeed_CheckMnes(pPAEWContext, devIdx, wordsPtr, inputWords.count);
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GenerateSeed_CheckMnes returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_GenerateSeed_CheckMnes returns success")
        }
    }
    
    @IBAction func importMNEBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            self.printLog("ready to call PAEW_ImportSeed")
            let mnemonics = "mass dust captain baby mass dust captain baby mass dust captain baby mass dust captain baby mass electric"
            var mnemonicsData = mnemonics.cString(using: String.Encoding.utf8)
            let mnemonicsPtr = mnemonicsData!.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> UnsafeMutablePointer<byte> in
                return ptr.bindMemory(to: byte.self).baseAddress!
            })
            self.printLog("mnemonics to import are: \(mnemonics)")
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let iRtn = PAEW_ImportSeed(pPAEWContext, devIdx, mnemonicsPtr, mnemonics.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ImportSeed returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_ImportSeed returns success")
        }
    }
    
    /*
     // MARK: - Wallet actions
     */
    
    @IBAction func getAddressBtnAction(sender: UIButton) -> () {
        let coinType = byte(PAEW_COIN_TYPE_EOS)
        
        let showTypeNames = ["DO NOT show on screen", "Show on screen"]
        let selectedType = PickerViewAlert.doModal(parent: self, title: "please select show type", dataSource: showTypeNames)
        if selectedType == -1 {
            return
        }
        guard selectedType >= 0 && selectedType < 2 else {
            self.printLog("invalid show type: \(selectedType)")
            return
        }
        let showType = byte(selectedType)
        let derivePath = puiDerivePathEOS
        let pathLen: size_t = derivePath.count
        
        DispatchQueue.global(qos: .default).async {
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let devIdx = 0
            self.printLog("ready to call PAEW_DeriveTradeAddress")
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), pathLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_DeriveTradeAddress on EOS returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_DeriveTradeAddress returns success")
            var addressLen = 1024
            var addressData = Data.init(count: addressLen)
            let addressPtr = addressData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            self.printLog("ready to call PAEW_GetTradeAddress")
            iRtn = PAEW_GetTradeAddress(pPAEWContext, devIdx, coinType, showType, addressPtr, &addressLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetTradeAddress on EOS returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            let address = String.init(cString: addressPtr)
            self.printLog("PAEW_GetTradeAddress on coin EOS returns success, address is \(address)")
        }
    }
    
    @IBAction func getDeviceCheckCodeAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let devIdx = 0
            
            var checkCodeLen: size_t = 1024;
            
            var checkCodeData = Data.init(count: checkCodeLen)
            let checkCodePtr = checkCodeData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            self.printLog("ready to call PAEW_GetDeviceCheckCode")
            let iRtn = PAEW_GetDeviceCheckCode(pPAEWContext, devIdx, checkCodePtr, &checkCodeLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetDeviceCheckCode returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("DeviceCheckCode is: \(Utils.bytesToHexString(data: checkCodePtr, length: checkCodeLen))")
            self.printLog("PAEW_GetDeviceCheckCode returns success")
        }
    }
    
    @IBAction func signAbortBtnAction (sender: UIButton) {
        self.abortBtnState = true
    }
    
    @IBAction func eosSignBtnAction(sender: UIButton) {
        self.abortBtnState = false
        var rtn = self.getAuthType()
        guard rtn == PAEW_RET_SUCCESS else {
            self.printLog("user canceled PAEW_EOS_TXSign_Ex")
            return
        }
        
        if self.nAuthType == PAEW_SIGN_AUTH_TYPE_PIN {
            rtn = self.getPIN()
            guard rtn == PAEW_RET_SUCCESS else {
                self.printLog("user canceled PAEW_EOS_TXSign_Ex")
                return
            }
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_EOS)
            let derivePath = self.puiDerivePathEOS
            self.printLog("ready to call PAEW_EOS_TXSign_Ex")
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_EOS_TXSign_Ex failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            let transaction: [UInt8] = [byte(0x74), byte(0x09), byte(0x70), byte(0xd9), byte(0xff),
                                        byte(0x01), byte(0xb5), byte(0x04), byte(0x63), byte(0x2f),
                                        byte(0xed), byte(0xe1), byte(0xad), byte(0xc3), byte(0xdf),
                                        byte(0xe5), byte(0x59), byte(0x90), byte(0x41), byte(0x5e),
                                        byte(0x4f), byte(0xde), byte(0x01), byte(0xe1), byte(0xb8),
                                        byte(0xf3), byte(0x15), byte(0xf8), byte(0x13), byte(0x6f),
                                        byte(0x47), byte(0x6c), byte(0x14), byte(0xc2), byte(0x67),
                                        byte(0x5b), byte(0x01), byte(0x24), byte(0x5f), byte(0x70),
                                        byte(0x5d), byte(0xd7), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x01), byte(0x00), byte(0xa6), byte(0x82),
                                        byte(0x34), byte(0x03), byte(0xea), byte(0x30), byte(0x55),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x57), byte(0x2d),
                                        byte(0x3c), byte(0xcd), byte(0xcd), byte(0x01), byte(0x20),
                                        byte(0x29), byte(0xc2), byte(0xca), byte(0x55), byte(0x7a),
                                        byte(0x73), byte(0x57), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0xa8), byte(0xed), byte(0x32), byte(0x32),
                                        byte(0x21), byte(0x20), byte(0x29), byte(0xc2), byte(0xca),
                                        byte(0x55), byte(0x7a), byte(0x73), byte(0x57), byte(0x90),
                                        byte(0x55), byte(0x8c), byte(0x86), byte(0x77), byte(0x95),
                                        byte(0x4c), byte(0x3c), byte(0x10), byte(0x27), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x04), byte(0x45), byte(0x4f), byte(0x53), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            var callback = signCallbacks.init(getAuthType: self.getAuthTypeCallback, getPIN: self.getPINCallback, putSignState: self.putSignStateCallback)
            self.lastSignState = PAEW_RET_SUCCESS
            iRtn = PAEW_EOS_TXSign_Ex(pPAEWContext, devIdx, transaction, transaction.count, sigPtr, &sigLen, &callback, nil)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_EOS_TXSign_Ex returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("EOS signature is: %s", sigPtr)
            self.printLog("PAEW_EOS_TXSign_Ex returns success")
        }
    }
    
    /*
     // MARK: - ClearLog action
     */
    
    @IBAction func clearLogBtnAction(sender: UIButton) {
        self.logCounter = 0
        if Thread.isMainThread {
            self.in_outTextView.text = ""
        } else {
            DispatchQueue.main.async {
                self.in_outTextView.text = ""
            }
        }
    }
    
    /*
     // MARK: - Log function
     */
    
    func printLog(_ format: String, _ args: CVarArg...) {
        logCounter += 1;
        let str:String = String.init(format: format, arguments: args)
        let log = String.init(format: "[%zu]%@\n", logCounter, str)
        
        if Thread.isMainThread {
            self.in_outTextView.text.append(log)
            self.in_outTextView.scrollRangeToVisible(NSRange.init(location: self.in_outTextView.text.count, length: 1))
        } else {
            DispatchQueue.main.async {
                self.in_outTextView.text.append(log)
                self.in_outTextView.scrollRangeToVisible(NSRange.init(location: self.in_outTextView.text.count, length: 1))
            }
        }
    }
}
