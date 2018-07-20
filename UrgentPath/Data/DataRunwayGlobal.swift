//
//  DataRunwayGlobal.swift
//  UrgentPath
//
//  Created by Jiashun Gou on 5/12/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

import Foundation

class DataRunwayGlobal {
    var data : [[Array<DataRunway>]]
    var data_size : Int
    
    init() {
        data = Array(repeating: Array(repeating: Array(), count: 360), count: 180)
        data_size = 0
    }
    
    func addRunway(runway_name:String,
                   loc_lat:Double,
                   loc_lon:Double,
                   loc_z:Double,
                   heading:Double,
                   length:Int,
                   width:Int,
                   surface:Double) {
        let tmpRunway = DataRunway(runway_name: runway_name,
                                   runway_loc_x: loc_lat,
                                   runway_loc_y: loc_lon,
                                   runway_loc_z: loc_z,
                                   runway_heading: heading,
                                   runway_length:length,
                                   runway_width:width,
                                   runway_surface_quality:surface)
        data[Int(loc_lat)+90][Int(loc_lon)+180].append(tmpRunway)
        data_size += 1
    }
    
    func size() -> Int {
        return data_size
    }
    
    //lat range: -90->90
    //lon range: -180->180
    //list all runways inside the 3*3 grid where plane is centered in the center block
    func listRunwaysAround(lat:Int, lon:Int) -> [DataRunway] {
        var ret = [DataRunway]()
        
        //handle edge case
        //when latitude more than 88 or less than -88
        //return all airports between latitude 86->90 or -89->-86
        if(lat < -88){
            for i in (-89)...(-86) {
                for j in (-180)...179 {
                    ret += listRunwaysOnGrid(lat: i, lon: j)
                }
            }
            return ret
        }
        else if(lat > 88){
            for i in 86...89 {
                for j in (-180)...179 {
                    ret += listRunwaysOnGrid(lat: i, lon: j)
                }
            }
            return ret
        }
        
        //add runways in same grid
        ret.append(contentsOf: listRunwaysOnGrid(lat: lat, lon: lon))
        //
        
        //add runways in grid above and below
        ret += listRunwaysOnGrid(lat: lat-1, lon: lon)
        ret += listRunwaysOnGrid(lat: lat+1, lon: lon)
        
        //add runways in left side grids of curret grid
        if(lon == -179){
            ret += listRunwaysOnGrid(lat: lat-1, lon: 179)
            ret += listRunwaysOnGrid(lat: lat, lon: 179)
            ret += listRunwaysOnGrid(lat: lat+1, lon: 179)
        }
        else {
            ret += listRunwaysOnGrid(lat: lat-1, lon: lon-1)
            ret += listRunwaysOnGrid(lat: lat, lon: lon-1)
            ret += listRunwaysOnGrid(lat: lat+1, lon: lon-1)
        }
        
        //add runways in right side grids of curret grid
        if(lon == 179){
            ret += listRunwaysOnGrid(lat: lat-1, lon: -179)
            ret += listRunwaysOnGrid(lat: lat, lon: -179)
            ret += listRunwaysOnGrid(lat: lat+1, lon: -179)
        }
        else{
            ret += listRunwaysOnGrid(lat: lat-1, lon: lon+1)
            ret += listRunwaysOnGrid(lat: lat, lon: lon+1)
            ret += listRunwaysOnGrid(lat: lat+1, lon: lon+1)
        }
        return ret
    }
    
    func listRunwaysAll() -> [DataRunway] {
        var ret = Array<DataRunway>()
        for i in 0...179 {
            for j in 0...359 {
                ret.append(contentsOf: data[i][j])
            }
        }
        return ret
    }
    
    //lat range: -90->90
    //lon range: -180->180
    func listRunwaysOnGrid(lat:Int, lon:Int) -> [DataRunway] {
        return data[lat+90][lon+180]
    }
    
}
