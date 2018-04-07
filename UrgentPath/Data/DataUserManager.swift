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
    
    private var data = DataUser()
    
    private init() {
        
    }
    
    func setGeoLocation(loc_x:Double,
                        loc_y:Double,
                        loc_z:Double) {
        data.user_loc_x = loc_x
        data.user_loc_y = loc_y
        data.user_loc_z = loc_z
    }
    
    func setHeading(heading:Double) {
        data.user_heading = heading
    }
    
    func setWind(wind_speed:Double,
                    wind_heading:Double) {
        data.wind_speed = wind_speed
        data.wind_heading = wind_heading
    }
    
    func getInstruction() -> String {
        return "not implemented yet"
    }
    
    func getGeoLocation() -> (Double,Double,Double) {
        return (data.user_loc_x,data.user_loc_y, data.user_loc_z)
    }
    
    func getHeading() -> Double {
        return data.user_heading
    }
    
    func getWind() -> (Double ,Double) {
        return (data.wind_speed,data.wind_heading)
    }
    
}
