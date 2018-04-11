//
//  FirstViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit
import CoreLocation

class FirstViewController: UIViewController, CLLocationManagerDelegate  {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var planeLocXText: UITextField!
    @IBOutlet weak var planeLocYText: UITextField!
    @IBOutlet weak var planeLocZText: UITextField!
    @IBOutlet weak var planeHeadingText: UITextField!
    @IBOutlet weak var windSpeedText: UITextField!
    @IBOutlet weak var windHeadingText: UITextField!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startLocationUpdate()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateView), userInfo: nil, repeats: true)
        planeLocXText.text = "?"
        planeLocYText.text = "?"
        planeLocZText.text = "?"
        planeHeadingText.text = "?"
        windSpeedText.text = "?"
        windHeadingText.text = "?"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // update instruction shown on FirstView
    @objc func updateView() {
        //update instruction
        instructionLabel.text = DataUserManager.shared.getInstruction()
        instructionLabel.lineBreakMode = .byWordWrapping
        
        //update wind
        let (wind_speed,wind_heading) = DataUserManager.shared.getWind()
        windSpeedText.text = String(wind_speed)
        windHeadingText.text = String(wind_heading)
    }
    
    func startLocationUpdate() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            locationManager.distanceFilter = 10
            locationManager.headingFilter = 5
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLoc:CLLocation = locations[0] as CLLocation
        planeLocXText.text = String(userLoc.coordinate.latitude)
        planeLocYText.text = String(userLoc.coordinate.longitude)
        planeLocZText.text = String(userLoc.altitude)
        DataUserManager.shared.setGeoLocation(loc_x: userLoc.coordinate.latitude, loc_y: userLoc.coordinate.longitude, loc_z: userLoc.altitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        planeHeadingText.text = String(newHeading.magneticHeading)
        DataUserManager.shared.setHeading(heading: newHeading.magneticHeading)
    }
}

