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
    let puiDerivePathETH: [CUnsignedInt] = [0, 0x8000002c, 0x8000003c, 0x80000000, 0x00000000, 0x00000000]
    let puiDerivePathEOS: [CUnsignedInt] = [0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000]
    let puiDerivePathCYB: [CUnsignedInt] = [0, 0, 1, 0x00000080, 0x00000000, 0x00000000]
    let puiDerivePathBTC: [CUnsignedInt] = [0, 0x8000002c, 0x80000000, 0x80000000, 0x00000000, 0x00000000]
    let puiDerivePathETC: [CUnsignedInt] = [0, 0x8000002c, 0x8000003d, 0x80000000, 0x00000000, 0x00000000]
    
    let in_outTextView: UITextView
    
    let categoryList: [UIButton]
    let deviceCategoryBtn: UIButton
    let fPrintCategoryBtn: UIButton
    let initCategoryBtn: UIButton
    let walletCategoryBtn: UIButton
    let imageCategoryBtn: UIButton
    let deviceCategoryList: [UIButton]
    let fPrintCategoryList: [UIButton]
    let initCategoryList: [UIButton]
    let walletCategoryList: [UIButton]
    let imageCategoryList: [UIButton]
    let allList: [[UIButton]]
    
    let getDevInfoBtn: UIButton
    let initPinBtn: UIButton
    let verifyPinBtn: UIButton
    let changePinBtn: UIButton
    let formatBtn: UIButton
    let clearScreenBtn: UIButton
    let freeContextBtn: UIButton
    let powerOffBtn: UIButton
    let writeSNBtn: UIButton
    let updateCOSBtn: UIButton
    let abortButtonBtn1: UIButton
    let getBatteryStateBtn: UIButton
    let getFWVersionBtn: UIButton
    
    let getFPListBtn: UIButton
    let enrollFPBtn: UIButton
    let verifyFPBtn: UIButton
    let deleteFPBtn: UIButton
    let calibrateFPBtn: UIButton
    let abortBtn: UIButton
    
    let genSeedBtn: UIButton
    let importMNEBtn: UIButton
    let recoverSeedBtn: UIButton
    
    let getAddressBtn: UIButton
    let getDeviceCheckCodeBtn: UIButton
    let signAbortBtn: UIButton
    let ethSignBtn: UIButton
    let eosSignBtn: UIButton
    let cybSignBtn: UIButton
    let ethSignNewBtn: UIButton
    let eosSignNewBtn: UIButton
    let cybSignNewBtn: UIButton
    let btcSignBtn: UIButton
    let erc20SignBtn: UIButton
    let etcSignBtn: UIButton
    let switchSignBtn: UIButton
    let abortButtonBtn2: UIButton
    
    let setImageDataBtn: UIButton
    let showImageBtn: UIButton
    let setLogoImageBtn: UIButton
    let getImageListBtn: UIButton
    let setImageNameBtn: UIButton
    let getImageNameBtn: UIButton
   
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
    var imageCount: size_t = 0
    var updateProgress = 0
    
    var abortBtnState: Bool = false
    var abortCondition: NSCondition

    var abortFPBlock: AbortHandelBlock? = nil
    
    var switchSignFlag: Bool = false
    var abortSignFlag: Bool = false
    var abortSignBlock: AbortHandelBlock? = nil
    
    var lastButtonState: Int32 = PAEW_RET_SUCCESS
    var abortButtonFlag: Bool = false
    
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
        if(selfClass.abortSignFlag) {
            selfClass.abortCondition.lock()
            selfClass.abortSignBlock!(true)
            selfClass.abortCondition.wait()
            selfClass.abortCondition.unlock()
            selfClass.abortSignFlag = false
        }
        rtn = UInt32(PAEW_RET_SUCCESS)
        return Int32(bitPattern: rtn)
    }
    
    var progressCallback: tFunc_Progress_Callback = {
        guard let selfClass = ewalletClass else {
            return Int32(bitPattern: PAEW_RET_DEV_OP_CANCEL)
        }
        if $1 != selfClass.updateProgress {
            selfClass.printLog("current update progress is \($1)%%")
            selfClass.updateProgress = $1
        }
        return PAEW_RET_SUCCESS
    }
    
    var putStateCallback: tFunc_PutState_Callback = {
        var rtn: UInt32 = PAEW_RET_DEV_OP_CANCEL
        guard let selfClass = ewalletClass else {
            return Int32(bitPattern: rtn)
        }
        if ($1 != selfClass.lastButtonState) {
            selfClass.printLog(Utils.errorCodeToString($1))
            selfClass.lastButtonState = $1
        }
        //here is a good place to canel waiting for button pressed
        if(selfClass.abortButtonFlag) {
            selfClass.abortCondition.lock()
            DispatchQueue.global(qos: .default).async {
                let devIdx = 0
                guard let pPAEWContext = selfClass.deviceContext else {
                    selfClass.printLog("Deivce not connected, connect to device first")
                    return
                }
                selfClass.printLog("ready to call PAEW_AbortButton")
                selfClass.abortCondition.lock()
                let iRtn = PAEW_AbortButton(pPAEWContext, devIdx)
                selfClass.abortCondition.signal()
                selfClass.abortCondition.unlock()
                guard iRtn == PAEW_RET_SUCCESS else {
                    selfClass.printLog("PAEW_AbortButton returns failed \(Utils.errorCodeToString(iRtn))")
                    return
                }
                selfClass.printLog("PAEW_AbortButton returns success")
            }
            selfClass.abortCondition.wait()
            selfClass.abortCondition.unlock()
            selfClass.abortButtonFlag = false
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
        writeSNBtn = UIButton.init(type: .custom)
        updateCOSBtn = UIButton.init(type: .custom)
        abortButtonBtn1 = UIButton.init(type: .custom)
        getBatteryStateBtn = UIButton.init(type: .custom)
        getFWVersionBtn = UIButton.init(type: .custom)
        
        getFPListBtn = UIButton.init(type: .custom)
        enrollFPBtn = UIButton.init(type: .custom)
        verifyFPBtn = UIButton.init(type: .custom)
        deleteFPBtn = UIButton.init(type: .custom)
        calibrateFPBtn = UIButton.init(type: .custom)
        abortBtn = UIButton.init(type: .custom)
        
        genSeedBtn = UIButton.init(type: .custom)
        importMNEBtn = UIButton.init(type: .custom)
        recoverSeedBtn = UIButton.init(type: .custom)
        
        getAddressBtn = UIButton.init(type: .custom);
        getDeviceCheckCodeBtn = UIButton.init(type: .custom)
        signAbortBtn = UIButton.init(type: .custom)
        ethSignBtn = UIButton.init(type: .custom);
        eosSignBtn = UIButton.init(type: .custom);
        cybSignBtn = UIButton.init(type: .custom);
        ethSignNewBtn = UIButton.init(type: .custom)
        eosSignNewBtn = UIButton.init(type: .custom)
        cybSignNewBtn = UIButton.init(type: .custom)
        btcSignBtn = UIButton.init(type: .custom)
        erc20SignBtn = UIButton.init(type: .custom)
        etcSignBtn = UIButton.init(type: .custom)
        switchSignBtn = UIButton.init(type: .custom)
        abortButtonBtn2 = UIButton.init(type: .custom)
        
        getImageListBtn = UIButton.init(type: .custom)
        setImageNameBtn = UIButton.init(type: .custom)
        getImageNameBtn = UIButton.init(type: .custom)
        setImageDataBtn = UIButton.init(type: .custom)
        showImageBtn = UIButton.init(type: .custom)
        setLogoImageBtn = UIButton.init(type: .custom)
        
        clearLogBtn = UIButton.init(type: UIButtonType.custom)
        
        fPrintCategoryBtn = UIButton.init(type: .custom)
        initCategoryBtn = UIButton.init(type: .custom)
        walletCategoryBtn = UIButton.init(type: .custom)
        imageCategoryBtn = UIButton.init(type: .custom)
        deviceCategoryBtn = UIButton.init(type: .custom)
        in_outTextView = UITextView.init()
        
        deviceCategoryList = [getDevInfoBtn, initPinBtn, verifyPinBtn, changePinBtn, formatBtn, clearScreenBtn, freeContextBtn, powerOffBtn, writeSNBtn, updateCOSBtn, abortButtonBtn1, getBatteryStateBtn, getFWVersionBtn]
        fPrintCategoryList = [getFPListBtn, enrollFPBtn, verifyFPBtn, deleteFPBtn, calibrateFPBtn, abortBtn]
        initCategoryList = [genSeedBtn, importMNEBtn, recoverSeedBtn]
        walletCategoryList = [getAddressBtn, getDeviceCheckCodeBtn, ethSignBtn, eosSignBtn, cybSignBtn, signAbortBtn, ethSignNewBtn, eosSignNewBtn, cybSignNewBtn, btcSignBtn, erc20SignBtn, etcSignBtn, switchSignBtn, abortButtonBtn2]
        imageCategoryList = [getImageListBtn, setImageNameBtn, getImageNameBtn, setImageDataBtn, showImageBtn, setLogoImageBtn]
        categoryList = [deviceCategoryBtn, fPrintCategoryBtn, initCategoryBtn, walletCategoryBtn, imageCategoryBtn]
        allList = Array.init(arrayLiteral: deviceCategoryList, fPrintCategoryList, initCategoryList, walletCategoryList, imageCategoryList)
        
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
        
        imageCategoryBtn.setTitle("Image", for: UIControlState.normal)
        imageCategoryBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        imageCategoryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        imageCategoryBtn.backgroundColor = UIColor.lightGray
        imageCategoryBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.categoryAction(sender:)), for: UIControlEvents.touchUpInside)
        
        
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
        
        writeSNBtn.setTitle("WriteSN", for: UIControlState.normal)
        writeSNBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        writeSNBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        writeSNBtn.backgroundColor = UIColor.lightGray
        writeSNBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.writeSNBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        updateCOSBtn.setTitle("UpdateCOS", for: UIControlState.normal)
        updateCOSBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        updateCOSBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        updateCOSBtn.backgroundColor = UIColor.lightGray
        updateCOSBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.updateCOSBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        abortButtonBtn1.setTitle("AbortButton", for: UIControlState.normal)
        abortButtonBtn1.setTitleColor(UIColor.blue, for:UIControlState.normal)
        abortButtonBtn1.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        abortButtonBtn1.backgroundColor = UIColor.lightGray
        abortButtonBtn1.addTarget(self, action: #selector(Test_C_EWallet_ViewController.abortButtonBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getBatteryStateBtn.setTitle("GetBatt", for: UIControlState.normal)
        getBatteryStateBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getBatteryStateBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getBatteryStateBtn.backgroundColor = UIColor.lightGray
        getBatteryStateBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getBatteryStateBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getFWVersionBtn.setTitle("GetFWVer", for: UIControlState.normal)
        getFWVersionBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getFWVersionBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getFWVersionBtn.backgroundColor = UIColor.lightGray
        getFWVersionBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getFWVersionBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        
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
        
        recoverSeedBtn.setTitle("RecoverSeed", for: UIControlState.normal)
        recoverSeedBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        recoverSeedBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        recoverSeedBtn.backgroundColor = UIColor.lightGray
        recoverSeedBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.recoverSeedBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        
        getAddressBtn.setTitle("GetAddress", for: UIControlState.normal)
        getAddressBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getAddressBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getAddressBtn.backgroundColor = UIColor.lightGray
        getAddressBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getAddressBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getDeviceCheckCodeBtn.setTitle("DevChkCode", for: UIControlState.normal)
        getDeviceCheckCodeBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getDeviceCheckCodeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getDeviceCheckCodeBtn.backgroundColor = UIColor.lightGray
        getDeviceCheckCodeBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getDeviceCheckCodeAction(sender:)), for: UIControlEvents.touchUpInside)
        
        signAbortBtn.setTitle("Abort", for: UIControlState.normal)
        signAbortBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        signAbortBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        signAbortBtn.backgroundColor = UIColor.lightGray
        signAbortBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.signAbortBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        ethSignBtn.setTitle("ETHSign", for: UIControlState.normal)
        ethSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        ethSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        ethSignBtn.backgroundColor = UIColor.lightGray
        ethSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.ethSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        eosSignBtn.setTitle("EOSSign", for: UIControlState.normal)
        eosSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        eosSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        eosSignBtn.backgroundColor = UIColor.lightGray
        eosSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.eosSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        cybSignBtn.setTitle("CYBSign", for: UIControlState.normal)
        cybSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        cybSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        cybSignBtn.backgroundColor = UIColor.lightGray
        cybSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.cybSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        ethSignNewBtn.setTitle("ETHSignNew", for: UIControlState.normal)
        ethSignNewBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        ethSignNewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        ethSignNewBtn.backgroundColor = UIColor.lightGray
        ethSignNewBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.ethSignNewBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        eosSignNewBtn.setTitle("EOSSignNew", for: UIControlState.normal)
        eosSignNewBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        eosSignNewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        eosSignNewBtn.backgroundColor = UIColor.lightGray
        eosSignNewBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.eosSignNewBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        cybSignNewBtn.setTitle("CYBSignNew", for: UIControlState.normal)
        cybSignNewBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        cybSignNewBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        cybSignNewBtn.backgroundColor = UIColor.lightGray
        cybSignNewBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.cybSignNewBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        btcSignBtn.setTitle("BTCSign", for: UIControlState.normal)
        btcSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        btcSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        btcSignBtn.backgroundColor = UIColor.lightGray
        btcSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.btcSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        erc20SignBtn.setTitle("ERC20Sign", for: UIControlState.normal)
        erc20SignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        erc20SignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        erc20SignBtn.backgroundColor = UIColor.lightGray
        erc20SignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.erc20SignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        etcSignBtn.setTitle("ETCSign", for: UIControlState.normal)
        etcSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        etcSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        etcSignBtn.backgroundColor = UIColor.lightGray
        etcSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.etcSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        switchSignBtn.setTitle("SwitchSignMethod", for: UIControlState.normal)
        switchSignBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        switchSignBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        switchSignBtn.backgroundColor = UIColor.lightGray
        switchSignBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.switchSignBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        abortButtonBtn2.setTitle("AbortButton", for: UIControlState.normal)
        abortButtonBtn2.setTitleColor(UIColor.blue, for:UIControlState.normal)
        abortButtonBtn2.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        abortButtonBtn2.backgroundColor = UIColor.lightGray
        abortButtonBtn2.addTarget(self, action: #selector(Test_C_EWallet_ViewController.abortButtonBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getImageListBtn.setTitle("GetList", for: UIControlState.normal)
        getImageListBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getImageListBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getImageListBtn.backgroundColor = UIColor.lightGray
        getImageListBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getImageListBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        setImageNameBtn.setTitle("SetName", for: UIControlState.normal)
        setImageNameBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        setImageNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        setImageNameBtn.backgroundColor = UIColor.lightGray
        setImageNameBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.setImageNameBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        getImageNameBtn.setTitle("GetName", for: UIControlState.normal)
        getImageNameBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        getImageNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        getImageNameBtn.backgroundColor = UIColor.lightGray
        getImageNameBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.getImageNameBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        setImageDataBtn.setTitle("SetData", for: UIControlState.normal)
        setImageDataBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        setImageDataBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        setImageDataBtn.backgroundColor = UIColor.lightGray
        setImageDataBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.setImageDataBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        showImageBtn.setTitle("ShowImg", for: UIControlState.normal)
        showImageBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        showImageBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        showImageBtn.backgroundColor = UIColor.lightGray
        showImageBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.showImageBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        setLogoImageBtn.setTitle("SetLogo", for: UIControlState.normal)
        setLogoImageBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        setLogoImageBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        setLogoImageBtn.backgroundColor = UIColor.lightGray
        setLogoImageBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.setLogoImageBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        clearLogBtn.setTitle("ClearLog", for: UIControlState.normal)
        clearLogBtn.setTitleColor(UIColor.blue, for:UIControlState.normal)
        clearLogBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium)
        clearLogBtn.backgroundColor = UIColor.lightGray
        clearLogBtn.addTarget(self, action: #selector(Test_C_EWallet_ViewController.clearLogBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        
        
        self.abortFPBlock =  { (abortState: Bool) in
            guard abortState else {
                return
            }
            DispatchQueue.global(qos: .default).async {
                let devIdx = 0
                guard let pPAEWContext = self.deviceContext else {
                    self.printLog("Deivce not connected, connect to device first")
                    return
                }
                self.abortBtnState = false
                self.printLog("ready to call PAEW_AbortFP")
                let iRtn = PAEW_AbortFP(pPAEWContext, devIdx)
                self.abortCondition.lock()
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
        
        self.abortSignBlock =  { (abortState: Bool) in
            guard abortState else {
                return
            }
            DispatchQueue.global(qos: .default).async {
                let devIdx = 0
                guard let pPAEWContext = self.deviceContext else {
                    self.printLog("Deivce not connected, connect to device first")
                    return
                }
                self.abortBtnState = false
                self.printLog("ready to call PAEW_AbortSign")
                self.abortCondition.lock()
                let iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                self.abortCondition.signal()
                self.abortCondition.unlock()
                guard iRtn == PAEW_RET_SUCCESS else {
                    self.printLog("PAEW_AbortSign returns failed \(Utils.errorCodeToString(iRtn))")
                    return
                }
                self.printLog("PAEW_AbortSign returns success")
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
        self.view.addSubview(imageCategoryBtn)
        
        let catArr:NSArray = NSArray.init(arrayLiteral: deviceCategoryBtn, fPrintCategoryBtn, initCategoryBtn, walletCategoryBtn, imageCategoryBtn)
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
        self.view.addSubview(writeSNBtn)
        self.view.addSubview(updateCOSBtn)
        self.view.addSubview(abortButtonBtn1)
        self.view.addSubview(getBatteryStateBtn)
        self.view.addSubview(getFWVersionBtn)
        
        self.view.addSubview(getFPListBtn)
        self.view.addSubview(enrollFPBtn)
        self.view.addSubview(verifyFPBtn)
        self.view.addSubview(deleteFPBtn)
        self.view.addSubview(calibrateFPBtn)
        self.view.addSubview(abortBtn)
        
        self.view.addSubview(genSeedBtn)
        self.view.addSubview(importMNEBtn)
        self.view.addSubview(recoverSeedBtn)
        
        self.view.addSubview(getAddressBtn)
        self.view.addSubview(getDeviceCheckCodeBtn)
        self.view.addSubview(signAbortBtn)
        self.view.addSubview(ethSignBtn)
        self.view.addSubview(eosSignBtn)
        self.view.addSubview(cybSignBtn)
        self.view.addSubview(ethSignNewBtn)
        self.view.addSubview(eosSignNewBtn)
        self.view.addSubview(cybSignNewBtn)
        self.view.addSubview(btcSignBtn)
        self.view.addSubview(erc20SignBtn)
        self.view.addSubview(etcSignBtn)
        self.view.addSubview(switchSignBtn)
        self.view.addSubview(abortButtonBtn2)
        
        self.view.addSubview(getImageListBtn)
        self.view.addSubview(setImageNameBtn)
        self.view.addSubview(getImageNameBtn)
        self.view.addSubview(setImageDataBtn)
        self.view.addSubview(showImageBtn)
        self.view.addSubview(setLogoImageBtn)
        
        let LINESPACING:CGFloat = 10
        let BUTTONHEIGHT:CGFloat = 30
        
        let cat1Arr1:NSArray = NSArray.init(arrayLiteral: getDevInfoBtn, initPinBtn, verifyPinBtn)
        cat1Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat1Arr2:NSArray = NSArray.init(arrayLiteral: changePinBtn, formatBtn, clearScreenBtn)
        cat1Arr2.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr2.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.getDevInfoBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat1Arr3:NSArray = NSArray.init(arrayLiteral: self.freeContextBtn, self.powerOffBtn, self.writeSNBtn)
        cat1Arr3.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr3.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.changePinBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat1Arr4:NSArray = NSArray.init(arrayLiteral: self.updateCOSBtn, self.abortButtonBtn1, self.getBatteryStateBtn)
        cat1Arr4.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat1Arr4.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.freeContextBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        getFWVersionBtn.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.updateCOSBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
            make.right.mas_equalTo()(self.getDevInfoBtn.mas_right);
            make.left.mas_equalTo()(self.getDevInfoBtn.mas_left);
        })
        
        let cat2Arr1:NSArray = NSArray.init(arrayLiteral: self.getFPListBtn, self.enrollFPBtn, self.verifyFPBtn)
        cat2Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat2Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat2Arr2:NSArray = NSArray.init(arrayLiteral: self.deleteFPBtn, self.calibrateFPBtn, self.abortBtn)
        cat2Arr2.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat2Arr2.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.getDevInfoBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        
        let cat3Arr1:NSArray = NSArray.init(arrayLiteral: self.genSeedBtn, self.importMNEBtn, self.recoverSeedBtn)
        cat3Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat3Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        
        let cat4Arr1:NSArray = NSArray.init(arrayLiteral: self.getAddressBtn, self.getDeviceCheckCodeBtn, self.signAbortBtn)
        cat4Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat4Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat4Arr2:NSArray = NSArray.init(arrayLiteral: self.ethSignBtn, self.eosSignBtn, self.cybSignBtn)
        cat4Arr2.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat4Arr2.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.getDevInfoBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat4Arr3:NSArray = NSArray.init(arrayLiteral: self.ethSignNewBtn, self.eosSignNewBtn, self.cybSignNewBtn)
        cat4Arr3.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat4Arr3.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.changePinBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat4Arr4:NSArray = NSArray.init(arrayLiteral: self.btcSignBtn, self.erc20SignBtn, self.etcSignBtn)
        cat4Arr4.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat4Arr4.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.ethSignNewBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat4Arr5:NSArray = NSArray.init(arrayLiteral: self.switchSignBtn, self.abortButtonBtn2)
        cat4Arr5.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat4Arr5.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.btcSignBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        
        let cat5Arr1:NSArray = NSArray.init(arrayLiteral: self.getImageListBtn, self.setImageNameBtn, self.getImageNameBtn)
        cat5Arr1.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat5Arr1.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.deviceCategoryBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        let cat5Arr2:NSArray = NSArray.init(arrayLiteral: self.setImageDataBtn, self.showImageBtn, self.setLogoImageBtn)
        cat5Arr2.mas_distributeViews(along: MASAxisType.horizontal, withFixedSpacing: CGFloat(10), leadSpacing: CGFloat(30), tailSpacing: CGFloat(30))
        cat5Arr2.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.getDevInfoBtn.mas_bottom)?.offset()(LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
        })
        
        self.view.addSubview(self.clearLogBtn)
        clearLogBtn.mas_makeConstraints ({ (make:MASConstraintMaker!) in
            make.bottom.mas_equalTo()(self.view.mas_bottom)?.offset()(-LINESPACING)
            make.height.mas_equalTo()(BUTTONHEIGHT)
            make.left.mas_equalTo()(self.initPinBtn.mas_left);
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
        case imageCategoryBtn:
            self.showCategory(imageCategoryList)
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
            let devInfoType: CUnsignedInt = CUnsignedInt(PAEW_DEV_INFOTYPE_COS_TYPE | PAEW_DEV_INFOTYPE_COS_VERSION | PAEW_DEV_INFOTYPE_SN | PAEW_DEV_INFOTYPE_CHAIN_TYPE | PAEW_DEV_INFOTYPE_PIN_STATE | PAEW_DEV_INFOTYPE_LIFECYCLE | PAEW_DEV_INFOTYPE_BLE_VERSION)
            var devInfo = PAEW_DevInfo.init()
            let iRtn = PAEW_GetDevInfo(pPAEWContext, devIdx, devInfoType, &devInfo)
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetDevInfo returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            self.printLog("ucPINState: %hh02X", devInfo.ucPINState)
            self.printLog("ucCOSType: %hh02X", devInfo.ucCOSType)
            
            let namePtr = UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(devInfo.pbSerialNumber), {return $0}).bindMemory(to: byte.self).baseAddress)!
            
            for i in 0..<PAEW_DEV_INFO_SN_LEN {
                if namePtr.advanced(by: Int(i)).pointee == 0xFF {
                    namePtr.advanced(by: Int(i)).pointee = 0
                }
            }
            let cosVersionPtr = withUnsafeBytes(of: &(devInfo.pbCOSVersion), {return $0}).bindMemory(to: byte.self).baseAddress!
            let bleVersionPtr = withUnsafeBytes(of: &(devInfo.pbBLEVersion), {return $0}).bindMemory(to: byte.self).baseAddress!
            self.printLog("Serial Number: \(String.init(cString: namePtr))")
            self.printLog("COS Version: \(Utils.bytesToHexString(data: cosVersionPtr, length: MemoryLayout.size(ofValue: devInfo.pbCOSVersion)))")
            self.printLog("BLE Version: \(Utils.bytesToHexString(data: bleVersionPtr, length: MemoryLayout.size(ofValue: devInfo.pbBLEVersion)))")
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
        self.abortButtonFlag = false
        self.lastButtonState = PAEW_RET_SUCCESS;
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_InitPIN_Ex")
            let iRtn = PAEW_InitPIN_Ex(pPAEWContext, devIdx, newpin.cString(using: String.Encoding.utf8), self.putStateCallback, nil)
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_InitPIN_Ex returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_InitPIN_Ex returns success")
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
        
        self.abortButtonFlag = false
        self.lastButtonState = PAEW_RET_SUCCESS;
        DispatchQueue.global(qos: .default).async {
            self.printLog("ready to call PAEW_ChangePIN_Input_Ex")
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let iRtn = PAEW_ChangePIN_Input_Ex(pPAEWContext, devIdx, oldpin.cString(using: String.Encoding.utf8), newpin.cString(using: String.Encoding.utf8), self.putStateCallback, nil)
            
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ChangePIN_Input_Ex returns failed: : \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_ChangePIN_Input_Ex returns success")
        }
    }
    
    @IBAction func formatBtnAction(sender: UIButton) {
        self.abortButtonFlag = false
        self.lastButtonState = PAEW_RET_SUCCESS;
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_Format_Ex")
            let iRtn = PAEW_Format_Ex(pPAEWContext, devIdx, self.putStateCallback, nil)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_Format_Ex returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_Format_Ex returns success")
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
    
    @IBAction func updateCOSBtnAction (sender: UIButton) {
        let bRestart = PickerViewAlert.doModal(parent: self, title: "Please select update type", dataSource: ["Resume", "Restart"])
        guard bRestart >= 0 else {
            return
        }
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            let filePath = path + "/WOOKONG_BIO_COS.bin"
            guard FileManager.default.fileExists(atPath: filePath) else {
                self.printLog("WOOKONG_BIO_COS.bin does not exists")
                return
            }
            let readHandler =  FileHandle(forReadingAtPath: filePath)
            guard let aHandler = readHandler else {
                self.printLog("WOOKONG_BIO_COS.bin read failed")
                return
            }
            let data = aHandler.readDataToEndOfFile()
            let dataPtr = data.withUnsafeBytes({ (ptr: UnsafePointer<byte>) -> UnsafePointer<byte> in
                return ptr
            })
            self.printLog("ready to call PAEW_ClearCOS")
            var iRtn = PAEW_ClearCOS(pPAEWContext, devIdx)
            if iRtn == PAEW_RET_SUCCESS {
                self.printLog("PAEW_ClearCOS returns success")
                //MUST sleep at least 5 seconds after clearcos succeeded
                Thread.sleep(forTimeInterval: 5.000)
            } else {
                self.printLog("PAEW_ClearCOS returns failed: %@", Utils.errorCodeToString(iRtn))
            }
            self.printLog("ready to call PAEW_UpdateCOS_Ex")
            self.updateProgress = 0
            let starttime = Date.init()
            iRtn = PAEW_UpdateCOS_Ex(pPAEWContext, devIdx, UInt8(bRestart), dataPtr, data.count, self.progressCallback, nil)
            let endtime = Date.init()
            let timeNumber = Int(endtime.timeIntervalSince1970 - starttime.timeIntervalSince1970)
            self.printLog("PAEW_UpdateCOS_Ex costs \(timeNumber) senconds")
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_UpdateCOS_Ex returns failed: %@", Utils.errorCodeToString(iRtn))
                return
            }
            self.printLog("PAEW_UpdateCOS_Ex returns success")
            //MUST sleep at least 5 seconds after updatecos succeeded
            Thread.sleep(forTimeInterval: 5.000)
            //MUST reconnect after update complete
            self.freeContextBtnAction(sender: self.freeContextBtn)
        }
    }
    
    @IBAction func abortButtonBtnAction(sender: UIButton) {
        self.abortButtonFlag = true
    }
    
    @IBAction func getBatteryStateBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            var batteryValue:[byte] = [0, 0]
            var batteryValueLen:Int = batteryValue.count
            self.printLog("ready to call PAEW_GetBatteryValue")
            let iRtn = PAEW_GetBatteryValue(pPAEWContext, devIdx, &batteryValue, &batteryValueLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetBatteryValue returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_GetBatteryValue returns success, power source is: %hh02X, battery level is 0x%hh02X", batteryValue[0], batteryValue[1])
        }
    }
    
    @IBAction func getFWVersionBtnAction(sender: UIButton) {
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            var version = PAEW_FWVersion()
            self.printLog("ready to call PAEW_GetFWVersion")
            let iRtn = PAEW_GetFWVersion(pPAEWContext, devIdx, &version)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetFWVersion returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            let algVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbAlgVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: version.nAlgVersionLen
            )
            let majorVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbMajorVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: MemoryLayout.size(ofValue: version.pbMajorVersion)
            )
            let minorVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbMinorVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: MemoryLayout.size(ofValue: version.pbMinorVersion)
            )
            let loaderVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbLoaderVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: MemoryLayout.size(ofValue: version.pbLoaderVersion)
            )
            let loaderChipVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbLoaderChipVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: MemoryLayout.size(ofValue: version.pbLoaderChipVersion)
            )
            let userChipVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbUserChipVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: MemoryLayout.size(ofValue: version.pbUserChipVersion)
            )
            let bleVer = Utils.bytesToHexString(
                data: UnsafeMutablePointer<byte>.init(mutating: withUnsafeBytes(of: &(version.pbBLEVersion), {return $0}).bindMemory(to: byte.self).baseAddress)!,
                length: MemoryLayout.size(ofValue: version.pbUserChipVersion)
            )
            
            self.printLog("PAEW_GetFWVersion returns success, algVer is %@, majorVer is %@, minorVer is %@, loaderChipVer is %@, loaderVer is %@, userChipVer is %@, bleVersion is %@, isUserFW: %hh02X", algVer, majorVer, minorVer, loaderChipVer, loaderVer, userChipVer, bleVer, version.nIsUserFW);
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
                    self.abortFPBlock!(true)
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
                    self.abortFPBlock!(true)
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
    
    @IBAction func recoverSeedBtnAction(sender: UIButton) {
        //the following APIs are all implemented by software, so they could also be called in the main thread
        DispatchQueue.global(qos: .default).async {
            let mnemonics = "mass dust captain baby mass dust captain baby mass dust captain baby mass dust captain baby mass electric"
            var mnemonicsData = mnemonics.cString(using: String.Encoding.utf8)
            let mnemonicsPtr = mnemonicsData!.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> UnsafeMutablePointer<byte> in
                return ptr.bindMemory(to: byte.self).baseAddress!
            })
            var seedLen:size_t = 64
            var seedData = Data.init(count: seedLen)
            let seedPtr = seedData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            let prvKeyLen:size_t = 1024
            var currentPrvKeyLen = prvKeyLen
            var prvKeyData = Data.init(count: prvKeyLen)
            let prvKeyPtr = prvKeyData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            let addressLen:size_t = 1024
            var currentAddressLen = addressLen
            var addressData = Data.init(count: addressLen)
            let addressPtr = addressData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            self.printLog("ready to call PAEW_RecoverSeedFromMne")
            var iRtn = PAEW_RecoverSeedFromMne( mnemonicsPtr, mnemonics.count, seedPtr, &seedLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_RecoverSeedFromMne returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            self.printLog("seed is: \(Utils.bytesToHexString(data: seedPtr, length: seedLen))")
            self.printLog("PAEW_RecoverSeedFromMne returns success")
            
            self.printLog("ready to call PAEW_GetTradeAddressFromSeed")
            iRtn = PAEW_GetTradeAddressFromSeed(seedPtr, seedLen, self.puiDerivePathETH.withUnsafeBufferPointer({return $0.baseAddress!}), self.puiDerivePathETH.count, prvKeyPtr, &currentPrvKeyLen, 0, UInt8(PAEW_COIN_TYPE_ETH), addressPtr, &currentAddressLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetTradeAddressFromSeed on ETH returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_GetTradeAddressFromSeed on ETH returns scuuess, prvKey is \(Utils.bytesToHexString(data: prvKeyPtr, length: currentPrvKeyLen)) ,address is 0x\(String.init(cString: addressPtr))")
            
            currentAddressLen = addressLen
            currentPrvKeyLen = prvKeyLen
            memset(prvKeyPtr, 0, currentPrvKeyLen)
            memset(addressPtr, 0, currentAddressLen)
            self.printLog("ready to call PAEW_GetTradeAddressFromSeed")
            iRtn = PAEW_GetTradeAddressFromSeed(seedPtr, seedLen, self.puiDerivePathEOS.withUnsafeBufferPointer({return $0.baseAddress!}), self.puiDerivePathEOS.count, prvKeyPtr, &currentPrvKeyLen, 0, UInt8(PAEW_COIN_TYPE_EOS), addressPtr, &currentAddressLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetTradeAddressFromSeed on EOS returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_GetTradeAddressFromSeed on EOS returns scuuess, prvKey is \(Utils.bytesToHexString(data: prvKeyPtr, length: currentPrvKeyLen)) ,address is \(String.init(cString: addressPtr))")
            
            currentAddressLen = addressLen
            currentPrvKeyLen = prvKeyLen
            memset(prvKeyPtr, 0, currentPrvKeyLen)
            memset(addressPtr, 0, currentAddressLen)
            self.printLog("ready to call PAEW_GetTradeAddressFromSeed")
            iRtn = PAEW_GetTradeAddressFromSeed(seedPtr, seedLen, self.puiDerivePathCYB.withUnsafeBufferPointer({return $0.baseAddress!}), self.puiDerivePathCYB.count, prvKeyPtr, &currentPrvKeyLen, 0, UInt8(PAEW_COIN_TYPE_CYB), addressPtr, &currentAddressLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetTradeAddressFromSeed on CYB returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_GetTradeAddressFromSeed on CYB returns scuuess, prvKey is \(Utils.bytesToHexString(data: prvKeyPtr, length: currentPrvKeyLen)) ,address is \(String.init(cString: addressPtr))")
        }
    }
    
    /*
     // MARK: - Wallet actions
     */
    
    @IBAction func getAddressBtnAction(sender: UIButton) -> () {
        let coinNames = ["ETH", "EOS", "CYB"]
        let coinTypes = [PAEW_COIN_TYPE_ETH, PAEW_COIN_TYPE_EOS, PAEW_COIN_TYPE_CYB]
        let selectedCoin = PickerViewAlert.doModal(parent: self, title: "please select coin type", dataSource: coinNames)
        if selectedCoin == -1 {
            return
        }
        guard selectedCoin >= 0 && selectedCoin <= 2 else {
            self.printLog("invalid coin type: \(selectedCoin)")
            return
        }
        let coinType = byte(coinTypes[selectedCoin])
        let coinName = coinNames[selectedCoin]
        
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
        let derivePath:[CUnsignedInt]
        
        switch coinName {
        case "ETH":
            derivePath = puiDerivePathETH
        case "EOS":
            derivePath = puiDerivePathEOS
        case "CYB":
            derivePath = puiDerivePathCYB
        default:
            derivePath = [0]
        }
        let pathLen: size_t = derivePath.count
        
        self.abortButtonFlag = false
        self.lastButtonState = PAEW_RET_SUCCESS;
        DispatchQueue.global(qos: .default).async {
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let devIdx = 0
            self.printLog("ready to call PAEW_DeriveTradeAddress")
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), pathLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_DeriveTradeAddress on coin type \(coinName) returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_DeriveTradeAddress returns success")
            var addressLen = 1024
            var addressData = Data.init(count: addressLen)
            let addressPtr = addressData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            self.printLog("ready to call PAEW_GetTradeAddress_Ex")
            iRtn = PAEW_GetTradeAddress_Ex(pPAEWContext, devIdx, coinType, showType, addressPtr, &addressLen, self.putStateCallback, nil)
            if showType != 0 {
                //if show address on screen, clear screen and show logo when getaddr completed
                PAEW_ShowImage(pPAEWContext, devIdx, 0, UInt8(PAEW_LCD_CLEAR_SHOW_LOGO))
            }
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetTradeAddress_Ex on coin type \(coinName) returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            let address = String.init(cString: addressPtr)
            self.printLog("PAEW_GetTradeAddress_Ex on coin type \(coinName) returns success, address is \(address)")
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
        self.abortSignFlag = true
    }
    
    @IBAction func ethSignBtnAction(sender: UIButton) {
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
            let coinType = byte(PAEW_COIN_TYPE_ETH)
            let derivePath = self.puiDerivePathETH
            self.printLog("ready to call PAEW_ETH_TXSign_Ex")
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ETH_TXSign_Ex failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            let transaction: [UInt8] = [byte(0xec), byte(0x09), byte(0x85), byte(0x04), byte(0xa8),
                                        byte(0x17), byte(0xc8), byte(0x00), byte(0x82), byte(0x52),
                                        byte(0x08), byte(0x94), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x88), byte(0x0d), byte(0xe0),
                                        byte(0xb6), byte(0xb3), byte(0xa7), byte(0x64), byte(0x00),
                                        byte(0x00), byte(0x80), byte(0x01), byte(0x80), byte(0x80)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            var callback = signCallbacks.init(getAuthType: self.getAuthTypeCallback, getPIN: self.getPINCallback, putSignState: self.putSignStateCallback)
            self.lastSignState = PAEW_RET_SUCCESS
            iRtn = PAEW_ETH_TXSign_Ex(pPAEWContext, devIdx, transaction, transaction.count, sigPtr, &sigLen, &callback, nil)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ETH_TXSign_Ex returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("ETH signature is: \(Utils.bytesToHexString(data: sigPtr, length: sigLen))")
            self.printLog("PAEW_ETH_TXSign_Ex returns success")
        }
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
    
    @IBAction func cybSignBtnAction(sender: UIButton) {
        self.abortBtnState = false
        var rtn = self.getAuthType()
        guard rtn == PAEW_RET_SUCCESS else {
            self.printLog("user canceled PAEW_CYB_TXSign_Ex")
            return
        }
        
        if self.nAuthType == PAEW_SIGN_AUTH_TYPE_PIN {
            rtn = self.getPIN()
            guard rtn == PAEW_RET_SUCCESS else {
                self.printLog("user canceled PAEW_CYB_TXSign_Ex")
                return
            }
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_CYB)
            let derivePath = self.puiDerivePathCYB
            self.printLog("ready to call PAEW_CYB_TXSign_Ex")
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_CYB_TXSign_Ex failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            let transaction: [byte] = [byte(0x26), byte(0xe9), byte(0xbf), byte(0x22), byte(0x06),
                                       byte(0xa1), byte(0xd1), byte(0x5c), byte(0x7e), byte(0x5b),
                                       byte(0x01), byte(0x00), byte(0xe8), byte(0x03), byte(0x00),
                                       byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                       byte(0x00), byte(0x80), byte(0xaf), byte(0x02), byte(0x80),
                                       byte(0xaf), byte(0x02), byte(0x0a), byte(0x00), byte(0x00),
                                       byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                       byte(0x00), byte(0x00), byte(0x01), byte(0x04), byte(0x0a),
                                       byte(0x7a), byte(0x68), byte(0x61), byte(0x6e), byte(0x67),
                                       byte(0x73), byte(0x79), byte(0x31), byte(0x33), byte(0x33),
                                       byte(0x03), byte(0x43), byte(0x59), byte(0x42), byte(0x03),
                                       byte(0x43), byte(0x59), byte(0x42), byte(0x05), byte(0x05),
                                       byte(0x00)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            var callback = signCallbacks.init(getAuthType: self.getAuthTypeCallback, getPIN: self.getPINCallback, putSignState: self.putSignStateCallback)
            self.lastSignState = PAEW_RET_SUCCESS
            iRtn = PAEW_CYB_TXSign_Ex(pPAEWContext, devIdx, transaction, transaction.count, sigPtr, &sigLen, &callback, nil)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_CYB_TXSign_Ex returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("CYB signature is: \(Utils.bytesToHexString(data: sigPtr, length: sigLen))")
            self.printLog("PAEW_CYB_TXSign_Ex returns success")
        }
    }
    
    @IBAction func ethSignNewBtnAction(sender: UIButton) {
        self.switchSignFlag = false
        self.abortSignFlag = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_ETH)
            let derivePath = self.puiDerivePathETH
            self.printLog("ready for eth signature")
            var authType: UInt8 = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
            var pinVerified = false
            
            let transaction: [UInt8] = [byte(0xec), byte(0x09), byte(0x85), byte(0x04), byte(0xa8),
                                        byte(0x17), byte(0xc8), byte(0x00), byte(0x82), byte(0x52),
                                        byte(0x08), byte(0x94), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x35), byte(0x35), byte(0x35),
                                        byte(0x35), byte(0x35), byte(0x88), byte(0x0d), byte(0xe0),
                                        byte(0xb6), byte(0xb3), byte(0xa7), byte(0x64), byte(0x00),
                                        byte(0x00), byte(0x80), byte(0x01), byte(0x80), byte(0x80)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("eth signature failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            iRtn = PAEW_ETH_SetTX(pPAEWContext, devIdx, transaction, transaction.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("eth signature failed due to PAEW_ETH_SetTX returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var lastResult: UInt32 = UInt32(PAEW_RET_SUCCESS)
            var lastAuthType = authType
            
            var needAbort = false
            
            self.printLog("default auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
            while true {
                //check abort sign flag
                if self.abortSignFlag {
                    self.abortSignFlag = false
                    iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                    if iRtn == PAEW_RET_SUCCESS {
                        self.printLog("eth signature abort")
                        needAbort = false
                        break
                    } else {
                        self.printLog("PAEW_AbortSign returns failed: \(Utils.errorCodeToString(iRtn))")
                        needAbort = true
                        break
                    }
                }
                //check switch sign flag
                if self.switchSignFlag {
                    self.switchSignFlag = false
                    if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_PIN)
                    } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                    }
                    //clear last getsign result
                    lastResult = UInt32(PAEW_RET_SUCCESS)
                    pinVerified = false
                }
                
                if lastAuthType != authType {
                    if authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN  {
                        let type = PickerViewAlert.doModal(parent: self, title: "Please select verify method", dataSource: ["Fingerprint", "PIN"])
                        guard type >= 0 else {
                            self.printLog("user canceled")
                            needAbort = true
                            break
                        }
                        authType = UInt8(type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN)
                    }
                    lastAuthType = authType
                    self.printLog("auth type changed, current auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
                    iRtn = PAEW_SwitchSign(pPAEWContext, devIdx)
                }
                //if auth type is PIN, PAEW_VerifySignPIN must be called
                if authType == PAEW_SIGN_AUTH_TYPE_PIN && (!pinVerified) {
                    let aPin = TextFieldViewAlert.doModal(parent: self, title: "Please input PIN", message: "Please input your PIN to continue", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
                    guard let pin = aPin else {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                        pinVerified = false
                        self.printLog("user canceled PIN input")
                        continue
                    }
                    iRtn = PAEW_VerifySignPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
                    guard iRtn == PAEW_RET_SUCCESS else {
                        pinVerified = false
                        self.printLog("PAEW_VerifySignPIN returns failed: \(Utils.errorCodeToString(iRtn))")
                        continue
                    }
                    pinVerified = true
                }
                
                //after all, loop to get sign result
                iRtn = PAEW_ETH_GetSignResult(pPAEWContext, devIdx, authType, sigPtr, &sigLen)
                
                if iRtn == PAEW_RET_SUCCESS {
                    self.printLog("ETH signature succeeded with signature: \(Utils.bytesToHexString(data: sigPtr, length: sigLen))")
                    needAbort = false
                    break
                } else if lastResult != UInt32(bitPattern: iRtn) {
                    self.printLog("\(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN") signature status : \(Utils.errorCodeToString(iRtn))")
                    lastResult = UInt32(bitPattern: iRtn)
                    //notify here: loop for pin and loop for fp have different loop conditions
                    if authType == PAEW_SIGN_AUTH_TYPE_FP {
                        if lastResult == PAEW_RET_NO_VERIFY_COUNT {
                            //like wechat, if fp verify count ran out, switch to pin verify
                            self.switchSignFlag = true
                            continue
                        }
                        if lastResult != PAEW_RET_DEV_WAITING
                            && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                            && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                            && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER {
                            self.printLog("ETH signature failed")
                            needAbort = true
                            break
                        }
                    } else if authType == PAEW_SIGN_AUTH_TYPE_PIN {
                        if lastResult != PAEW_RET_DEV_WAITING {
                            self.printLog("ETH signature failed")
                            needAbort = true
                            break
                        }
                    }
                }
            }
            //finally, call abort if PAEW_ETH_GetSignResult returns non PAEW_RET_SUCCESS values
            if needAbort {
                iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
            }
        }
    }
    
    @IBAction func eosSignNewBtnAction(sender: UIButton) {
        self.switchSignFlag = false
        self.abortSignFlag = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_EOS)
            let derivePath = self.puiDerivePathEOS
            self.printLog("ready for eos signature")
            var authType: UInt8 = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
            var pinVerified = false
            
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
            
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("EOS signature failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            iRtn = PAEW_EOS_SetTX(pPAEWContext, devIdx, transaction, transaction.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("EOS signature failed due to PAEW_EOS_SetTX returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var lastResult: UInt32 = UInt32(PAEW_RET_SUCCESS)
            var lastAuthType = authType
            
            var needAbort = false
            
            self.printLog("default auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
            while true {
                //check abort sign flag
                if self.abortSignFlag {
                    self.abortSignFlag = false
                    iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                    if iRtn == PAEW_RET_SUCCESS {
                        self.printLog("EOS signature abort")
                        needAbort = false
                        break
                    } else {
                        self.printLog("PAEW_AbortSign returns failed: \(Utils.errorCodeToString(iRtn))")
                        needAbort = true
                        break
                    }
                }
                //check switch sign flag
                if self.switchSignFlag {
                    self.switchSignFlag = false
                    if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_PIN)
                    } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                    }
                    //clear last getsign result
                    lastResult = UInt32(PAEW_RET_SUCCESS)
                    pinVerified = false
                }
                
                if lastAuthType != authType {
                    if authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN  {
                        let type = PickerViewAlert.doModal(parent: self, title: "Please select verify method", dataSource: ["Fingerprint", "PIN"])
                        guard type >= 0 else {
                            self.printLog("user canceled")
                            needAbort = true
                            break
                        }
                        authType = UInt8(type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN)
                    }
                    lastAuthType = authType
                    self.printLog("auth type changed, current auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
                    iRtn = PAEW_SwitchSign(pPAEWContext, devIdx)
                }
                //if auth type is PIN, PAEW_VerifySignPIN must be called
                if authType == PAEW_SIGN_AUTH_TYPE_PIN && (!pinVerified) {
                    let aPin = TextFieldViewAlert.doModal(parent: self, title: "Please input PIN", message: "Please input your PIN to continue", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
                    guard let pin = aPin else {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                        pinVerified = false
                        self.printLog("user canceled PIN input")
                        continue
                    }
                    iRtn = PAEW_VerifySignPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
                    guard iRtn == PAEW_RET_SUCCESS else {
                        pinVerified = false
                        self.printLog("PAEW_VerifySignPIN returns failed: \(Utils.errorCodeToString(iRtn))")
                        continue
                    }
                    pinVerified = true
                }
                
                //after all, loop to get sign result
                iRtn = PAEW_EOS_GetSignResult(pPAEWContext, devIdx, authType, sigPtr, &sigLen)
                
                if iRtn == PAEW_RET_SUCCESS {
                    self.printLog("EOS signature succeeded with signature: %s", sigPtr)
                    needAbort = false
                    break
                } else if lastResult != UInt32(bitPattern: iRtn) {
                    self.printLog("\(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN") signature status : \(Utils.errorCodeToString(iRtn))")
                    lastResult = UInt32(bitPattern: iRtn)
                    //notify here: loop for pin and loop for fp have different loop conditions
                    if authType == PAEW_SIGN_AUTH_TYPE_FP {
                        if lastResult == PAEW_RET_NO_VERIFY_COUNT {
                            //like wechat, if fp verify count ran out, switch to pin verify
                            self.switchSignFlag = true
                            continue
                        }
                        if lastResult != PAEW_RET_DEV_WAITING
                            && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                            && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                            && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER {
                            self.printLog("EOS signature failed")
                            needAbort = true
                            break
                        }
                    } else if authType == PAEW_SIGN_AUTH_TYPE_PIN {
                        if lastResult != PAEW_RET_DEV_WAITING {
                            self.printLog("EOS signature failed")
                            needAbort = true
                            break
                        }
                    }
                }
            }
            //finally, call abort if PAEW_EOS_GetSignResult returns non PAEW_RET_SUCCESS values
            if needAbort {
                iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
            }
        }
    }
    
    @IBAction func cybSignNewBtnAction(sender: UIButton) {
        self.switchSignFlag = false
        self.abortSignFlag = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_CYB)
            let derivePath = self.puiDerivePathCYB
            self.printLog("ready for cyb signature")
            var authType: UInt8 = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
            var pinVerified = false
            
            let transaction: [UInt8] = [byte(0x26), byte(0xe9), byte(0xbf), byte(0x22), byte(0x06),
                                        byte(0xa1), byte(0xd1), byte(0x5c), byte(0x7e), byte(0x5b),
                                        byte(0x01), byte(0x00), byte(0xe8), byte(0x03), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x80), byte(0xaf), byte(0x02), byte(0x80),
                                        byte(0xaf), byte(0x02), byte(0x0a), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x01), byte(0x04), byte(0x0a),
                                        byte(0x7a), byte(0x68), byte(0x61), byte(0x6e), byte(0x67),
                                        byte(0x73), byte(0x79), byte(0x31), byte(0x33), byte(0x33),
                                        byte(0x03), byte(0x43), byte(0x59), byte(0x42), byte(0x03),
                                        byte(0x43), byte(0x59), byte(0x42), byte(0x05), byte(0x05),
                                        byte(0x00)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("cyb signature failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            iRtn = PAEW_CYB_SetTX(pPAEWContext, devIdx, transaction, transaction.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("cyb signature failed due to PAEW_CYB_SetTX returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var lastResult: UInt32 = UInt32(PAEW_RET_SUCCESS)
            var lastAuthType = authType
            
            var needAbort = false
            
            self.printLog("default auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
            while true {
                //check abort sign flag
                if self.abortSignFlag {
                    self.abortSignFlag = false
                    iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                    if iRtn == PAEW_RET_SUCCESS {
                        self.printLog("cyb signature abort")
                        needAbort = false
                        break
                    } else {
                        self.printLog("PAEW_AbortSign returns failed: \(Utils.errorCodeToString(iRtn))")
                        needAbort = true
                        break
                    }
                }
                //check switch sign flag
                if self.switchSignFlag {
                    self.switchSignFlag = false
                    if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_PIN)
                    } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                    }
                    //clear last getsign result
                    lastResult = UInt32(PAEW_RET_SUCCESS)
                    pinVerified = false
                }
                
                if lastAuthType != authType {
                    if authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN  {
                        let type = PickerViewAlert.doModal(parent: self, title: "Please select verify method", dataSource: ["Fingerprint", "PIN"])
                        guard type >= 0 else {
                            self.printLog("user canceled")
                            needAbort = true
                            break
                        }
                        authType = UInt8(type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN)
                    }
                    lastAuthType = authType
                    self.printLog("auth type changed, current auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
                    iRtn = PAEW_SwitchSign(pPAEWContext, devIdx)
                }
                //if auth type is PIN, PAEW_VerifySignPIN must be called
                if authType == PAEW_SIGN_AUTH_TYPE_PIN && (!pinVerified) {
                    let aPin = TextFieldViewAlert.doModal(parent: self, title: "Please input PIN", message: "Please input your PIN to continue", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
                    guard let pin = aPin else {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                        pinVerified = false
                        self.printLog("user canceled PIN input")
                        continue
                    }
                    iRtn = PAEW_VerifySignPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
                    guard iRtn == PAEW_RET_SUCCESS else {
                        pinVerified = false
                        self.printLog("PAEW_VerifySignPIN returns failed: \(Utils.errorCodeToString(iRtn))")
                        continue
                    }
                    pinVerified = true
                }
                
                //after all, loop to get sign result
                iRtn = PAEW_CYB_GetSignResult(pPAEWContext, devIdx, authType, sigPtr, &sigLen)
                
                if iRtn == PAEW_RET_SUCCESS {
                    self.printLog("CYB signature succeeded with signature: \(Utils.bytesToHexString(data: sigPtr, length: sigLen))")
                    needAbort = false
                    break
                } else if lastResult != UInt32(bitPattern: iRtn) {
                    self.printLog("\(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN") signature status : \(Utils.errorCodeToString(iRtn))")
                    lastResult = UInt32(bitPattern: iRtn)
                    //notify here: loop for pin and loop for fp have different loop conditions
                    if authType == PAEW_SIGN_AUTH_TYPE_FP {
                        if lastResult == PAEW_RET_NO_VERIFY_COUNT {
                            //like wechat, if fp verify count ran out, switch to pin verify
                            self.switchSignFlag = true
                            continue
                        }
                        if lastResult != PAEW_RET_DEV_WAITING
                            && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                            && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                            && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER {
                            self.printLog("CYB signature failed")
                            needAbort = true
                            break
                        }
                    } else if authType == PAEW_SIGN_AUTH_TYPE_PIN {
                        if lastResult != PAEW_RET_DEV_WAITING {
                            self.printLog("CYB signature failed")
                            needAbort = true
                            break
                        }
                    }
                }
            }
            //finally, call abort if PAEW_CYB_GetSignResult returns non PAEW_RET_SUCCESS values
            if needAbort {
                iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
            }
        }
    }
    
    @IBAction func btcSignBtnAction(sender: UIButton) {
        self.switchSignFlag = false
        self.abortSignFlag = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_BTC)
            let derivePath = self.puiDerivePathBTC
            self.printLog("ready for btc signature")
            var authType: UInt8 = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
            var pinVerified = false
            
            let nUTXOCount = 2
            let utxo1: [UInt8] = [byte(0x01), byte(0x00), byte(0x00), byte(0x00), byte(0x03), byte(0xe0), byte(0xb1), byte(0x1a), byte(0x95), byte(0x15), byte(0xee), byte(0x6d), byte(0x6b), byte(0x54), byte(0x08), byte(0xaf), byte(0x88), byte(0x1d), byte(0x6e), byte(0x44), byte(0x75), byte(0xdd), byte(0xbd), byte(0x4f), byte(0x4c), byte(0xab), byte(0xcf), byte(0xfa), byte(0x73), byte(0x00), byte(0xfc), byte(0x95), byte(0x36), byte(0x7f), byte(0xe5), byte(0x3f), byte(0xd0), byte(0x01), byte(0x00), byte(0x00), byte(0x00), byte(0x6b), byte(0x48), byte(0x30), byte(0x45), byte(0x02), byte(0x21), byte(0x00), byte(0xd7), byte(0xe8), byte(0x36), byte(0x51), byte(0x9e), byte(0x2b), byte(0x08), byte(0x5c), byte(0xae), byte(0x1c), byte(0xe9), byte(0xc4), byte(0xee), byte(0x45), byte(0x66), byte(0xe1), byte(0x4c), byte(0x31), byte(0xcf), byte(0x27), byte(0x6e), byte(0xbc), byte(0x78), byte(0xd4), byte(0x5b), byte(0x86), byte(0x55), byte(0xf8), byte(0x4f), byte(0x76), byte(0x3e), byte(0x5c), byte(0x02), byte(0x20), byte(0x4f), byte(0xb4), byte(0x83), byte(0xa7), byte(0xa4), byte(0xe5), byte(0xf1), byte(0x00), byte(0xcb), byte(0xcd), byte(0xd2), byte(0x23), byte(0xf3), byte(0xc2), byte(0x18), byte(0x20), byte(0xd9), byte(0xe8), byte(0xc9), byte(0xf6), byte(0xa6), byte(0x7f), byte(0x2b), byte(0x06), byte(0xbd), byte(0x52), byte(0xde), byte(0xf4), byte(0x66), byte(0x34), byte(0xba), byte(0xd9), byte(0x01), byte(0x21), byte(0x03), byte(0x95), byte(0xe0), byte(0x57), byte(0x1b), byte(0x44), byte(0x1e), byte(0x0f), byte(0x2f), byte(0xd9), byte(0x32), byte(0x90), byte(0x6a), byte(0x3f), byte(0xd6), byte(0x8a), byte(0x57), byte(0x09), byte(0x8a), byte(0x55), byte(0x52), byte(0xdd), byte(0x62), byte(0xe2), byte(0x23), byte(0x87), byte(0x13), byte(0x9b), byte(0x1f), byte(0x60), byte(0x78), byte(0x22), byte(0x3d), byte(0xff), byte(0xff), byte(0xff), byte(0xff), byte(0xe0), byte(0xb1), byte(0x1a), byte(0x95), byte(0x15), byte(0xee), byte(0x6d), byte(0x6b), byte(0x54), byte(0x08), byte(0xaf), byte(0x88), byte(0x1d), byte(0x6e), byte(0x44), byte(0x75), byte(0xdd), byte(0xbd), byte(0x4f), byte(0x4c), byte(0xab), byte(0xcf), byte(0xfa), byte(0x73), byte(0x00), byte(0xfc), byte(0x95), byte(0x36), byte(0x7f), byte(0xe5), byte(0x3f), byte(0xd0), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x6a), byte(0x47), byte(0x30), byte(0x44), byte(0x02), byte(0x20), byte(0x5e), byte(0xfa), byte(0x77), byte(0x19), byte(0xce), byte(0x8d), byte(0xb5), byte(0x45), byte(0x4c), byte(0x55), byte(0xc2), byte(0x1a), byte(0x97), byte(0xe8), byte(0x9e), byte(0xce), byte(0xe2), byte(0x0e), byte(0x16), byte(0x7b), byte(0x84), byte(0x81), byte(0x63), byte(0x22), byte(0x5a), byte(0x30), byte(0xb6), byte(0x30), byte(0xb2), byte(0xab), byte(0xb8), byte(0x70), byte(0x02), byte(0x20), byte(0x12), byte(0xa2), byte(0x4d), byte(0xf9), byte(0xf0), byte(0xc7), byte(0x64), byte(0x84), byte(0x3b), byte(0x8e), byte(0xe5), byte(0x8a), byte(0x56), byte(0x63), byte(0x2f), byte(0xc8), byte(0x4b), byte(0xda), byte(0x23), byte(0xcc), byte(0xf7), byte(0xa7), byte(0x4c), byte(0xad), byte(0xe9), byte(0x45), byte(0xe7), byte(0xc1), byte(0x67), byte(0x96), byte(0xa4), byte(0x27), byte(0x01), byte(0x21), byte(0x03), byte(0x95), byte(0xe0), byte(0x57), byte(0x1b), byte(0x44), byte(0x1e), byte(0x0f), byte(0x2f), byte(0xd9), byte(0x32), byte(0x90), byte(0x6a), byte(0x3f), byte(0xd6), byte(0x8a), byte(0x57), byte(0x09), byte(0x8a), byte(0x55), byte(0x52), byte(0xdd), byte(0x62), byte(0xe2), byte(0x23), byte(0x87), byte(0x13), byte(0x9b), byte(0x1f), byte(0x60), byte(0x78), byte(0x22), byte(0x3d), byte(0xff), byte(0xff), byte(0xff), byte(0xff), byte(0x09), byte(0xfb), byte(0x2c), byte(0xc0), byte(0xa8), byte(0x73), byte(0x80), byte(0x0b), byte(0x67), byte(0xfb), byte(0x14), byte(0x39), byte(0x83), byte(0xf6), byte(0x6d), byte(0x7a), byte(0x02), byte(0xa6), byte(0xfb), byte(0x74), byte(0x02), byte(0x35), byte(0x6c), byte(0x64), byte(0x24), byte(0x67), byte(0x20), byte(0xf3), byte(0x1f), byte(0xb9), byte(0xee), byte(0xaf), byte(0x01), byte(0x00), byte(0x00), byte(0x00), byte(0x6a), byte(0x47), byte(0x30), byte(0x44), byte(0x02), byte(0x20), byte(0x25), byte(0xdd), byte(0xa0), byte(0xab), byte(0x18), byte(0x22), byte(0xb2), byte(0x87), byte(0x84), byte(0x96), byte(0x11), byte(0x6b), byte(0x36), byte(0xdb), byte(0x23), byte(0x9a), byte(0xeb), byte(0x98), byte(0x27), byte(0x60), byte(0xa8), byte(0x60), byte(0x39), byte(0xfd), byte(0xd5), byte(0xc3), byte(0x71), byte(0x34), byte(0x13), byte(0x78), byte(0x76), byte(0x38), byte(0x02), byte(0x20), byte(0x64), byte(0x60), byte(0xf3), byte(0x5b), byte(0x32), byte(0xa2), byte(0x92), byte(0xd2), byte(0x04), byte(0x73), byte(0xa8), byte(0x67), byte(0x73), byte(0x50), byte(0x68), byte(0xc1), byte(0xcf), byte(0xf3), byte(0xf0), byte(0x06), byte(0xeb), byte(0x27), byte(0xa1), byte(0x59), byte(0x22), byte(0xd3), byte(0xb7), byte(0x23), byte(0xce), byte(0x92), byte(0xfb), byte(0x54), byte(0x01), byte(0x21), byte(0x03), byte(0x95), byte(0xe0), byte(0x57), byte(0x1b), byte(0x44), byte(0x1e), byte(0x0f), byte(0x2f), byte(0xd9), byte(0x32), byte(0x90), byte(0x6a), byte(0x3f), byte(0xd6), byte(0x8a), byte(0x57), byte(0x09), byte(0x8a), byte(0x55), byte(0x52), byte(0xdd), byte(0x62), byte(0xe2), byte(0x23), byte(0x87), byte(0x13), byte(0x9b), byte(0x1f), byte(0x60), byte(0x78), byte(0x22), byte(0x3d), byte(0xff), byte(0xff), byte(0xff), byte(0xff), byte(0x02), byte(0x00), byte(0x46), byte(0xc3), byte(0x23), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x19), byte(0x76), byte(0xa9), byte(0x14), byte(0xcd), byte(0x55), byte(0x7a), byte(0x2e), byte(0x83), byte(0xfb), byte(0x75), byte(0x18), byte(0x50), byte(0x73), byte(0xa3), byte(0x01), byte(0xda), byte(0x77), byte(0x28), byte(0x85), byte(0x18), byte(0x3b), byte(0x58), byte(0x0c), byte(0x88), byte(0xac), byte(0x11), byte(0x39), byte(0xc0), byte(0x05), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x19), byte(0x76), byte(0xa9), byte(0x14), byte(0xcd), byte(0x55), byte(0x7a), byte(0x2e), byte(0x83), byte(0xfb), byte(0x75), byte(0x18), byte(0x50), byte(0x73), byte(0xa3), byte(0x01), byte(0xda), byte(0x77), byte(0x28), byte(0x85), byte(0x18), byte(0x3b), byte(0x58), byte(0x0c), byte(0x88), byte(0xac), byte(0x00), byte(0x00), byte(0x00), byte(0x00)];
            
            let utxo2:[UInt8] = [byte(0x01), byte(0x00), byte(0x00), byte(0x00), byte(0x01), byte(0xde), byte(0xe0), byte(0x79), byte(0x35), byte(0x92), byte(0x48), byte(0x29), byte(0x9e), byte(0x3f), byte(0x24), byte(0xe7), byte(0x87), byte(0x7c), byte(0x6b), byte(0x1c), byte(0x2f), byte(0x36), byte(0x1b), byte(0x54), byte(0x74), byte(0x1f), byte(0x00), byte(0xb8), byte(0x05), byte(0x6f), byte(0xc5), byte(0x00), byte(0x1c), byte(0xdc), byte(0x75), byte(0x07), byte(0x94), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x6a), byte(0x47), byte(0x30), byte(0x44), byte(0x02), byte(0x20), byte(0x0d), byte(0xbb), byte(0xca), byte(0x48), byte(0x74), byte(0xb8), byte(0x36), byte(0x23), byte(0xea), byte(0x6c), byte(0x31), byte(0x97), byte(0x0d), byte(0xf4), byte(0x9e), byte(0xfb), byte(0xc3), byte(0x71), byte(0xc1), byte(0x20), byte(0xa9), byte(0x33), byte(0xea), byte(0x7f), byte(0x5a), byte(0xd7), byte(0x07), byte(0xf7), byte(0xa0), byte(0xbc), byte(0x57), byte(0xab), byte(0x02), byte(0x20), byte(0x7c), byte(0xd3), byte(0x14), byte(0x05), byte(0xcb), byte(0xcb), byte(0x55), byte(0x20), byte(0xe6), byte(0x35), byte(0x07), byte(0x9f), byte(0x1b), byte(0x8a), byte(0x8b), byte(0xde), byte(0xc9), byte(0xe7), byte(0xea), byte(0x6c), byte(0x5a), byte(0xa5), byte(0x99), byte(0x7e), byte(0xa1), byte(0xee), byte(0x65), byte(0x9e), byte(0xe4), byte(0xef), byte(0xdd), byte(0x77), byte(0x01), byte(0x21), byte(0x03), byte(0x95), byte(0xe0), byte(0x57), byte(0x1b), byte(0x44), byte(0x1e), byte(0x0f), byte(0x2f), byte(0xd9), byte(0x32), byte(0x90), byte(0x6a), byte(0x3f), byte(0xd6), byte(0x8a), byte(0x57), byte(0x09), byte(0x8a), byte(0x55), byte(0x52), byte(0xdd), byte(0x62), byte(0xe2), byte(0x23), byte(0x87), byte(0x13), byte(0x9b), byte(0x1f), byte(0x60), byte(0x78), byte(0x22), byte(0x3d), byte(0xff), byte(0xff), byte(0xff), byte(0xff), byte(0x02), byte(0x00), byte(0x46), byte(0xc3), byte(0x23), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x19), byte(0x76), byte(0xa9), byte(0x14), byte(0xcd), byte(0x55), byte(0x7a), byte(0x2e), byte(0x83), byte(0xfb), byte(0x75), byte(0x18), byte(0x50), byte(0x73), byte(0xa3), byte(0x01), byte(0xda), byte(0x77), byte(0x28), byte(0x85), byte(0x18), byte(0x3b), byte(0x58), byte(0x0c), byte(0x88), byte(0xac), byte(0x60), byte(0xb9), byte(0xeb), byte(0x0b), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x19), byte(0x76), byte(0xa9), byte(0x14), byte(0xcd), byte(0x55), byte(0x7a), byte(0x2e), byte(0x83), byte(0xfb), byte(0x75), byte(0x18), byte(0x50), byte(0x73), byte(0xa3), byte(0x01), byte(0xda), byte(0x77), byte(0x28), byte(0x85), byte(0x18), byte(0x3b), byte(0x58), byte(0x0c), byte(0x88), byte(0xac), byte(0x00), byte(0x00), byte(0x00), byte(0x00)]
            
            var ppUTXOs = [utxo1.withUnsafeBufferPointer({return $0.baseAddress}), utxo2.withUnsafeBufferPointer({return $0.baseAddress})]
            let UTXOLen:[size_t] = [utxo1.count, utxo2.count]
            
            var sigData1 = Data.init(repeating: UInt8(0), count: Int(PAEW_BTC_SIG_MAX_LEN))
            var sigData2 = Data.init(repeating: UInt8(0), count: Int(PAEW_BTC_SIG_MAX_LEN))
            let ppTXSig = [sigData1.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            }),  sigData2.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })]
            var pnTXSig: [size_t] = [sigData1.count, sigData2.count]
            
            let transaction: [UInt8] = [byte(0x01), byte(0x00), byte(0x00), byte(0x00), byte(0x02), byte(0xbf), byte(0x69), byte(0x08), byte(0x9d), byte(0x98), byte(0xb9), byte(0x3c), byte(0xd3), byte(0xe5), byte(0x4f), byte(0xb2), byte(0xcc), byte(0x45), byte(0x75), byte(0xde), byte(0x55), byte(0x0f), byte(0xa4), byte(0x6b), byte(0x49), byte(0x01), byte(0xc8), byte(0xd3), byte(0xf5), byte(0x9c), byte(0xa3), byte(0x18), byte(0xfc), byte(0x63), byte(0xe0), byte(0x02), byte(0x77), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0xff), byte(0xff), byte(0xff), byte(0xff), byte(0xcd), byte(0x6e), byte(0x85), byte(0xa4), byte(0xe5), byte(0x33), byte(0xf5), byte(0x6f), byte(0x65), byte(0x8b), byte(0x80), byte(0xb1), byte(0x9d), byte(0xee), byte(0x11), byte(0x4f), byte(0x0b), byte(0xc4), byte(0xb0), byte(0xc7), byte(0x80), byte(0xeb), byte(0x68), byte(0x3b), byte(0x59), byte(0x22), byte(0x1c), byte(0x6f), byte(0xe1), byte(0x81), byte(0xd3), byte(0x57), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0xff), byte(0xff), byte(0xff), byte(0xff), byte(0x02), byte(0xbb), byte(0xb3), byte(0xeb), byte(0x0b), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x19), byte(0x76), byte(0xa9), byte(0x14), byte(0xcd), byte(0x55), byte(0x7a), byte(0x2e), byte(0x83), byte(0xfb), byte(0x75), byte(0x18), byte(0x50), byte(0x73), byte(0xa3), byte(0x01), byte(0xda), byte(0x77), byte(0x28), byte(0x85), byte(0x18), byte(0x3b), byte(0x58), byte(0x0c), byte(0x88), byte(0xac), byte(0x00), byte(0xca), byte(0x9a), byte(0x3b), byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x19), byte(0x76), byte(0xa9), byte(0x14), byte(0xBD), byte(0x2C), byte(0xBC), byte(0xF0), byte(0xDD), byte(0x69), byte(0x3F), byte(0x73), byte(0x56), byte(0x8F), byte(0x7D), byte(0x44), byte(0xC8), byte(0xAC), byte(0x26), byte(0xC5), byte(0xDA), byte(0xD5), byte(0x21), byte(0x00), byte(0x88), byte(0xac), byte(0x00), byte(0x00), byte(0x00), byte(0x00)]
            
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("btc signature failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            //var t1: UnsafePointer<UInt8> = UTXOLen.withUnsafeBufferPointer({return $0.baseAddress!})
            iRtn = PAEW_BTC_SetTX(pPAEWContext, devIdx, nUTXOCount, ppUTXOs.withUnsafeBufferPointer({return $0.baseAddress}), UTXOLen.withUnsafeBufferPointer({return $0.baseAddress!}), transaction, transaction.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("btc signature failed due to PAEW_BTC_SetTX returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var lastResult: UInt32 = UInt32(PAEW_RET_SUCCESS)
            var lastAuthType = authType
            
            var needAbort = false
            
            self.printLog("default auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
            while true {
                //check abort sign flag
                if self.abortSignFlag {
                    self.abortSignFlag = false
                    iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                    if iRtn == PAEW_RET_SUCCESS {
                        self.printLog("btc signature abort")
                        needAbort = false
                        break
                    } else {
                        self.printLog("PAEW_AbortSign returns failed: \(Utils.errorCodeToString(iRtn))")
                        needAbort = true
                        break
                    }
                }
                //check switch sign flag
                if self.switchSignFlag {
                    self.switchSignFlag = false
                    if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_PIN)
                    } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                    }
                    //clear last getsign result
                    lastResult = UInt32(PAEW_RET_SUCCESS)
                    pinVerified = false
                }
                
                if lastAuthType != authType {
                    if authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN  {
                        let type = PickerViewAlert.doModal(parent: self, title: "Please select verify method", dataSource: ["Fingerprint", "PIN"])
                        guard type >= 0 else {
                            self.printLog("user canceled")
                            needAbort = true
                            break
                        }
                        authType = UInt8(type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN)
                    }
                    lastAuthType = authType
                    self.printLog("auth type changed, current auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
                    iRtn = PAEW_SwitchSign(pPAEWContext, devIdx)
                }
                //if auth type is PIN, PAEW_VerifySignPIN must be called
                if authType == PAEW_SIGN_AUTH_TYPE_PIN && (!pinVerified) {
                    let aPin = TextFieldViewAlert.doModal(parent: self, title: "Please input PIN", message: "Please input your PIN to continue", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
                    guard let pin = aPin else {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                        pinVerified = false
                        self.printLog("user canceled PIN input")
                        continue
                    }
                    iRtn = PAEW_VerifySignPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
                    guard iRtn == PAEW_RET_SUCCESS else {
                        pinVerified = false
                        self.printLog("PAEW_VerifySignPIN returns failed: \(Utils.errorCodeToString(iRtn))")
                        continue
                    }
                    pinVerified = true
                }
                
                //after all, loop to get sign result
                //first pass sig index to 0 to get first signature, if GetSignResult returns success, then loop to get other signatures
                iRtn = PAEW_BTC_GetSignResult(pPAEWContext, devIdx, authType, 0, ppTXSig[0], &(pnTXSig[0]))
                
                if iRtn == PAEW_RET_SUCCESS {
                    self.printLog("erc20 signature succeeded with signature0: \(Utils.bytesToHexString(data: ppTXSig[0], length: pnTXSig[0]))")
                    for i in 1..<nUTXOCount {
                        iRtn = PAEW_BTC_GetSignResult(pPAEWContext, devIdx, authType, i, ppTXSig[i], &(pnTXSig[i]))
                        self.printLog("erc20 signature succeeded with signature\(i): \(Utils.bytesToHexString(data: ppTXSig[i], length: pnTXSig[i]))")
                    }
                    needAbort = false
                    break
                } else if lastResult != UInt32(bitPattern: iRtn) {
                    self.printLog("\(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN") signature status : \(Utils.errorCodeToString(iRtn))")
                    lastResult = UInt32(bitPattern: iRtn)
                    //notify here: loop for pin and loop for fp have different loop conditions
                    if authType == PAEW_SIGN_AUTH_TYPE_FP {
                        if lastResult == PAEW_RET_NO_VERIFY_COUNT {
                            //like wechat, if fp verify count ran out, switch to pin verify
                            self.switchSignFlag = true
                            continue
                        }
                        if lastResult != PAEW_RET_DEV_WAITING
                            && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                            && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                            && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER {
                            self.printLog("erc20 signature failed")
                            needAbort = true
                            break
                        }
                    } else if authType == PAEW_SIGN_AUTH_TYPE_PIN {
                        if lastResult != PAEW_RET_DEV_WAITING {
                            self.printLog("erc20 signature failed")
                            needAbort = true
                            break
                        }
                    }
                }
            }
            //finally, call abort if PAEW_ETH_GetSignResult returns non PAEW_RET_SUCCESS values
            if needAbort {
                iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
            }
        }
    }
    
    @IBAction func erc20SignBtnAction(sender: UIButton) {
        self.switchSignFlag = false
        self.abortSignFlag = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_ETH)
            let derivePath = self.puiDerivePathETH
            self.printLog("ready for erc20 signature")
            var authType: UInt8 = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
            var pinVerified = false
            
            let transaction: [UInt8] = [byte(0xf8), byte(0x69), byte(0x80), byte(0x84), byte(0xb2),
                                        byte(0xd0), byte(0x5e), byte(0x00), byte(0x83), byte(0x01),
                                        byte(0xd4), byte(0xc0), byte(0x94), byte(0x85), byte(0x9a),
                                        byte(0x9c), byte(0x0b), byte(0x44), byte(0xcb), byte(0x70),
                                        byte(0x66), byte(0xd9), byte(0x56), byte(0xa9), byte(0x58),
                                        byte(0xb0), byte(0xb8), byte(0x2e), byte(0x54), byte(0xc9),
                                        byte(0xe4), byte(0x4b), byte(0x4b), byte(0x80), byte(0xb8),
                                        byte(0x44), byte(0xa9), byte(0x05), byte(0x9c), byte(0xbb),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0xf0), byte(0x32), byte(0x32),
                                        byte(0xeb), byte(0xb2), byte(0x32), byte(0x78), byte(0x6a),
                                        byte(0xff), byte(0x2d), byte(0xab), byte(0x33), byte(0xa6),
                                        byte(0xba), byte(0xdc), byte(0x17), byte(0x3a), byte(0x16),
                                        byte(0x56), byte(0xab), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x00), byte(0x00), byte(0x00), byte(0x00),
                                        byte(0x00), byte(0x1d), byte(0x24), byte(0xb2), byte(0xdf),
                                        byte(0xac), byte(0x52), byte(0x00), byte(0x00), byte(0x01),
                                        byte(0x80), byte(0x80)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("erc20 signature failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            iRtn = PAEW_SetERC20Info(pPAEWContext, devIdx, coinType, "iETH", 18)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("erc20 signature failed due to PAEW_SetERC20Info returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            iRtn = PAEW_ETH_SetTX(pPAEWContext, devIdx, transaction, transaction.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("erc20 signature failed due to PAEW_ETH_SetTX returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var lastResult: UInt32 = UInt32(PAEW_RET_SUCCESS)
            var lastAuthType = authType
            
            var needAbort = false
            
            self.printLog("default auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
            while true {
                //check abort sign flag
                if self.abortSignFlag {
                    self.abortSignFlag = false
                    iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                    if iRtn == PAEW_RET_SUCCESS {
                        self.printLog("erc20 signature abort")
                        needAbort = false
                        break
                    } else {
                        self.printLog("PAEW_AbortSign returns failed: \(Utils.errorCodeToString(iRtn))")
                        needAbort = true
                        break
                    }
                }
                //check switch sign flag
                if self.switchSignFlag {
                    self.switchSignFlag = false
                    if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_PIN)
                    } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                    }
                    //clear last getsign result
                    lastResult = UInt32(PAEW_RET_SUCCESS)
                    pinVerified = false
                }
                
                if lastAuthType != authType {
                    if authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN  {
                        let type = PickerViewAlert.doModal(parent: self, title: "Please select verify method", dataSource: ["Fingerprint", "PIN"])
                        guard type >= 0 else {
                            self.printLog("user canceled")
                            needAbort = true
                            break
                        }
                        authType = UInt8(type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN)
                    }
                    lastAuthType = authType
                    self.printLog("auth type changed, current auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
                    iRtn = PAEW_SwitchSign(pPAEWContext, devIdx)
                }
                //if auth type is PIN, PAEW_VerifySignPIN must be called
                if authType == PAEW_SIGN_AUTH_TYPE_PIN && (!pinVerified) {
                    let aPin = TextFieldViewAlert.doModal(parent: self, title: "Please input PIN", message: "Please input your PIN to continue", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
                    guard let pin = aPin else {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                        pinVerified = false
                        self.printLog("user canceled PIN input")
                        continue
                    }
                    iRtn = PAEW_VerifySignPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
                    guard iRtn == PAEW_RET_SUCCESS else {
                        pinVerified = false
                        self.printLog("PAEW_VerifySignPIN returns failed: \(Utils.errorCodeToString(iRtn))")
                        continue
                    }
                    pinVerified = true
                }
                
                //after all, loop to get sign result
                iRtn = PAEW_ETH_GetSignResult(pPAEWContext, devIdx, authType, sigPtr, &sigLen)
                
                if iRtn == PAEW_RET_SUCCESS {
                    self.printLog("erc20 signature succeeded with signature: \(Utils.bytesToHexString(data: sigPtr, length: sigLen))")
                    needAbort = false
                    break
                } else if lastResult != UInt32(bitPattern: iRtn) {
                    self.printLog("\(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN") signature status : \(Utils.errorCodeToString(iRtn))")
                    lastResult = UInt32(bitPattern: iRtn)
                    //notify here: loop for pin and loop for fp have different loop conditions
                    if authType == PAEW_SIGN_AUTH_TYPE_FP {
                        if lastResult == PAEW_RET_NO_VERIFY_COUNT {
                            //like wechat, if fp verify count ran out, switch to pin verify
                            self.switchSignFlag = true
                            continue
                        }
                        if lastResult != PAEW_RET_DEV_WAITING
                            && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                            && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                            && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER {
                            self.printLog("erc20 signature failed")
                            needAbort = true
                            break
                        }
                    } else if authType == PAEW_SIGN_AUTH_TYPE_PIN {
                        if lastResult != PAEW_RET_DEV_WAITING {
                            self.printLog("erc20 signature failed")
                            needAbort = true
                            break
                        }
                    }
                }
            }
            //finally, call abort if PAEW_ETH_GetSignResult returns non PAEW_RET_SUCCESS values
            if needAbort {
                iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
            }
        }
    }
    
    @IBAction func etcSignBtnAction(sender: UIButton) {
        self.switchSignFlag = false
        self.abortSignFlag = false
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let coinType = byte(PAEW_COIN_TYPE_ETC)
            let derivePath = self.puiDerivePathETC
            self.printLog("ready for etc signature")
            var authType: UInt8 = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
            var pinVerified = false
            
            let transaction: [UInt8] = [byte(0xEC), byte(0x0C), byte(0x85), byte(0x04), byte(0xA8),
                                        byte(0x17), byte(0xC8), byte(0x00), byte(0x83), byte(0x01),
                                        byte(0xD4), byte(0xC0), byte(0x94), byte(0xF2), byte(0xE6),
                                        byte(0xC2), byte(0xC9), byte(0xBD), byte(0xB2), byte(0xC2),
                                        byte(0x18), byte(0x3B), byte(0x04), byte(0x4E), byte(0x54),
                                        byte(0xE1), byte(0x76), byte(0xC7), byte(0xD5), byte(0xDB),
                                        byte(0x7C), byte(0x70), byte(0xFE), byte(0x87), byte(0x03),
                                        byte(0x8D), byte(0x7E), byte(0xA4), byte(0xC6), byte(0x80),
                                        byte(0x00), byte(0x80), byte(0x3D), byte(0x80), byte(0x80)]
            
            var sigLen:size_t = 1024
            var sigData = Data.init(count: sigLen)
            let sigPtr = sigData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            
            var iRtn = PAEW_DeriveTradeAddress(pPAEWContext, devIdx, coinType, derivePath.withUnsafeBufferPointer({return $0.baseAddress!}), derivePath.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("etc signature failed due to PAEW_DeriveTradeAddress returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            iRtn = PAEW_ETC_SetTX(pPAEWContext, devIdx, transaction, transaction.count)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("etc signature failed due to PAEW_ETC_SetTX returns : \(Utils.errorCodeToString(iRtn))")
                return
            }
            
            var lastResult: UInt32 = UInt32(PAEW_RET_SUCCESS)
            var lastAuthType = authType
            
            var needAbort = false
            
            self.printLog("default auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
            while true {
                //check abort sign flag
                if self.abortSignFlag {
                    self.abortSignFlag = false
                    iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
                    if iRtn == PAEW_RET_SUCCESS {
                        self.printLog("etc signature abort")
                        needAbort = false
                        break
                    } else {
                        self.printLog("PAEW_AbortSign returns failed: \(Utils.errorCodeToString(iRtn))")
                        needAbort = true
                        break
                    }
                }
                //check switch sign flag
                if self.switchSignFlag {
                    self.switchSignFlag = false
                    if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_PIN)
                    } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                    }
                    //clear last getsign result
                    lastResult = UInt32(PAEW_RET_SUCCESS)
                    pinVerified = false
                }
                
                if lastAuthType != authType {
                    if authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN  {
                        let type = PickerViewAlert.doModal(parent: self, title: "Please select verify method", dataSource: ["Fingerprint", "PIN"])
                        guard type >= 0 else {
                            self.printLog("user canceled")
                            needAbort = true
                            break
                        }
                        authType = UInt8(type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN)
                    }
                    lastAuthType = authType
                    self.printLog("auth type changed, current auth type: \(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN")")
                    iRtn = PAEW_SwitchSign(pPAEWContext, devIdx)
                }
                //if auth type is PIN, PAEW_VerifySignPIN must be called
                if authType == PAEW_SIGN_AUTH_TYPE_PIN && (!pinVerified) {
                    let aPin = TextFieldViewAlert.doModal(parent: self, title: "Please input PIN", message: "Please input your PIN to continue", isPassword: true, minLengtRequired: 6, maxLengtRequired: 16, keyBoardType: .numberPad)
                    guard let pin = aPin else {
                        authType = UInt8(PAEW_SIGN_AUTH_TYPE_FP)
                        pinVerified = false
                        self.printLog("user canceled PIN input")
                        continue
                    }
                    iRtn = PAEW_VerifySignPIN(pPAEWContext, devIdx, pin.cString(using: String.Encoding.utf8))
                    guard iRtn == PAEW_RET_SUCCESS else {
                        pinVerified = false
                        self.printLog("PAEW_VerifySignPIN returns failed: \(Utils.errorCodeToString(iRtn))")
                        continue
                    }
                    pinVerified = true
                }
                
                //after all, loop to get sign result
                iRtn = PAEW_ETC_GetSignResult(pPAEWContext, devIdx, authType, sigPtr, &sigLen)
                
                if iRtn == PAEW_RET_SUCCESS {
                    self.printLog("ETC signature succeeded with signature: \(Utils.bytesToHexString(data: sigPtr, length: sigLen))")
                    needAbort = false
                    break
                } else if lastResult != UInt32(bitPattern: iRtn) {
                    self.printLog("\(authType == PAEW_SIGN_AUTH_TYPE_FP ? "Fingerprint" : "PIN") signature status : \(Utils.errorCodeToString(iRtn))")
                    lastResult = UInt32(bitPattern: iRtn)
                    //notify here: loop for pin and loop for fp have different loop conditions
                    if authType == PAEW_SIGN_AUTH_TYPE_FP {
                        if lastResult == PAEW_RET_NO_VERIFY_COUNT {
                            //like wechat, if fp verify count ran out, switch to pin verify
                            self.switchSignFlag = true
                            continue
                        }
                        if lastResult != PAEW_RET_DEV_WAITING
                            && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                            && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                            && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER {
                            self.printLog("ETC signature failed")
                            needAbort = true
                            break
                        }
                    } else if authType == PAEW_SIGN_AUTH_TYPE_PIN {
                        if lastResult != PAEW_RET_DEV_WAITING {
                            self.printLog("ETC signature failed")
                            needAbort = true
                            break
                        }
                    }
                }
            }
            //finally, call abort if PAEW_ETH_GetSignResult returns non PAEW_RET_SUCCESS values
            if needAbort {
                iRtn = PAEW_AbortSign(pPAEWContext, devIdx)
            }
        }
    }
    
    @IBAction func switchSignBtnAction(sender: UIButton) {
        self.switchSignFlag = true
    }
    
    @IBAction func abortSignNewBtnAction(sender: UIButton) {
        self.abortSignFlag = true
    }
    
    /*
     // MARK: - Image actions
     */
    
    @IBAction func getImageListBtnAction(sender: UIButton) {
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            var iRtn = PAEW_RET_UNKNOWN_FAIL;
            var  nImageCount:size_t = 0;
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_GetImageList")
            iRtn = UInt32(PAEW_GetImageList(pPAEWContext, devIdx, nil, &nImageCount));
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetImageList returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.imageCount = nImageCount;
            self.printLog("PAEW_GetImageList returns returns success, device image count is: \(nImageCount)")
        }
    }
    
    @IBAction func setImageNameBtnAction(sender: UIButton) {
        if (self.imageCount <= 0) {
            self.printLog("invalid image count, please call GetImageList first!")
            return
        }
        var arr = Array<String>.init()
        for i in 0..<imageCount {
            arr.append("\(i)")
        }
        
        let index = PickerViewAlert.doModal(parent: self, title: "please select image index:", dataSource: arr)
        if index < 0 {
            return
        }
        
        let imagename = TextFieldViewAlert.doModal(parent: self, title: "Please input image name", message: "Please input image name", isPassword: false, minLengtRequired: 1, maxLengtRequired: Int(PAEW_IMAGE_NAME_MAX_LEN), keyBoardType: .default)
        guard let result = imagename else {
            self.printLog("invalid image name length, valid name length is between 0 and \(PAEW_IMAGE_NAME_MAX_LEN)")
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            let resultTrimmed = result.trimmingCharacters(in: .whitespaces)
            let len: size_t = result.count
            self.printLog("ready to call PAEW_SetImageName")
            var tmp = resultTrimmed.cString(using: String.Encoding.utf8)!
            let ptr = tmp.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> UnsafeMutablePointer<byte> in
                return ptr.bindMemory(to: byte.self).baseAddress!
            })
            let iRtn = PAEW_SetImageName(pPAEWContext, devIdx, UInt8(index), ptr, len)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_SetImageName returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_SetImageName returns success, set image name to '\(resultTrimmed)' at index \(index)")
        }
    }
    
    @IBAction func getImageNameBtnAction(sender: UIButton) {
        guard self.imageCount > 0 else {
            self.printLog("invalid image count, please call GetImageList first!")
            return
        }
        var arr = Array<String>.init()
        for i in 0..<imageCount {
            arr.append("\(i)")
        }
        
        let index = PickerViewAlert.doModal(parent: self, title: "please select image index:", dataSource: arr)
        guard index >= 0 else {
            return
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            var data = Data.init(count: Int(PAEW_IMAGE_NAME_MAX_LEN))
            let dataAsUInt8 = data.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<UInt8> in
                return ptr
            })
            var len = Int(PAEW_IMAGE_NAME_MAX_LEN)
            self.printLog("ready to call PAEW_SetImageName")
            let iRtn = PAEW_GetImageName(pPAEWContext, devIdx, UInt8(index), dataAsUInt8, &len)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_GetImageName returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            let dataAsInt8 = data.withUnsafeBytes({ (ptr: UnsafePointer<CChar>) -> UnsafePointer<CChar> in
                return ptr
            })
            let imgName = String.init(cString: dataAsInt8)
            self.printLog("PAEW_GetImageName returns success, image name at index \(index) is '\(imgName)' ", index, imgName)
        }
    }
    
    @IBAction func setImageDataBtnAction(sender: UIButton) {
        guard self.imageCount > 0 else {
            self.printLog("invalid image count, please call GetImageList first!")
            return
        }
        
        
        

        DispatchQueue.global(qos: .default).async {
            var arr = Array<String>.init()
            for i in 0..<self.imageCount {
                arr.append("\(i)")
            }
            
            let index = PickerViewAlert.doModal(parent: self, title: "please select the destination image index:", dataSource: arr)
            guard index >= 0 else {
                self.printLog("invalid image index")
                return
            }
            
            guard let path = Bundle.main.resourcePath else {
                self.printLog("logo image not found")
                return
            }
            let logoPath = path.appending("/logo")
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: path) else {
                self.printLog("logo image not found")
                return
            }
            guard let names = try? fileManager.contentsOfDirectory(atPath: logoPath) else {
                self.printLog("logo image not found")
                return
            }
            guard names.count > 0 else {
                self.printLog("logo image not found")
                return
            }
            
            let imgIndex = PickerViewAlert.doModal(parent: self, title: "please select image to set:", dataSource:names)
            guard imgIndex >= 0 else {
                self.printLog("invalid image name")
                return
            }
            
            
            guard let image = fileManager.contents(atPath: logoPath.appending("/\(names[imgIndex])")) else {
                self.printLog("invalid image data")
                return
            }
            var destImgLen: size_t = 10240;
            var destImg = Data.init(count: destImgLen)
            let imgDataPtr = destImg.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<byte>) -> UnsafeMutablePointer<byte> in
                return ptr
            })
            let imageDataOffSet:UInt32 = UInt32(image[10] | image[11] << 8 | image[12] << 16 | image[13] << 24);
            self.printLog("ready to call PAEW_ConvertBMP")
            let imgPtr = image.withUnsafeBytes({ (ptr: UnsafePointer<byte>) -> UnsafePointer<byte> in
                return ptr
            })
            var iRtn = PAEW_ConvertBMP(imgPtr.advanced(by: Int(imageDataOffSet)), image.count - Int(imageDataOffSet), 128, 80, imgDataPtr, &destImgLen);
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ShowImage returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_ConvertBMP returns success")
            
            let devIdx = 0
            let pPAEWContext = self.deviceContext
            iRtn = PAEW_SetImageData(pPAEWContext, devIdx, UInt8(index), imgDataPtr, destImgLen)
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_SetImageData returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_SetImageData on index \(index) returns success")
        }
    }
    
    @IBAction func showImageBtnAction(sender: UIButton) {
        guard self.imageCount > 0 else {
            self.printLog("invalid image count, please call GetImageList first!")
            return;
        }
        var arr = Array<String>.init()
        for i in 0..<imageCount {
            arr.append("\(i)")
        }
        
        let index = PickerViewAlert.doModal(parent: self, title: "please select image index:", dataSource: arr)
        guard index >= 0 else {
            self.printLog("invalid image count, please call GetImageList first!")
            return;
        }
        
        
        
        let arrType = ["PAEW_LCD_CLEAR", "PAEW_LCD_SHOW_LOGO", "PAEW_LCD_CLEAR_SHOW_LOGO"]
        
        let type = PickerViewAlert.doModal(parent: self, title:"please select show type:", dataSource:arrType)
        guard type >= 0 else {
            self.printLog("invalid show type: \(type)")
            return;
        }
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_ShowImage")
            let iRtn = PAEW_ShowImage(pPAEWContext, devIdx, UInt8(index), UInt8(type))
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_ShowImage returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_ShowImage on index \(index) returns success")
        }
    }
    
    @IBAction func setLogoImageBtnAction(sender: UIButton) {
        guard self.imageCount > 0 else {
            self.printLog("invalid image count, please call GetImageList first!")
            return;
        }
        var arr = Array<String>.init()
        for i in 0..<imageCount {
            arr.append("\(i)")
        }
        
        let index = PickerViewAlert.doModal(parent: self, title: "please select image index:", dataSource: arr)
        guard index >= 0 else {
            self.printLog("invalid image count, please call GetImageList first!")
            return;
        }
        
        DispatchQueue.global(qos: .default).async {
            let devIdx = 0
            guard let pPAEWContext = self.deviceContext else {
                self.printLog("Deivce not connected, connect to device first")
                return
            }
            self.printLog("ready to call PAEW_SetLogoImage")
            let iRtn = PAEW_SetLogoImage(pPAEWContext, devIdx, UInt8(index));
            guard iRtn == PAEW_RET_SUCCESS else {
                self.printLog("PAEW_SetLogoImage returns failed: \(Utils.errorCodeToString(iRtn))")
                return
            }
            self.printLog("PAEW_SetLogoImage returns success, current logi index is \(index)")
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
