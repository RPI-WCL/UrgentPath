//
//  DataRunwayManager.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/7/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation
import CoreLocation

class DataRunwayManager {
    static let shared = DataRunwayManager()//singleton
    
    //private var data : [DataRunway]
    private var data : DataRunwayGlobal
    private var sortedRunways : [DataRunway]
    
    private init() {
        data = DataRunwayGlobal()
        sortedRunways = [DataRunway]()
        readRunwayCSV()
    }
    
    private func readRunwayCSV() {
        let path = Bundle.main.path(forResource: "runways_with_mag_heading", ofType: "csv")
        if(path == nil){
            return
        }
        let url = URL(fileURLWithPath: path!)
        let content = try! NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
        
        let rows = content.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            if(columns.count < 17){
                continue
            }
            let airportStr = columns[2].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
            if(columns[8] != "" && columns[9] != "" && columns[10] != "" && columns[11] != "" && columns[13] != ""){
                let runwayNumStr = columns[8].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                data.addRunway(runway_name: airportStr + runwayNumStr, loc_lat: Double(columns[9])!, loc_lon: Double(columns[10])!, loc_z: Double(columns[11])!, heading: Double(columns[13])!)
            }
            if(columns[15] != "" && columns[16] != "" && columns[17] != "" && columns[18] != "" && columns[20] != ""){
                let runwayNumStr = columns[15].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                data.addRunway(runway_name: airportStr + runwayNumStr, loc_lat: Double(columns[16])!, loc_lon: Double(columns[17])!, loc_z: Double(columns[18])!, heading: Double(columns[20])!)
            }
        }
        print("Amount of runway read from csv file: " + String(data.size()))
    }
    
    //loc_lat_S range: -90->90
    //loc_lon_W range: -180->180
    //sort runway from close to far by current location
    func sortRunway(lat_N loc_lat_N:Double, lon_E loc_lon_E:Double) {
        var aroundList = data.listRunwaysAround(lat: Int(loc_lat_N), lon: Int(loc_lon_E))
        if(aroundList.count == 0) {
            aroundList = data.listRunwaysAll()
            print("sort ALL runways")
        }
        else{
            print("sort partial runways")
        }
        sortedRunways = aroundList.sorted(by: { getGeoDistance(loc_lat_N,
                                                               loc_lon_E,
                                                               $0.runway_loc_lat,
                                                               $0.runway_loc_lon)
                                                < getGeoDistance(loc_lat_N,
                                                                 loc_lon_E,
                                                                 $1.runway_loc_lat,
                                                                 $1.runway_loc_lon) })
    }
    
    func getCloestRunway() -> DataRunway {
        return sortedRunways[0]
    }
    
    //return distance between given 2 points in [meters]
    private func getGeoDistance(_ loc_lat_1:Double,
                                _ loc_lon_1:Double,
                                _ loc_lat_2:Double,
                                _ loc_lon_2:Double) -> Double {
        let loc1 = CLLocation(latitude: loc_lat_1, longitude: loc_lon_1)
        let loc2 = CLLocation(latitude: loc_lat_2, longitude: loc_lon_2)
        return loc1.distance(from: loc2)
    }
}
