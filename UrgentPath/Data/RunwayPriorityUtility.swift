//
//  RunwayPriorityUtility.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 7/9/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

struct RunwayPriorityUtility {
    var runway_length_max : Int
    var runway_width_max : Int
    var runway_max_distance : Double
    var headwind_max : Double
    var crosswind_max : Double
    var crosswind_min : Double

    init(runway_length_max : Int,
         runway_width_max : Int = 0,
         runway_max_distance : Double,
         headwind_max : Double,
         crosswind_max : Double,
         crosswind_min : Double) {
        self.runway_length_max = runway_length_max
        self.runway_width_max = runway_width_max
        self.runway_max_distance = runway_max_distance
        self.headwind_max = headwind_max
        self.crosswind_max = crosswind_max
        self.crosswind_min = crosswind_min
    }
}
