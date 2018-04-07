//
//  DataRunway.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/6/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

struct DataRunway {
    var runway_name : String
    var runway_loc_x : Double
    var runway_loc_y : Double
    var runway_loc_z : Double
    var runway_heading : Double
    var runway_rank : Int = 0
    
    init(runway_name: String,
         runway_loc_x : Double,
         runway_loc_y : Double,
         runway_loc_z : Double,
         runway_heading : Double,
         runway_rank : Int = 0) {
        self.runway_name = runway_name
        self.runway_loc_x = runway_loc_x
        self.runway_loc_y = runway_loc_y
        self.runway_loc_z = runway_loc_z
        self.runway_heading = runway_heading
        self.runway_rank = runway_rank
    }
}
