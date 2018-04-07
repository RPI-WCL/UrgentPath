//
//  FirstViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var planeLocXLabel: UITextField!
    @IBOutlet weak var planeLocYLabel: UITextField!
    @IBOutlet weak var planeLocZLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateView), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // update instruction shown on FirstView
    @objc func updateView() {
        //update instruction
        instructionLabel.text = DataUserManager.shared.getInstruction()
        instructionLabel.lineBreakMode = .byWordWrapping
        
        //update geo location
        let (loc_x,loc_y,loc_z) = DataUserManager.shared.getGeoLocation()
        planeLocXLabel.text = String(loc_x)
        planeLocYLabel.text = String(loc_y)
        planeLocZLabel.text = String(loc_z)
    }
}

