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
    
    func updateGeoLocation(loc_x:Double,
                           loc_y:Double,
                           loc_z:Double){
        data.user_loc_x = loc_x
        data.user_loc_y = loc_y
        data.user_loc_z = loc_z
    }
    
    func updateHeading(heading:Double){
        data.user_heading = heading
    }
    
    func updateWind(wind_speed:Double,
                    wind_heading:Double){
        data.wind_speed = wind_speed
        data.wind_heading = wind_heading
    }
    
    func getInstruction() -> String{
        return "nothing yet"
    }
    
}
