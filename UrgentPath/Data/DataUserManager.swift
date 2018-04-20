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
    
    //set plane location from modified XPlane input
    func setFromXPlaneString(str:String) {
        //print("[\(str)]\n")
        let parts = str.components(separatedBy: ",")
        if(parts.count != 3) {
            print("Error: input from XPlane is invalid")
            return
        }
        setGeoLocation( Double(parts[0]),
                        Double(parts[1]),
                        Double(parts[2]))
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
    
    //generate guidance to pilots
    func getInstruction() -> String {
        let c_str: UnsafeMutablePointer<Int8>? = TrajectoryCal( -73.8767,
                                                                40.8513,
                                                                0.02745947667,
                                                                1.5586,
                                                                -73.8571,
                                                                40.7721,
                                                                0,
                                                                2.3736,
                                                                0.001,
                                                                240.0,
                                                                17.25,
                                                                9.0,
                                                                40.0,
                                                                0.0)
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
