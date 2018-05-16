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
    @IBOutlet weak var connectionTypeSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup PickerView
        self.pickConfig.delegate = self
        self.pickConfig.dataSource = self
        
        let planeConfig = DataPlaneManager.shared.getChosenPlaneConfig()
        planeTypeLabel.text = planeConfig.plane_type
        updateIntervalLabel.text = String(planeConfig.update_interval)
        bestGlidingSpeedLabel.text = String(planeConfig.best_gliding_airspeed)
        bestGlidingRatioLabel.text = String(planeConfig.best_gliding_ratio)
        dirtyGlidingRatioLabel.text = String(planeConfig.dirty_gliding_ratio)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //number of components/columns picker view should display
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DataPlaneManager.shared.getConfigAmount()
    }
    
    //shown title on the picker view
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return DataPlaneManager.shared.getPlaneConfigWithIndex(index:row).plane_type
    }
    
    //update info when select new row
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        DataPlaneManager.shared.setCurrentIndex(index: row)
//        let planeConfig : DataPlane = DataPlaneManager.shared.getChosenPlaneConfig()
//        planeTypeLabel.text = planeConfig.plane_type
//        updateIntervalLabel.text = String(planeConfig.update_interval)
//        bestGlidingSpeedLabel.text = String(planeConfig.best_gliding_airspeed)
//        bestGlidingRatioLabel.text = String(planeConfig.best_gliding_ratio)
//        dirtyGlidingRatioLabel.text = String(planeConfig.dirty_gliding_ratio)
    }
    
    @IBAction func connectionTypeSwitchChanged(switchConnection : UISwitch!) {
        DataUserManager.shared.setGeoLocation(loc_x: 0, loc_y: 0, loc_z: 0)
        DataUserManager.shared.setHeading(heading: 0)
        DataUserManager.shared.setWind(wind_speed: 0, wind_heading: 0)
        if switchConnection.isOn {
            DataUserManager.shared.setConnectionType(type: DataUser.Connection.XPlane)
        }
        else {
            DataUserManager.shared.setConnectionType(type: DataUser.Connection.Phone)
        }
    }
    
}
