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
    @IBOutlet weak var planeLocXText: UITextField!
    @IBOutlet weak var planeLocYText: UITextField!
    @IBOutlet weak var planeLocZText: UITextField!
    @IBOutlet weak var planeHeadingText: UITextField!
    @IBOutlet weak var windSpeedText: UITextField!
    @IBOutlet weak var windHeadingText: UITextField!
    
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
        planeLocXText.text = String(loc_x)
        planeLocYText.text = String(loc_y)
        planeLocZText.text = String(loc_z)
        
        //update heading
        let plane_heading = DataUserManager.shared.getHeading()
        planeHeadingText.text = String(plane_heading)
        
        //update wind
        let (wind_speed,wind_heading) = DataUserManager.shared.getWind()
        windSpeedText.text = String(wind_speed)
        windHeadingText.text = String(wind_heading)
    }
}

