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
    func getTrajectory() -> DataTrajectory? {
        print("======================================================")
        let runwayDataList = DataRunwayManager.shared.getCloestRunways()
        if (runwayDataList.count == 0) {
            return nil//"No route found - (farther than approximate footprint)"
        }
        let start = DispatchTime.now()
        let listOfTrajectory : [DataTrajectory] = listTrajectory(runways: runwayDataList)
        let end = DispatchTime.now()
        let timeInterval: Double = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)/1000000000
        print(String(timeInterval) + " [" + String(runwayDataList.count) + "]")
        
        if(listOfTrajectory.count == 0) {
            return nil//"No route found - (no trajectory found)"
        }
        let rankedTrajectory = rankTrajectory(trajectories: listOfTrajectory)
        return rankedTrajectory
    }
    
    //return distance from plane to target runway
    //unit in km
    func getDistancePlaneToRunway(runway_lat:Double, runway_lon:Double) -> Double {
        let loc1 = CLLocation(latitude: data.user_loc_lat, longitude: data.user_loc_lon)
        let loc2 = CLLocation(latitude: runway_lat, longitude: runway_lon)
        let estimateDistance = loc1.distance(from: loc2)
        return estimateDistance/1000
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
    
    //list all trajectories from given runways
    private func listTrajectory(runways:[DataRunway]) -> [DataTrajectory] {
        let planeData = DataPlaneManager.shared.getChosenPlaneConfig()
        var ret = [DataTrajectory]()
        let trajPtr = UnsafeMutablePointer<TrajectoryData>.allocate(capacity: 1)
        for runwayData in runways {
            TrajectoryCal(  trajPtr,
                            data.user_loc_lat,//user_x //TODO:
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
            let error_code = Int(trajPtr.pointee.error_code)
            if(error_code != 0) {
                continue
            }
            let tmp = DataTrajectory(time_curveFirst: trajPtr.pointee.time_curveFirst,
                                     time_straight: trajPtr.pointee.time_straight,
                                     time_curveSecond: trajPtr.pointee.time_curveSecond,
                                     time_spiral: trajPtr.pointee.time_spiral,
                                     time_extend: trajPtr.pointee.time_extend,
                                     degree_curveFirst: trajPtr.pointee.degree_curveFirst,
                                     degree_curveSecond: trajPtr.pointee.degree_curveSecond,
                                     degree_spiral: trajPtr.pointee.degree_spiral,
                                     error_code: Int(trajPtr.pointee.error_code),
                                     runway_name: runwayData.runway_name,
                                     runway_lat: runwayData.runway_loc_lat,
                                     runway_lon: runwayData.runway_loc_lon,
                                     firstCurveStart_lat: trajPtr.pointee.firstCurveStart_lat,
                                     firstCurveStart_lon: trajPtr.pointee.firstCurveStart_lon,
                                     straightStart_lat: trajPtr.pointee.straightStart_lat,
                                     straightStart_lon: trajPtr.pointee.straightStart_lon,
                                     secondCurveStart_lat: trajPtr.pointee.secondCurveStart_lat,
                                     secondCurveStart_lon: trajPtr.pointee.secondCurveStart_lon,
                                     spiralStart_lat: trajPtr.pointee.spiralStart_lat,
                                     spiralStart_lon: trajPtr.pointee.spiralStart_lon,
                                     extendedStart_lat: trajPtr.pointee.extendedStart_lat,
                                     extendedStart_lon: trajPtr.pointee.extendedStart_lon)
            ret.append(tmp)
        }
        trajPtr.deinitialize(count: 1)
        return ret
    }
    
    //TODO: sort the trajectories with utility function
    private func rankTrajectory(trajectories:[DataTrajectory]) -> DataTrajectory {
        
        
        return trajectories.first!
    }
    
}
