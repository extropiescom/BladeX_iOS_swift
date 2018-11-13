//
//  ToolCell.swift
//  TestCompileDemoSwift
//
//  Created by Peng Wei on 2018/11/2.
//  Copyright © 2018年 extropies. All rights reserved.
//

import UIKit
import CoreBluetooth

class ToolCell: UITableViewCell {

    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var servicesLabel: UILabel!
    
    var peripheral:ToolCellModel? = nil
    
    static let height:CGFloat = 80.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
    func setPeripheral(model:ToolCellModel) {
        //
        peripheral = model ;
        
        self.servicesLabel.text = model.peripheralName ;
        self.RSSILabel.text = String.init(format: "%d", model.RSSI)
        
        if (model.state == CBPeripheralState.connected.rawValue) {
            self.stateLabel.text = "connected";
            self.stateLabel.backgroundColor = UIColor.green;
        }else{
            self.stateLabel.backgroundColor = UIColor.orange;
            self.stateLabel.text = "disconnected";
        }
    }

}
