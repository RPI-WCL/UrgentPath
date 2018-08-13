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
import Charts

let MAPTILESERVERADDRESS = "https://wcl.cs.rpi.edu/pilots/data/maptiles/jpg/"

class FirstViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var locationBtn: UIButton!
    @IBAction func tapLocationBtn(_ sender: UIButton) {
        let (lat,lon,_) = DataUserManager.shared.getGeoLocation()
        mapView.animate(toLocation: CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var planeLocZText: UITextField!
    @IBOutlet weak var planeHeadingText: UITextField!
    @IBOutlet weak var runwayText: UITextField!
    @IBOutlet weak var runwayDistanceText: UITextField!
    
    let runwayQueue = DispatchQueue(label: "runway", qos: .utility)
    
    let locationManager = CLLocationManager()
    var currentLocationMarker: GMSMarker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loc = DataUserManager.shared.getGeoLocation()
        let heading = DataUserManager.shared.getHeading()
        DataRunwayManager.shared.sortRunway(lat: loc.0, lon: loc.1, heading: heading)
        
        initText()
        initMap()
        initLineChart()
        startLocationUpdate()
        
        //start schedules
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateLocationHeading), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateInstruction), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateRunwayList), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateVerticalIndicator), userInfo: nil, repeats: true)//TODO 1 -> 5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func initText() {
        planeLocZText.text = "0"
        planeHeadingText.text = "0"
    }
    
    private func initMap() {
        //obtrain url for correct tile
        let urls: GMSTileURLConstructor = {(x, y, zoom) in
            let new_y = Int(pow(Double(2),Double(zoom)))-Int(y)
            let url = MAPTILESERVERADDRESS + "\(zoom)/\(new_y-1)/\(x).jpg"
            return URL(string: url)
        }
        
        //create a layer for vfr
        let layer = GMSURLTileLayer(urlConstructor: urls)
        
        //allow larger tile display, less definition but higher zoom performance
        layer.tileSize = 1024
        
        // Display on the map at certain priority
        layer.zIndex = 100
        layer.map = mapView
        
        //limit the range to zoom, which is actually maxZoom+1
        mapView.setMinZoom(1, maxZoom: 10.99)
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
        
        locationBtn.layer.cornerRadius = 0.5 * locationBtn.frame.width
        locationBtn.setImage(UIImage(named: "location-64.png"), for: .normal)
        mapView.bringSubview(toFront: locationBtn)
    }
    
    private func initLineChart() {
        var chartEntry = [ChartDataEntry]()
        let current_time = Double(Date().timeIntervalSince1970)
        let value = ChartDataEntry(x: current_time, y: 0.0)
        chartEntry.append(value)
        let attitude_line = LineChartDataSet(values: chartEntry, label: "Altitude(feet)")
        attitude_line.colors = [NSUIColor.blue]
        attitude_line.drawCirclesEnabled = false
        attitude_line.drawValuesEnabled = false
        
        //assign the line to data then to chartView
        let data = LineChartData()
        data.addDataSet(attitude_line)
        lineChartView.data = data
        
        //setup the outlook of the line chart
        lineChartView.chartDescription?.text  = ""
        lineChartView.legend.enabled = false
        lineChartView.rightAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.enabled = false
        lineChartView.leftAxis.enabled = false
        lineChartView.rightAxis.enabled = true
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
    
    // update instruction shown on FirstView
    @objc func updateLocationHeading() {
        //update location and heading text
        let (loc_lat,loc_lon,loc_z) = DataUserManager.shared.getGeoLocation()
        let loc_heading = DataUserManager.shared.getHeading()
        planeLocZText.text = formatText(loc_z) + " feet"
        planeHeadingText.text = formatText(loc_heading)
        currentLocationMarker?.position = CLLocationCoordinate2D(latitude: loc_lat, longitude: loc_lon)
        currentLocationMarker?.rotation = loc_heading
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.XPlane) {
            DataUserManager.shared.handleXPlane()
        }
    }
    
    //update instruction
    @objc func updateInstruction() {
        //format for time attached behind instruction
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let traj = DataUserManager.shared.getTrajectory()
        if (traj == nil) {
            self.instructionLabel.text = "no route found" + "\n" + dateFormatter.string(from: Date()) + " UTC"
        }
        else {
            var trajStr = "30 degree bank " + formatText(traj!.time_curveFirst,0) + " seconds -> " + formatText(traj!.degree_curveFirst,1) + "°\n"
            trajStr += "Straight line glide " + formatText(traj!.time_straight,0)  + " seconds\n"
            trajStr += "30 degree bank " + formatText(traj!.time_curveSecond,0) + " seconds -> " + formatText(traj!.degree_curveSecond,1) + "°\n"
            trajStr += "30 degree bank spiral " + formatText(traj!.time_spiral,0) + "  seconds -> " + formatText(traj!.degree_spiral,1) + "°\n"
            trajStr += "Dirty configuration straight glide " + formatText(traj!.time_extend,0) + "  seconds"
            self.instructionLabel.text = trajStr + "\n" + dateFormatter.string(from: Date()) + " UTC"
            self.runwayText.text = traj!.runway_name
            drawTrajectory(firstCurve_lat: traj!.firstCurveStart_lat,
                           firstCurve_lon: traj!.firstCurveStart_lon,
                           straight_lat: traj!.straightStart_lat,
                           straight_lon: traj!.straightStart_lon,
                           secondCurve_lat: traj!.secondCurveStart_lat,
                           secondCurve_lon: traj!.secondCurveStart_lon,
                           spiral_lat: traj!.spiralStart_lat,
                           spiral_lon: traj!.spiralStart_lon,
                           extended_lat: traj!.extendedStart_lat,
                           extended_lon: traj!.extendedStart_lon,
                           runway_lat: traj!.runway_lat,
                           runway_lon: traj!.runway_lon)
        }
        self.instructionLabel.lineBreakMode = .byWordWrapping
    }
    
    @objc func updateRunwayList(){
        runwayQueue.async {
            let location_data = DataUserManager.shared.getGeoLocation()
            let heading = DataUserManager.shared.getHeading()
            DataRunwayManager.shared.sortRunway(lat: location_data.0, lon: location_data.1, heading: heading)
        }
    }
    
    @objc func updateVerticalIndicator(){
        //the data will be put into line chart
        let current_time = Double(Date().timeIntervalSince1970)
        let (_,_,loc_z) = DataUserManager.shared.getGeoLocation()
        
        //target the dataset as 0 since its the only one right now
        let dataset = lineChartView.lineData?.getDataSetByIndex(0)!
        
        //let rand_int = Double(arc4random_uniform(UInt32(100 + 1)))
        let entry = ChartDataEntry(x: current_time, y: loc_z)
        _ = dataset!.addEntry(entry)
        
        //only allowing viewing the latest data
        lineChartView.setVisibleXRangeMaximum(100)
        lineChartView.moveViewToX(current_time)//TODO clean dataset when too much data occupies memory
        
        //update the lineChartView
        lineChartView.data?.notifyDataChanged()
        lineChartView.notifyDataSetChanged()
    }
    
    //location update from GPS on phone
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.Phone) {
            let userLoc:CLLocation = locations[0] as CLLocation
            DataUserManager.shared.setGeoLocation(loc_x: userLoc.coordinate.latitude, loc_y: userLoc.coordinate.longitude, loc_z: userLoc.altitude)
            //TODO
            let camera = GMSCameraPosition.camera(withLatitude: userLoc.coordinate.latitude, longitude: userLoc.coordinate.longitude, zoom: 10.99)
            mapView.animate(to: camera)
        }
    }
    
    //heading update from GPS on phone
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.Phone) {
            DataUserManager.shared.setHeading(heading: newHeading.magneticHeading)
        }
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
    
    private func drawTrajectory(firstCurve_lat: Double,
                                firstCurve_lon: Double,
                                straight_lat: Double,
                                straight_lon: Double,
                                secondCurve_lat: Double,
                                secondCurve_lon: Double,
                                spiral_lat: Double,
                                spiral_lon: Double,
                                extended_lat: Double,
                                extended_lon: Double,
                                runway_lat: Double,
                                runway_lon: Double) {
        
    }
    
    private func formatText(_ text:Double, _ digit:Int = 2) -> String {
        if (digit == 0) {
            return String(format: "%d", Int(text+0.5))
        }
        else if (digit == 1) {
            return String(format: "%.1f", text)
        }
        else {
            return String(format: "%.2f", text)
        }
    }
}
