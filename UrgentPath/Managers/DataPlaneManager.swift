//
//  DataPlaneManager.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/6/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

class DataPlaneManager {
    static let shared = DataPlaneManager()//singleton
    
    private var currentPlaneIndex : Int
    private var data : [DataPlane]
    
    private init() {
        currentPlaneIndex = 0
        data = [DataPlane]()
        let config_plane_a320 = DataPlane(plane_type: "A320",
                                          update_interval: 0.001,
                                          best_gliding_airspeed: 240.0,
                                          best_gliding_ratio: 17.25,
                                          dirty_gliding_ratio: 9.0)
        let config_plane_cessna172 = DataPlane( plane_type: "Cessna 172SP",
                                                update_interval: 0.001,//TODO supposed to be 0.0001
                                                best_gliding_airspeed: 68.0,
                                                best_gliding_ratio: 9.0,
                                                dirty_gliding_ratio: 7.0)
        data.append(config_plane_a320)
        data.append(config_plane_cessna172)
    }
    
    func getPlaneConfigAll() -> [DataPlane] {
        return data
    }
    
    func getPlaneConfigWithIndex(index:Int) -> DataPlane {
        return data[index]
    }
    
    func getChosenPlaneConfig() -> DataPlane {
        return data[currentPlaneIndex]
    }
    
    func getConfigAmount() -> Int {
        return data.count
    }
    
    func setCurrentIndex(index:Int){
        currentPlaneIndex = index
    }
}
