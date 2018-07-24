//
//  TrajectoryCal.h
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//
#pragma once
#include "demo.h"
#include "helper.h"
#include <stdio.h>
#include <dirent.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <pthread.h>
#include <ctype.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>

#define TRUE  (1==1)
#define FALSE (!TRUE)

extern struct TrajectoryData {
    double time_curveFirst;
    double time_straight;
    double time_curveSecond;
    double time_spiral;
    double time_extend;
    int error_code;
    double degree_curveFirst;
    double degree_curveSecond;
    double degree_spiral;
};

//degrees to radians
double degToRad(double deg);

//north 0 to east 0
//clokwise to counterclockwise
double CompassRadToMathRad(double rad);

Seg basic_path(Packet data);
Seg2 model_wind(Seg path_with_spiral, Packet data);

extern void TrajectoryCal(  struct TrajectoryData* ptr,
                             double user_x,
                             double user_y,
                             double user_z,
                             double user_heading,
                             double runway_x,
                             double runway_y,
                             double runway_z,
                             double runway_heading,
                             double interval,
                             double best_gliding_speed,
                             double best_gliding_ratio,
                             double dirty_gliding_ratio,
                             double wind_speed,
                             double wind_heading,
                             int catch_runway);
