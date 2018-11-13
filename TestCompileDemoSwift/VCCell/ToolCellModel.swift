//
//  ToolCellModel.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/1.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit

class ToolCellModel: NSObject {
    var peripheralName:String = ""
    var RSSI:Int = 0
    var state:Int = 0
    
    init(peripheralName:String, RSSI:Int, state:Int) {
        self.peripheralName = peripheralName
        self.RSSI = RSSI
        self.state = state
        super.init()
    }
}

/*
 
 
 
 
 
 */
