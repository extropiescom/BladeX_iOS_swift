//
//  ViewController.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/10/29.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit




var vcClass:ViewController? = nil

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    static var cbParam = callback_param.init()
    
    //callback for EnumContext
    var enumCallback:tFunc_EnumCallback = {
        let devName = String.init(cString: $0!)
        let selfClass = vcClass!
        ViewController.printLog("enumCallback::: ", devName, $1, $2)
        
        let model:ToolCellModel = ToolCellModel.init(peripheralName: devName, RSSI: Int($1), state: Int($2))

        selfClass.DevdataArray.append(model)
        selfClass.devTabView.reloadData()
        return PAEW_RET_SUCCESS;
    }
    
    //battery callback for connected device
    var batteryCallback:tFunc_BatteryCallback = {
        let str = String.init(format: "power source: %@, battery level: 0x%02X", $0 == 0 ? "USB" : "Battery", $1)
        ViewController.printLog("batteryCallback::: \(str)")
        return PAEW_RET_SUCCESS
    }
    
    //disconnect callback for connected device
    var disconnectCallback:tFunc_DisconnectedCallback = {
        let str = String.init(format: "disconnect error code: %d, description: %s", $0, $1!)
        ViewController.printLog("disconnectCallback::: ", str)
        return PAEW_RET_SUCCESS
    }
    
    var procCallback: tFunc_Proc_Callback = {
        let param: callback_param = $0!.pointee
        printLog("tFunc_Proc_Callback")
        printLog("dev_count: \(param.dev_count)")
        printLog("dev_index: \(param.dev_index)")
        printLog("pstatus: \(Utils.ewallet_status2string(param.pstatus))")
        printLog("pstep: \(Utils.ewallet_step2string(param.pstep))")
        printLog("ret_value: \(param.ret_value)")
        return PAEW_RET_SUCCESS
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.DevdataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ToolCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ToolCell.self), for: indexPath) as! ToolCell
        cell.setPeripheral(model: self.DevdataArray[indexPath.row])
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.DevdataArray[indexPath.row]
        self.connectAction(devName: model.peripheralName)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ToolCell.height
    }
    
    var StartScanBtn:UIButton
    var devNameField:UITextField
    var timeoutField:UITextField
    var devTabView:UITableView
    
    //variable to store names of discovered bladeX devices
    var DevdataArray = Array<ToolCellModel>.init()
    
    //variable to store device context handle of connected bladeX device
    var pPAEWContext:UnsafeMutableRawPointer? = UnsafeMutableRawPointer(UnsafeMutablePointer<Int>.init(mutating: nil))
    
    init() {
        
        StartScanBtn = UIButton(type: UIButtonType.custom)
        devNameField = UITextField.init()
        timeoutField = UITextField.init()
        devTabView = UITableView(frame: CGRect.init(), style: .plain)
        
        super.init(nibName: nil, bundle: nil)
        vcClass = self
        
        StartScanBtn.setTitle("StartScan", for: .normal)
        StartScanBtn.setTitleColor(UIColor.blue, for: .normal)
        StartScanBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        StartScanBtn.backgroundColor = UIColor.lightGray
        StartScanBtn.addTarget(self, action: #selector(ViewController.StartScanBtnAction(_:)), for: .touchUpInside)
        
        devNameField.placeholder = "Please input device name"
        devNameField.clearButtonMode = .always
        devNameField.returnKeyType = .done
        devNameField.text = "WOOKONG BIO"
        devNameField.layer.borderColor = UIColor.green.cgColor
        devNameField.layer.borderWidth = 1;
        devNameField.layer.cornerRadius = 5;
        
        timeoutField.placeholder = "Please input BLE scan timeout"
        timeoutField.keyboardType = .numberPad
        timeoutField.clearButtonMode = .always
        timeoutField.returnKeyType = .done
        timeoutField.text = "15"
        timeoutField.layer.borderColor = UIColor.green.cgColor
        timeoutField.layer.borderWidth = 1;
        timeoutField.layer.cornerRadius = 5;
        
        devTabView.frame = self.view.bounds
        devTabView.delegate = self
        devTabView.dataSource = self
        devTabView.backgroundColor = UIColor.groupTableViewBackground
        let nibName = "ToolCell"
        devTabView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: NSStringFromClass(ToolCell.self))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.edgesForExtendedLayout = UIRectEdge(rawValue: 0);
        self.extendedLayoutIncludesOpaqueBars = false;
        self.modalPresentationCapturesStatusBarAppearance = false;
        addSubViewAfterViewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addSubViewAfterViewDidLoad() {
        self.view.addSubview(StartScanBtn)
        self.StartScanBtn.mas_makeConstraints( { (make:MASConstraintMaker!) in
            make.bottom.mas_equalTo()(self.view.mas_bottom)?.offset()(-30)
            make.width.mas_equalTo()(120)
            make.height.mas_equalTo()(50)
            make.centerX.mas_equalTo()(self.view.mas_centerX)
        })
        
        self.view.addSubview(devNameField)
        self.devNameField.mas_makeConstraints( { (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.view.mas_top)?.offset()(20)
            make.left.mas_equalTo()(self.view.mas_left)?.offset()(0)
            make.right.mas_equalTo()(self.view.mas_right)?.offset()(0)
            make.height.mas_equalTo()(40)
        })
        
        self.view.addSubview(timeoutField)
        self.timeoutField.mas_makeConstraints( { (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.devNameField.mas_bottom)?.offset()(20)
            make.left.mas_equalTo()(self.view.mas_left)?.offset()(0)
            make.right.mas_equalTo()(self.view.mas_right)?.offset()(0)
            make.height.mas_equalTo()(40)
        })
        
        self.view.addSubview(devTabView)
        self.devTabView.mas_makeConstraints( { (make:MASConstraintMaker!) in
            make.top.mas_equalTo()(self.timeoutField.mas_bottom)?.offset()(20)
            make.width.mas_equalTo()(self.view.mas_width)
            make.right.mas_equalTo()(self.view.mas_right)
            make.bottom.mas_equalTo()(self.StartScanBtn.mas_top)?.offset()(-10)
        })
    }
    
    @IBAction func StartScanBtnAction(_ sender: Any) {
        self.DevdataArray.removeAll()
        //let pattern = self.devNameField.text!
        guard let pattern = self.devNameField.text else {
            return
        }
        guard let timeoutStr = self.timeoutField.text else {
            return
        }
        let timeout = (timeoutStr as NSString).intValue
        
        //all APIs MUST be called outside the main thread
        DispatchQueue.global(qos: .default).async { [unowned self] in
            var enumContext = EnumContext.init();
            
            //prepare for search pattern of device name
            //bladeX library will only return the device that contains the search pattern in device name
            let namePtr = UnsafeMutablePointer<CChar>.init(mutating: withUnsafeBytes(of: &(enumContext.searchName), {return $0}).bindMemory(to: CChar.self).baseAddress)
            strcpy(namePtr, pattern.cString(using: String.Encoding.utf8))
            
            //set callback to enumContext
            enumContext.enumCallBack = self.enumCallback;
            
            //set bluetooth scan timeout
            enumContext.timeout = timeout;
            
            //prepare parameters for calling PAEW_GetDeviceListWithDevContext
            
            //devType MUST set to PAEW_DEV_TYPE_BT
            let devType:CUnsignedChar = CUnsignedChar(PAEW_DEV_TYPE_BT)
            
            //devNamesData is used to store the bluetooth scan result, this is a OUT parameter
            //or you may use a single line of code instead the three lines below,
            //let devNames = UnsafeMutablePointer<CChar>.allocate(capacity: 512*16);
            //but you MUST remenber to free devNames after
            var devNamesData = Data.init(count: 512*64)
            let devNames = devNamesData.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<CChar>) -> UnsafeMutablePointer< CChar> in
                return ptr
            })
            
            //length of devNames allocated memory, this is a IN/OUT parameter
            var devNamesLen:size_t = 512*16;
            
            //device count of search result, this is a OUT parameter
            var nDevCount:size_t  = 0;
            
            //size of enumContext
            let ctxSize = MemoryLayout.size(ofValue: enumContext);
            
            let rtn = PAEW_GetDeviceListWithDevContext(devType, devNames, &devNamesLen, &nDevCount, &enumContext, ctxSize);
            
            //here shows how to process result of PAEW_GetDeviceListWithDevContext
            //for a better user experience, you may use enumCallback to notify user a new device was found
            guard rtn == PAEW_RET_SUCCESS else {
                ViewController.printLog("PAEW_GetDeviceListWithDevContext failed: %@", Utils.errorCodeToString(rtn))
                return
            }
            
            //result format in devNames:
            //devName1 + '\0' + devName2 + '\0' + ...
            ViewController.printLog("PAEW_GetDeviceListWithDevContext succeeded: %@", Utils.errorCodeToString(rtn))
            var devices: Array<String> = Array.init()
            if nDevCount > 0 {
                var index = 0
                for _ in 0..<nDevCount {
                    let dev:String = String.init(cString: devNames.advanced(by: index))
                    let len = strlen(devNames + index)
                    index += (len + 1)
                    devices.append(dev)
                }
                
                //now, every element in arr is a single devName,
                //so it can be used as input parameter for PAEW_InitContextWithDevNameAndDevContext
                ViewController.printLog("\(nDevCount) devices found")
                ViewController.printLog("devices: \(devices)")
            } else {
                ViewController.printLog("no devices were found")
            }
        }
    }
    
    func connectAction(devName:String) {
        DispatchQueue.global(qos: .default).async {[unowned self] in
            //connectContext initialization
            var connectContext = ConnectContext(timeout:5, batteryCallBack:self.batteryCallback, disconnectedCallback:self.disconnectCallback)
            
            //in this demo, we use the first device that we discovered
            let devNamePtr = devName.cString(using: String.Encoding.utf8)
            
            //set device type
            let devType:CUnsignedChar = CUnsignedChar(PAEW_DEV_TYPE_BT)
            
            //size of enumContext
            let ctxSize = MemoryLayout.size(ofValue: connectContext);
            
            //currently the last two parameters may be nil (NULL in C)
            let rtn = PAEW_InitContextWithDevNameAndDevContext(&self.pPAEWContext, devNamePtr, devType, &connectContext, ctxSize, self.procCallback, &ViewController.cbParam)
            guard rtn == PAEW_RET_SUCCESS else{
                ViewController.printLog("PAEW_InitContextWithDevNameAndDevContext failed: %@", Utils.errorCodeToString(rtn))
                return
            }
            
            DispatchQueue.main.async {
                //after connection established, you will see batteryCallback be called every 6 seconds
                //to report current battery source and battery level of connected device,
                //if you manually power off the connected device, you should see that disconnectCallback be called
                ViewController.printLog("PAEW_InitContextWithDevNameAndDevContext succeeded: %@", Utils.errorCodeToString(rtn))
                let controller = Test_C_EWallet_ViewController.init(p: self.pPAEWContext!)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    class func printLog(_ format: String, _ args: CVarArg...) {
        let str:String = String.init(format: format, arguments: args)
        print("ViewController.swift: \(str)")
    }
}
