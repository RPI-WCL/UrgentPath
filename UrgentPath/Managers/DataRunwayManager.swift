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
    
    private var data : [DataRunway]
    private var lastSortTime : Date
    
    private init() {
        data = [DataRunway]()
        lastSortTime = Date(timeIntervalSince1970: 0)
        readRunwayCSV()
    }
    
    private func readRunwayCSV() {
        let path = Bundle.main.path(forResource: "runways", ofType: "csv")
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
            if(columns[9] != "" && columns[10] != "" && columns[11] != "" && columns[12] != ""){
                let runwayNumStr = columns[12].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                let runway1 = DataRunway(runway_name: airportStr + runwayNumStr,
                                         runway_loc_x: Double(columns[9])!,
                                         runway_loc_y: Double(columns[10])!,
                                         runway_loc_z: Double(columns[11])!/364173.0,//TODO
                                         runway_heading: Double(0))//TODO
                data.append(runway1)
            }
            if(columns[14] != "" && columns[15] != "" && columns[16] != "" && columns[17] != ""){
                let runwayNumStr = columns[14].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                let runway2 = DataRunway(runway_name: airportStr + runwayNumStr,
                                         runway_loc_x: Double(columns[15])!,
                                         runway_loc_y: Double(columns[16])!,
                                         runway_loc_z: Double(columns[17])!/364173.0,//TODO
                                         runway_heading: Double(0))//TODO
                data.append(runway2)
            }
        }
        print("Amount of runway read from csv file: " + String(data.count))
    }
    
    //sort runway from close to far by current location
    func sortRunway(loc_x_1:Double, loc_y_1:Double) {
        let elapsed = Date().timeIntervalSince(lastSortTime)
        if(elapsed < 120){ //update target airport every 120 seconds
            return
        }
        data = data.sorted(by: { getGeoDistance(loc_x_1,
                                                loc_y_1,
                                                $0.runway_loc_x,
                                                $0.runway_loc_y)
                                > getGeoDistance(loc_x_1,
                                                 loc_y_1,
                                                 $1.runway_loc_x,
                                                 $1.runway_loc_y) })
        lastSortTime = Date()
    }
    
    func getCloestRunway() -> DataRunway {
        return data[0]
    }
    
    //return distance between given 2 points in [meters]
    private func getGeoDistance(_ loc_x_1:Double,
                                _ loc_y_1:Double,
                                _ loc_x_2:Double,
                                _ loc_y_2:Double) -> Double {
        let loc1 = CLLocation(latitude: loc_x_1, longitude: loc_y_1)
        let loc2 = CLLocation(latitude: loc_x_2, longitude: loc_y_2)
        return loc1.distance(from: loc2)
    }
}
