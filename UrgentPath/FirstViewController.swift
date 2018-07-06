//
//  FirstViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit
import Darwin
import GoogleMaps
import CoreLocation

class FirstViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var planeLocXText: UITextField!
    @IBOutlet weak var planeLocYText: UITextField!
    @IBOutlet weak var planeLocZText: UITextField!
    @IBOutlet weak var planeHeadingText: UITextField!
    @IBOutlet weak var windSpeedText: UITextField!
    @IBOutlet weak var windHeadingText: UITextField!
    @IBOutlet weak var runwayText: UITextField!
    @IBOutlet weak var runwayDistanceText: UITextField!
    
    let runwayQueue = DispatchQueue(label: "runway", qos: .utility)
    
    let locationManager = CLLocationManager()
    var currentLocationMarker: GMSMarker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loc = DataUserManager.shared.getGeoLocation()
        DataRunwayManager.shared.sortRunway(lat: loc.0, lon: loc.1)
        
        initText()
        initMap()
        startLocationUpdate()
        
        //start schedules
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateLocationHeading), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateRunwayText), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateInstruction), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateWind), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateRunwayList), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func initMap() {
        //obtrain url for correct tile
        let urls: GMSTileURLConstructor = {(x, y, zoom) in
            let new_y = Int(pow(Double(2),Double(zoom)))-Int(y)
            let url = "https://www.enjoybeta.com/maps/\(zoom)/\(new_y-1)/\(x).png"
            return URL(string: url)
        }
        
        //create a layer for vfr
        let layer = GMSURLTileLayer(urlConstructor: urls)
        
        //allow larger tile display, less definition but higher zoom performance
        layer.tileSize = 1024
        
        // Display on the map at certain priority
        layer.zIndex = 100
        layer.map = mapView
        
        //move camera to destinated location
        let camera = GMSCameraPosition.camera(withLatitude: 39.8282, longitude: -98.5795, zoom: 4)//TODO
        mapView.animate(to: camera)
        
        //limit the range to zoom, which is actually maxZoom+1
        mapView.setMinZoom(4, maxZoom: 10.99)
        //display the dot marking current location
        mapView.isMyLocationEnabled = false
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = true
        mapView.settings.tiltGestures = false
        
        //setup the default style of google map
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "GoogleMapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find GoogleMapStyle.json")
            }
        } catch {
            NSLog("Map style failed to load. \(error)")
        }
        
        //setup current location marker
        currentLocationMarker = nil
        if let location = locationManager.location {
            currentLocationMarker = GMSMarker(position: location.coordinate)
            currentLocationMarker?.icon = UIImage(named: "arrow-48.png")
            currentLocationMarker?.rotation = locationManager.location?.course ?? 0
            currentLocationMarker?.isFlat = true
            currentLocationMarker?.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            currentLocationMarker?.map = mapView
        }
        
        //TODO remove
        //KALB
        markRunway(startLat:42.7372,startLon:-73.8043,endLat:42.7569,endLon:-73.8051)
    }
    
    //update current target runway text
    @objc func updateRunwayText(){
        self.runwayText.text = DataRunwayManager.shared.getCloestRunway().runway_name
        self.runwayDistanceText.text = formatText(DataUserManager.shared.getDistancePlaneToRunway()) + " km"
    }
    
    @objc func updateRunwayList(){
        runwayQueue.async {
            let data = DataUserManager.shared.getGeoLocation()
            DataRunwayManager.shared.sortRunway(lat: data.0, lon: data.1)
        }
    }
    
    // update instruction shown on FirstView
    @objc func updateLocationHeading() {
        //update location and heading text
        let (loc_lat,loc_lon,loc_z) = DataUserManager.shared.getGeoLocation()
        let loc_heading = DataUserManager.shared.getHeading()
        planeLocXText.text = formatText(loc_lat)
        planeLocYText.text = formatText(loc_lon)
        planeLocZText.text = formatText(loc_z) + " feet"
        planeHeadingText.text = formatText(loc_heading)
//        let camera = GMSCameraPosition.camera(withLatitude: loc_lat, longitude: loc_lon, zoom: 9)
//        mapView.animate(to: camera)
        currentLocationMarker?.position = CLLocationCoordinate2D(latitude: loc_lat, longitude: loc_lon)
        currentLocationMarker?.rotation = loc_heading
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.XPlane) {
            DataUserManager.shared.handleXPlane()
        }
    }
    
    @objc func updateWind() {
        //update wind text
        let (wind_speed,wind_heading) = DataUserManager.shared.getWind()
        self.windSpeedText.text = String(String(wind_speed).prefix(5))
        self.windHeadingText.text = String(String(wind_heading).prefix(5))
    }
    
    //update instruction
    @objc func updateInstruction() {
        //format for time attached behind instruction
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        
        self.instructionLabel.text = DataUserManager.shared.getInstruction() + "\n" + dateFormatter.string(from: Date())
        self.instructionLabel.lineBreakMode = .byWordWrapping
    }
    
    //initalize location/heading update from GPS/compass on phone
    private func startLocationUpdate() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            locationManager.distanceFilter = 10//not going to update if move less than 10 meters
            locationManager.headingFilter = 1//not going to update if degree changes less than 1 degree
        }
    }
    
    //location update from GPS on phone
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.Phone) {
            let userLoc:CLLocation = locations[0] as CLLocation
            DataUserManager.shared.setGeoLocation(loc_x: userLoc.coordinate.latitude, loc_y: userLoc.coordinate.longitude, loc_z: userLoc.altitude)
        }
    }
    
    //heading update from GPS on phone
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.Phone) {
            DataUserManager.shared.setHeading(heading: newHeading.magneticHeading)
        }
    }
    
    private func initText() {
        planeLocXText.text = "0"
        planeLocYText.text = "0"
        planeLocZText.text = "0"
        planeHeadingText.text = "0"
        windSpeedText.text = "0"
        windHeadingText.text = "0"
    }
    
    private func markRunway(startLat:Double,startLon:Double,endLat:Double,endLon:Double) {
        //add a runway
        let path = GMSMutablePath()
        path.add(CLLocationCoordinate2D(latitude: startLat, longitude: startLon))
        path.add(CLLocationCoordinate2D(latitude: endLat, longitude: endLon))
        let poly = GMSPolyline(path: path)
        poly.zIndex = 200
        poly.strokeWidth = 4
        poly.strokeColor = .orange
        poly.map = mapView
    }
    
    private func formatText(_ input:Double) -> String {
        return String(format: "%.3f", input)
    }
}

