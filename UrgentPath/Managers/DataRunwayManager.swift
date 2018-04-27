//
//  DataRunwayManager.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/7/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation
import CoreLocation

class DataRunwayManager {
    static let shared = DataRunwayManager()//singleton
    
    private var data : [DataRunway]
    
    private init() {
        data = [DataRunway]()
        let runway_LGA31 = DataRunway(runway_name: "LGA31",
                                      runway_loc_x: -73.8571,
                                      runway_loc_y: 40.7721,
                                      runway_loc_z: 0,
                                      runway_heading: 2.3736)
        data.append(runway_LGA31)
    }
    
    //sort runway from close to far by current location
    func sortRunway(loc_x_1:Double, loc_y_1:Double) {
        data = data.sorted(by: { getGeoDistance(loc_x_1,
                                                loc_y_1,
                                                $0.runway_loc_x,
                                                $0.runway_loc_y)
                                > getGeoDistance(loc_x_1,
                                                 loc_y_1,
                                                 $1.runway_loc_x,
                                                 $1.runway_loc_y) })
    }
    
    func getCloestRunway() -> DataRunway {
        return data[0]
    }
    
    //return distance between given 2 points in [meters]
    private func getGeoDistance(_ loc_x_1:Double,
                                _ loc_y_1:Double,
                                _ loc_x_2:Double,
                                _ loc_y_2:Double) -> Double {
        let loc1 = CLLocation(latitude: loc_x_1, longitude: loc_y_1)
        let loc2 = CLLocation(latitude: loc_x_2, longitude: loc_y_2)
        return loc1.distance(from: loc2)
    }
}
