//
//  DataUserManager.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 4/6/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftSocket

let UDP_PORT_LISTENING : Int32 = 60000
let MAX_UDP_PACKET_SIZE : Int = 1024

class DataUserManager {
    static let shared = DataUserManager()//singleton
    
    private var data : DataUser

    private let udpQueue : DispatchQueue
    private var server : UDPServer
    
    private init() {
        data = DataUser()
        udpQueue = DispatchQueue(label: "udp", qos: .utility)
        server = UDPServer(address: "0.0.0.0", port:UDP_PORT_LISTENING)
    }
    
    //set plane location with given input data
    func setGeoLocation(loc_x:Double,
                        loc_y:Double,
                        loc_z:Double) {
        data.user_loc_lat = loc_x
        data.user_loc_lon = loc_y
        data.user_loc_z = loc_z
    }
    
    //set plane heading with given input data
    func setHeading(heading:Double) {
        data.user_heading = heading
    }
    
    //set wind speed/heading with given input data
    func setWind(wind_speed:Double,
                 wind_heading:Double) {
        data.wind_speed = wind_speed
        data.wind_heading = wind_heading
    }
    
    //set type of data use for guidance
    func setConnectionType(type:DataUser.Connection) {
        data.connectionType = type
    }
    
    func handleXPlane() {
        udpQueue.async {
            let (byteArray,_,_) = self.server.recv(MAX_UDP_PACKET_SIZE)
            if let byteArray = byteArray,
                let str = String(data: Data(byteArray), encoding: .utf8) {
                //print("[\(str)]\n")
                let parts = str.components(separatedBy: ",")
                if(parts.count != 4){
                    return
                }
                DataUserManager.shared.setFromXPlaneStringArray(parts: parts)
            }
        }
    }
    
    //set plane location from modified XPlane input
    func setFromXPlaneStringArray(parts:[String]) {
        if(parts.count == 4){
            setGeoLocation(loc_x: Double(parts[0])!,
                           loc_y: Double(parts[1])!,
                           loc_z: Double(parts[2])!)
            setHeading(heading: Double(parts[3])!)
        }
        else{
            print("Error: unknown input from XPlane")
        }
    }
    
    //generate guidance to pilots
    func getInstruction() -> String {
        print("======================================================")
        let planeData = DataPlaneManager.shared.getChosenPlaneConfig()
        let runwayData = DataRunwayManager.shared.getCloestRunway()
        print("Target runway: " + runwayData.runway_name)
        
        let loc1 = CLLocation(latitude: data.user_loc_lat, longitude: data.user_loc_lon)
        let loc2 = CLLocation(latitude: runwayData.runway_loc_lat, longitude: runwayData.runway_loc_lon)
        let estimateDistance = loc1.distance(from: loc2)
        print("Estimate distance: " + String(estimateDistance/1000))
        
        // if the distance between plane and airport is larger than 100km, plane is not likely to reach runway
        // prevent runtime error in Trajectory generation code
        if(estimateDistance/1000 > 100){
            return "No route found - pre-calculation (>100km)"
        }
        
        let c_str: UnsafeMutablePointer<Int8>? = TrajectoryCal( data.user_loc_lat,//user_x
                                                                data.user_loc_lon,//user_y
                                                                data.user_loc_z,//user_z
                                                                data.user_heading,//user_heading
                                                                runwayData.runway_loc_lat,//runway_x
                                                                runwayData.runway_loc_lon,//runway_y
                                                                runwayData.runway_loc_z,//runway_z
                                                                runwayData.runway_heading,//runway_heading
                                                                planeData.update_interval,//interval
                                                                planeData.best_gliding_airspeed,//best_gliding_speed
                                                                planeData.best_gliding_ratio,//best_gliding_ratio
                                                                planeData.dirty_gliding_ratio,//dirty_gliding_ratio
                                                                data.wind_speed,//wind_speed
                                                                data.wind_heading,//wind_heading
                                                                1)//catch_runway
        if(c_str == nil) {
            NSLog("calculation failed\n")
            return "calculation failed"
        }
        let str = String(cString: c_str!)
        return str
    }
    
    //return plane location
    func getGeoLocation() -> (Double,Double,Double) {
        return (data.user_loc_lat,data.user_loc_lon, data.user_loc_z)
    }
    
    //return plane heading
    func getHeading() -> Double {
        return data.user_heading
    }
    
    //return wind speed/heading
    func getWind() -> (Double ,Double) {
        return (data.wind_speed,data.wind_heading)
    }
    
    //get type of data use for guidance
    func getConnectionType() -> DataUser.Connection {
        return data.connectionType
    }
}
