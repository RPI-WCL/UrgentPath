//
//  FirstViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftSocket

let MAX_UDP_PACKET_SIZE : Int = 1024
let UDP_PORT_LISTENING : Int32 = 60000

class FirstViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var planeLocXText: UITextField!
    @IBOutlet weak var planeLocYText: UITextField!
    @IBOutlet weak var planeLocZText: UITextField!
    @IBOutlet weak var planeHeadingText: UITextField!
    @IBOutlet weak var windSpeedText: UITextField!
    @IBOutlet weak var windHeadingText: UITextField!
    @IBOutlet weak var runwayText: UITextField!
    let udpQueue = DispatchQueue(label: "udp", qos: .utility)
    
    let locationManager = CLLocationManager()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initText()
        startLocationUpdate()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateView), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // update instruction shown on FirstView
    @objc func updateView() {
        //update instruction
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
//        let startTime = Date()
        self.instructionLabel.text = DataUserManager.shared.getInstruction() + "\n" + dateFormatter.string(from: Date())
//        let endTime = Date()
//        let elapsed = endTime.timeIntervalSince(startTime)
//        print("Time elapsed:[\(elapsed)]")
        self.instructionLabel.lineBreakMode = .byWordWrapping
        
        //update wind
        let (wind_speed,wind_heading) = DataUserManager.shared.getWind()
        self.windSpeedText.text = String(wind_speed)
        self.windHeadingText.text = String(wind_heading)
        
        //update current target runway
        self.runwayText.text = DataRunwayManager.shared.getCloestRunway().runway_name
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
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.Phone) {
            let userLoc:CLLocation = locations[0] as CLLocation
            DataUserManager.shared.setGeoLocation(loc_x: userLoc.coordinate.latitude, loc_y: userLoc.coordinate.longitude, loc_z: userLoc.altitude)
        }
        else if (DataUserManager.shared.getConnectionType() == DataUser.Connection.XPlane) {
            udpQueue.async {
                self.handleXPlane()
            }
        }
        else{
            print("Error: invalid connection type")
        }
        let (x,y,z) = DataUserManager.shared.getGeoLocation()
        planeLocXText.text = String(x)
        planeLocYText.text = String(y)
        planeLocZText.text = String(z)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        planeHeadingText.text = String(newHeading.magneticHeading)
        DataUserManager.shared.setHeading(heading: newHeading.magneticHeading)
    }
    
    func initText() {
        planeLocXText.text = "0"
        planeLocYText.text = "0"
        planeLocZText.text = "0"
        planeHeadingText.text = "0"
        windSpeedText.text = "0"
        windHeadingText.text = "0"
    }
    
    func handleXPlane() {
        let server = UDPServer(address: "0.0.0.0", port:UDP_PORT_LISTENING)
        let (byteArray,_,_) = server.recv(MAX_UDP_PACKET_SIZE)
        if let byteArray = byteArray,
        let tmpStr = String(data: Data(byteArray), encoding: .utf8) {
            DataUserManager.shared.setFromXPlaneString(str: tmpStr)
        }
        server.close()
    }
}

