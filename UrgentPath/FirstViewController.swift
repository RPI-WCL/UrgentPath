//
//  FirstViewController.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import UIKit
import Darwin
import Mapbox
import CoreLocation
import Charts

class FirstViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    @IBOutlet weak var mapviewUI: UIView!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var planeLocZText: UITextField!
    @IBOutlet weak var planeHeadingText: UITextField!
    @IBOutlet weak var runwayText: UITextField!
    @IBOutlet weak var runwayDistanceText: UITextField!
    var sectionalLayer: MGLRasterStyleLayer?
    
    let runwayQueue = DispatchQueue(label: "runway", qos: .utility)
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loc = DataUserManager.shared.getGeoLocation()
        DataRunwayManager.shared.sortRunway(lat: loc.0, lon: loc.1)
        
        initText()
        initMap()
        initLineChart()
        startLocationUpdate()
        
        //start schedules
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateLocationHeading), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateRunwayText), userInfo: nil, repeats: true)
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
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        let source = MGLRasterTileSource(identifier: "contours", tileURLTemplates: ["https://wcl.cs.rpi.edu/pilots/data/maptiles/jpg/{z}/{y}/{x}.jpg"], options: [ .tileSize: 256,
                                                                                                                                                                   .tileCoordinateSystem: 1,
                                                                                                                                                                   .minimumZoomLevel: 1,
                                                                                                                                                                   .maximumZoomLevel: 10])
        let layer = MGLRasterStyleLayer(identifier: "contours", source: source)
        style.addSource(source)
        style.addLayer(layer)
        self.sectionalLayer = layer
    }
    
    private func initMap() {
        let styleURL = URL(string: "mapbox://styles/enjoybeta/cjjnu1oam3f8g2snavk9t5r96")
        let mapview = MGLMapView(frame: view.bounds, styleURL: styleURL)
        mapview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapviewUI.addSubview(mapview)
    
        mapview.setCenter(CLLocationCoordinate2D(latitude: 40.7, longitude: -73.9), zoomLevel:9, animated: false)
        mapview.showsUserLocation = true
        mapview.maximumZoomLevel = 10
        mapview.delegate = self
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
//        currentLocationMarker?.position = CLLocationCoordinate2D(latitude: loc_lat, longitude: loc_lon)
//        currentLocationMarker?.rotation = loc_heading
        if(DataUserManager.shared.getConnectionType() == DataUser.Connection.XPlane) {
            DataUserManager.shared.handleXPlane()
        }
    }
    
    //update current target runway text
    @objc func updateRunwayText() {
        self.runwayText.text = DataRunwayManager.shared.getCloestRunway().runway_name
        self.runwayDistanceText.text = formatText(DataUserManager.shared.getDistancePlaneToRunway()) + " km"
    }
    
    //update instruction
    @objc func updateInstruction() {
        //format for time attached behind instruction
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        self.instructionLabel.text = DataUserManager.shared.getInstruction() + "\n" + dateFormatter.string(from: Date()) + " UTC"
        self.instructionLabel.lineBreakMode = .byWordWrapping
    }
    
    @objc func updateRunwayList(){
        runwayQueue.async {
            let data = DataUserManager.shared.getGeoLocation()
            DataRunwayManager.shared.sortRunway(lat: data.0, lon: data.1)
        }
    }
    
    @objc func updateVerticalIndicator() {
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
    
    //Geolocation update from GPS on phone
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
    
    private func markRunway(startLat:Double,startLon:Double,endLat:Double,endLon:Double) {
        
    }
    
    private func formatText(_ input:Double) -> String {
        return String(format: "%.3f", input)
    }
}
