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
            else if (columns[8] == "H1" || columns[8] == "H2") {
                continue
            }
            else if (columns[3] == "") {
                continue
            }
            
            let airportStr = columns[2].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
            
            //if runway width doesn't exist, default to 25 feet, which is the minimum
            var runway_width: Int
            if (columns[4] != "") {
                runway_width = Int(columns[4])!
            }
            else {
                runway_width = 25
            }
            
            //if runway exist on left side of this line
            if(columns[8] != "" && columns[9] != "" && columns[10] != "" && columns[11] != "" && columns[13] != ""){
                let runwayNumStr = columns[8].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                data.addRunway(runway_name: airportStr + runwayNumStr,
                               loc_lat: Double(columns[9])!,
                               loc_lon: Double(columns[10])!,
                               loc_z: Double(columns[11])!,
                               heading: Double(columns[13])!,
                               length: Int(columns[3])!,
                               width: runway_width,
                               surface: surfaceQualityToDouble(surface_str: columns[5]))
            }
            //if runway exist on right side of this line
            if(columns[15] != "" && columns[16] != "" && columns[17] != "" && columns[18] != "" && columns[20] != ""){
                let runwayNumStr = columns[15].replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
                data.addRunway(runway_name: airportStr + runwayNumStr,
                               loc_lat: Double(columns[16])!,
                               loc_lon: Double(columns[17])!,
                               loc_z: Double(columns[18])!,
                               heading: Double(columns[20])!,
                               length: Int(columns[3])!,
                               width: runway_width,
                               surface:surfaceQualityToDouble(surface_str: columns[5]))
            }
        }
        print("Amount of runway read from csv file: " + String(data.size()))
    }
    
    //lat range: -90->90 N
    //lon range: -180->180 E
    //sort runway from close to far by current location
    func sortRunway(lat:Double, lon:Double) {
        var aroundList = data.listRunwaysAround(lat: Int(lat), lon: Int(lon))
        if(aroundList.count == 0) {
            aroundList = data.listRunwaysAll()
            print("sort ALL runways")
        }
        else{
            print("sort partial runways")
        }
        sortedRunways = aroundList.sorted(by: { getGeoDistance(lat,
                                                               lon,
                                                               $0.runway_loc_lat,
                                                               $0.runway_loc_lon)
                                                < getGeoDistance(lat,
                                                                 lon,
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
    
    //TODO remove ""
    private func surfaceQualityToDouble(surface_str: String) -> Double {
//        let str = surface_str.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range:nil)
        let str = surface_str.uppercased()
        
        if (str.range(of:"ASPH") != nil
            || str.range(of:"ASP") != nil
            || str.range(of:"CONC") != nil
            || str.range(of:"CON") != nil
            || str.range(of:"BIT") != nil
            || str.range(of:"PER") != nil
            || str.range(of:"COP") != nil
            || str.range(of:"COM") != nil
            || str.range(of:"COR") != nil
            || str.range(of:"PEM") != nil
            || str.range(of:"UNK") != nil
            || str.range(of:"TAR") != nil
            || str.range(of:"BRI") != nil
            || str.range(of:"MAC") != nil
            || str.range(of:"PAVED") != nil
            || str.range(of:"CLA") != nil) {
            return 1
        }
        else if (str.range(of:"METAL") != nil
            || str.range(of:"PSP") != nil) {
            return 0.5
        }
        else if (str.range(of:"WOOD") != nil) {
            return 0.2
        }
        else if (str.range(of:"TURF") != nil
            || str.range(of:"GRAVEL") != nil
            || str.range(of:"GRVL") != nil
            || str.range(of:"GVL") != nil
            || str.range(of:"DIRT") != nil
            || str.range(of:"GRE") != nil
            || str.range(of:"GRAS") != nil
            || str.range(of:"GRAAS") != nil
            || str.range(of:"GRS") != nil
            || str.range(of:"SAND") != nil
            || str.range(of:"SAN") != nil
            || str.range(of:"LAT") != nil
            || str.range(of:"SNOW") != nil
            || str.range(of:"EARTH") != nil
            || str.range(of:"CORAL") != nil) {
            return 0.1
        }
        else if (str == ""
            || str.range(of:"WATER") != nil
            || str.range(of:"GROUND") != nil) {
            return 0
        }
        else {
            return 0
        }
    }
}
