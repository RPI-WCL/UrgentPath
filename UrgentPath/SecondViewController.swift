//
//  SecondViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit
import Darwin

class SecondViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var pickConfig: UIPickerView!
    @IBOutlet weak var planeTypeLabel: UITextField!
    @IBOutlet weak var updateIntervalLabel: UITextField!
    @IBOutlet weak var bestGlidingSpeedLabel: UITextField!
    @IBOutlet weak var bestGlidingRatioLabel: UITextField!
    @IBOutlet weak var dirtyGlidingRatioLabel: UITextField!
    
    var configData: [DataPlane] = [DataPlane]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup PickerView
        self.pickConfig.delegate = self
        self.pickConfig.dataSource = self
        
        configData = DataPlaneManager.shared.getPlaneConfigAll()
        planeTypeLabel.text = configData[0].plane_type
        updateIntervalLabel.text = String(configData[0].update_interval)
        bestGlidingSpeedLabel.text = String(configData[0].best_gliding_airspeed)
        bestGlidingRatioLabel.text = String(configData[0].best_gliding_ratio)
        dirtyGlidingRatioLabel.text = String(configData[0].dirty_gliding_ratio)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return configData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return configData[row].plane_type
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        planeTypeLabel.text = configData[row].plane_type
        updateIntervalLabel.text = String(configData[row].update_interval)
        bestGlidingSpeedLabel.text = String(configData[row].best_gliding_airspeed)
        bestGlidingRatioLabel.text = String(configData[row].best_gliding_ratio)
        dirtyGlidingRatioLabel.text = String(configData[row].dirty_gliding_ratio)
    }
    
    @IBAction func connectionTypeSwitchChanged(switchConnection : UISwitch!) {
        if switchConnection.isOn {
            DataUserManager.shared.setConnectionType(type: DataUser.Connection.Phone)
        }
        else {
            DataUserManager.shared.setConnectionType(type: DataUser.Connection.XPlane)
        }
    }
    
}
