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
    @IBOutlet weak var nameLabel: UITextField!
    
    var configData: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.pickConfig.delegate = self
        self.pickConfig.dataSource = self
        configData = ["Cessna 172", "Boeing 777"]
        nameLabel.text = configData[0]
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
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return configData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        nameLabel.text = configData[row]
    }
    
}
