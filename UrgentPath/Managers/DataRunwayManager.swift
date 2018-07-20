//
//  DataRunwayManager.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/7/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation
import CoreLocation

//weight to prioritize runways
let C1 = 0.1//runway length
let C2 = 0.1//runway width
let C3 = 0.0//instrument quality
let C4 = 1.0//distance to runway
let C5 = 0.0//headwind
let C6 = 0.0//crosswind
let C7 = 0.1//runway surface
let C8 = 0.0//facility

class DataRunwayManager {
    static let shared = DataRunwayManager()//singleton
    
    private var data : DataRunwayGlobal
    private var closebyRunways : [DataRunway]
    
    private init() {
        data = DataRunwayGlobal()
        closebyRunways = [DataRunway]()
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
                continue//ignore heli pads
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
    
    //lat range: [-90,90) N
    //lon range: [-180,180) E
    //sort runway from close to far by current location
    func sortRunway(lat:Double, lon:Double, heading:Double) {
        var aroundList = data.listRunwaysAround(lat: Int(lat), lon: Int(lon))
        let (_,_,alt) = DataUserManager.shared.getGeoLocation()
        let planeConfig = DataPlaneManager.shared.getChosenPlaneConfig()
        var filteredList = filterPossibleRunway(runways: aroundList,
                                          usr_lat: lat,
                                          usr_lon: lon,
                                          heading: heading,
                                          altitude: alt,
                                          glide_ratio: planeConfig.best_gliding_ratio,
                                          glide_speed: planeConfig.best_gliding_airspeed)
        if(aroundList.count == 0) {
            print("sort ALL runways")
            aroundList = data.listRunwaysAll()
            closebyRunways = aroundList.sorted(by: { getGeoDistance(lat,
                                                                   lon,
                                                                   $0.runway_loc_lat,
                                                                   $0.runway_loc_lon)
                                                    < getGeoDistance(lat,
                                                                     lon,
                                                                     $1.runway_loc_lat,
                                                                     $1.runway_loc_lon) })
            return
        }
        else if (filteredList.count == 0) {
            print("sort runways in grid")
            filteredList = aroundList
        }
        else{
            print("sort filtered runways")
        }
        let runway_length_max = filteredList.map{$0.runway_length}.max()!
        let runway_width_max = filteredList.map{$0.runway_width}.max()!
        let runway_max_dis = (filteredList.map{getGeoDistance($0.runway_loc_lat, $0.runway_loc_lon, lat, lon)}.max()!)/1000
        let runwayPriorityUtility = RunwayPriorityUtility(  runway_length_max: runway_length_max,
                                                            runway_width_max: runway_width_max,
                                                            runway_max_distance: runway_max_dis,//TODO ?
                                                            headwind_max: 1,//TODO
                                                            crosswind_max: 1,
                                                            crosswind_min: 0)
        closebyRunways = filteredList.sorted(by: { getRunwayRating(lat,
                                                                  lon,
                                                                  heading,
                                                                  $0,
                                                                  runwayPriorityUtility)
                                                > getRunwayRating(lat,
                                                                  lon,
                                                                  heading,
                                                                  $1,
                                                                  runwayPriorityUtility) })
    }
    
    func getCloestRunway() -> DataRunway {
        return closebyRunways[0]
    }
    
    //filter out runways not possible with airplane current altitude and heading
    private func filterPossibleRunway(runways: [DataRunway],
                                      usr_lat:Double,
                                      usr_lon:Double,
                                      heading:Double,
                                      altitude:Double,
                                      glide_ratio:Double,
                                      glide_speed:Double) -> [DataRunway] {
        let dis = altitude * glide_ratio / 3.28 // unit is meter
        let filtered = runways.filter{ getGeoDistance($0.runway_loc_lat, $0.runway_loc_lon, usr_lat, usr_lon) < dis }
        return filtered
    }
    
    //return rating for runway regarding current situation
    private func getRunwayRating(_ loc_lat_1:Double,
                                _ loc_lon_1:Double,
                                _ heading:Double,
                                _ runway:DataRunway,
                                _ utility:RunwayPriorityUtility) -> Double {
        let loc1 = CLLocation(latitude: loc_lat_1, longitude: loc_lon_1)
        let loc2 = CLLocation(latitude: runway.runway_loc_lat, longitude: runway.runway_loc_lon)
        let dis = loc1.distance(from: loc2)/1000
        
        let rating_runway_length = C1 * Double(runway.runway_length) / Double(utility.runway_length_max)
        let rating_runway_width = C2 * Double(runway.runway_width) / Double(utility.runway_width_max)
        let rating_instrument_quality = C3 * 0
        let rating_distance = C4 * ((utility.runway_max_distance - dis) / utility.runway_max_distance)// TODO
        let rating_headwind = C5 * 0 / utility.headwind_max
        let rating_crosswind = C6 * (utility.crosswind_max - 0)/(utility.crosswind_max - utility.crosswind_min)
        let rating_surface = C7 * runway.runway_surface_quality
        let rating_facility = C8 * 0
        let rating = rating_runway_length + rating_runway_width + rating_instrument_quality
                    + rating_distance + rating_headwind + rating_crosswind + rating_surface + rating_facility
        return rating
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
    
    private func surfaceQualityToDouble(surface_str: String) -> Double {
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
