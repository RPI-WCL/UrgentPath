//
//  DataPlane.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/6/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

struct DataPlane {
    var plane_type : String
    var update_interval : Double
    var best_gliding_airspeed : Double
    var best_gliding_ratio : Double
    var dirty_gliding_ratio : Double
    var plane_rank : Int = 0
    
    init(plane_type: String,
         update_interval : Double,
         best_gliding_airspeed : Double,
         best_gliding_ratio : Double,
         dirty_gliding_ratio : Double,
         plane_rank : Int = 0) {
        self.plane_type = plane_type
        self.update_interval = update_interval
        self.best_gliding_airspeed = best_gliding_airspeed
        self.best_gliding_ratio = best_gliding_ratio
        self.dirty_gliding_ratio = dirty_gliding_ratio
        self.plane_rank = plane_rank
    }
}
