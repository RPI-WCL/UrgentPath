//
//  DataUser.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/6/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

struct DataUser {
    var user_loc_x : Double
    var user_loc_y : Double
    var user_loc_z : Double
    var user_heading : Double
    var wind_speed : Double
    var wind_heading : Double
    
    enum Connection: Equatable {
        case Phone
        case XPlane
    }
    
    var connectionType : Connection
    
    init(user_loc_x : Double = 0,
         user_loc_y : Double = 0,
         user_loc_z : Double = 0,
         user_heading : Double = 0,
         wind_speed : Double = 0,
         wind_heading : Double = 0) {
        self.user_loc_x = user_loc_x
        self.user_loc_y = user_loc_y
        self.user_loc_z = user_loc_z
        self.user_heading = user_heading
        self.wind_speed = wind_speed
        self.wind_heading = wind_heading
        connectionType = Connection.Phone
    }
}
