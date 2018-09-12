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
    var runway_lat : Double;
    var runway_lon : Double;
    
    var firstCurveStart_lat : Double;
    var firstCurveStart_lon : Double;
    var firstCurveHalf_lat : Double;
    var firstCurveHalf_lon : Double;
    var straightStart_lat : Double;
    var straightStart_lon : Double;
    var secondCurveStart_lat : Double;
    var secondCurveStart_lon : Double;
    var secondCurveHalf_lat : Double;
    var secondCurveHalf_lon : Double;
    var spiralStart_lat : Double;
    var spiralStart_lon : Double;
    var extendedStart_lat : Double;
    var extendedStart_lon : Double;
}
