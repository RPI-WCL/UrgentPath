//
//  DataUserManager.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/6/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

class DataUserManager {
    static let shared = DataUserManager()//singleton
    
    private var data : DataUser
    
    private init() {
        data = DataUser()
    }
    
    //set plane location with given input data
    func setGeoLocation(loc_x:Double,
                        loc_y:Double,
                        loc_z:Double) {
        data.user_loc_x = loc_x
        data.user_loc_y = loc_y
        data.user_loc_z = loc_z
    }
    
    //set plane heading with given input data
    func setHeading(heading:Double) {
        data.user_heading = heading
    }
    
    //set wind speed/heading with given input data
    func setWind(wind_speed:Double,
                 wind_heading:Double) {
        data.wind_speed = wind_speed
        data.wind_heading = wind_heading
    }
    
    //set type of data use for guidance
    func setConnectionType(type:DataUser.Connection) {
        data.connectionType = type
    }
    
    //set plane location from modified XPlane input
    func setFromXPlaneString(str:String) {
        //print("[\(str)]\n")
        let parts = str.components(separatedBy: ",")
        if(Double(parts[0]) == 18 && parts.count == 2){
            //18 is heading
            setHeading(heading: Double(parts[1])!)
        }
        else if(Double(parts[0]) == 20 && parts.count == 4){
            //20 is geo location
            setGeoLocation(loc_x: Double(parts[1])!,
                           loc_y: Double(parts[2])!,
                           loc_z: Double(parts[3])!)
        }
        else{
            print("Error: unknown input from XPlane")
        }
    }
    
    //generate guidance to pilots
    func getInstruction() -> String {
        let planeData = DataPlaneManager.shared.getChosenPlaneConfig()
        DataRunwayManager.shared.sortRunway(loc_x_1: data.user_loc_x, loc_y_1: data.user_loc_y)
        let runwayData = DataRunwayManager.shared.getCloestRunway()
        
        let c_str: UnsafeMutablePointer<Int8>? = TrajectoryCal( data.user_loc_x,//user_x
                                                                data.user_loc_y,//user_y
                                                                data.user_loc_z,//user_z
                                                                data.user_heading,//user_heading
                                                                runwayData.runway_loc_x,//runway_x
                                                                runwayData.runway_loc_y,//runway_y
                                                                runwayData.runway_loc_z,//runway_z
                                                                runwayData.runway_heading,//runway_heading
                                                                planeData.update_interval,//interval
                                                                planeData.best_gliding_airspeed,//best_gliding_speed
                                                                planeData.best_gliding_ratio,//best_gliding_ratio
                                                                planeData.dirty_gliding_ratio,//dirty_gliding_ratio
                                                                data.wind_speed,//wind_speed
                                                                data.wind_heading,//wind_heading
                                                                1)//catch_runway
        if(c_str == nil) {
            NSLog("calculation in c failed\n")
            return "calculation in c failed"
        }
        let str = String(cString: c_str!)
        return str
    }
    
    //return plane location
    func getGeoLocation() -> (Double,Double,Double) {
        return (data.user_loc_x,data.user_loc_y, data.user_loc_z)
    }
    
    //return plane heading
    func getHeading() -> Double {
        return data.user_heading
    }
    
    //return wind speed/heading
    func getWind() -> (Double ,Double) {
        return (data.wind_speed,data.wind_heading)
    }
    
    //get type of data use for guidance
    func getConnectionType() -> DataUser.Connection {
        return data.connectionType
    }
}
