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
    let runwayQueue = DispatchQueue(label: "runway", qos: .utility)
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loc = DataUserManager.shared.getGeoLocation()
        DataRunwayManager.shared.sortRunway(lat_N: loc.0, lon_E: loc.1)//change direction of location,NE -> SW
        
        initText()
        startLocationUpdate()
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateLocationHeading), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateView), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateRunway), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func updateRunway(){
        runwayQueue.async {
            let data = DataUserManager.shared.getGeoLocation()
//            let startTime = Date()
            DataRunwayManager.shared.sortRunway(lat_N: data.0, lon_E: data.1)//change direction of location,NE -> SW
//            let endTime = Date()
//            let elapsed = endTime.timeIntervalSince(startTime)
//            print("Time elapsed for sorting:[\(elapsed)]")
        }
    }
    
    // update instruction shown on FirstView
    @objc func updateLocationHeading() {
        //update location and heading text
        let (loc_lat,loc_lon,loc_z) = DataUserManager.shared.getGeoLocation()
        let loc_heading = DataUserManager.shared.getHeading()
        planeLocXText.text = formatText(loc_lat)
        planeLocYText.text = formatText(loc_lon)
        planeLocZText.text = formatText(loc_z)
        planeHeadingText.text = formatText(loc_heading)
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.XPlane){
            handleXPlane()
        }
    }
    
    @objc func updateView() {
        //update instruction
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        
//        let startTime = Date()
        self.instructionLabel.text = DataUserManager.shared.getInstruction() + "\n" + dateFormatter.string(from: Date())
//        let endTime = Date()
//        let elapsed = endTime.timeIntervalSince(startTime)
//        print("Time elapsed for generating instruction:[\(elapsed)]")
        self.instructionLabel.lineBreakMode = .byWordWrapping
        
        //update wind text
        let (wind_speed,wind_heading) = DataUserManager.shared.getWind()
        self.windSpeedText.text = String(String(wind_speed).prefix(5))
        self.windHeadingText.text = String(String(wind_heading).prefix(5))
        
        //update current target runway text
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
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.Phone) {
            DataUserManager.shared.setHeading(heading: newHeading.magneticHeading)
        }
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
        udpQueue.async {
            let server = UDPServer(address: "0.0.0.0", port:UDP_PORT_LISTENING)
            let (byteArray,_,_) = server.recv(MAX_UDP_PACKET_SIZE)
            if let byteArray = byteArray,
                let str = String(data: Data(byteArray), encoding: .utf8) {
                //print("[\(str)]\n")
                let parts = str.components(separatedBy: ",")
                if(parts.count != 4){
                    server.close()
                    return
                }
                DataUserManager.shared.setFromXPlaneString(parts: parts)
            }
            server.close()
        }
    }
    
    func formatText(_ input:Double) -> String {
        return String(format: "%.3f", input)
    }
}

