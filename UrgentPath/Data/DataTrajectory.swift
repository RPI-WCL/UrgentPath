//
//  DataTrajectory.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 7/22/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

struct DataTrajectory {
    var time_curveFirst : Double;
    var time_straight : Double;
    var time_curveSecond : Double;
    var time_spiral : Double;
    var time_extend : Double;
    var degree_curveFirst : Double;
    var degree_curveSecond : Double;
    var degree_spiral : Double;
    var error_code : Int;           // code -1: general calculation failure
                                    // code 0: no error
                                    // code 1: crash during first curve
                                    // code 2: crash during straight
                                    // code 3: crash during second curve
                                    // code 4: crash during spiral
                                    // code 5: reserved
    var runway_name : String;
    
    init(time_curveFirst: Double = 0,
         time_straight: Double = 0,
         time_curveSecond: Double = 0,
         time_spiral: Double = 0,
         time_extend: Double = 0,
         degree_curveFirst: Double = 0.0,
         degree_curveSecond: Double = 0.0,
         degree_spiral: Double = 0.0,
         error_code: Int = 0,
         runway_name: String = "") {
        self.time_curveFirst = time_curveFirst
        self.time_straight = time_straight
        self.time_curveSecond = time_curveSecond
        self.time_spiral = time_spiral
        self.time_extend = time_extend
        self.degree_curveFirst = degree_curveFirst
        self.degree_curveSecond = degree_curveSecond
        self.degree_spiral = degree_spiral
        self.error_code = error_code
        self.runway_name = runway_name
    }
}
