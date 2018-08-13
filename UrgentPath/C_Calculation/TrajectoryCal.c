//
//  TrajectoryCal.c
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

#include "TrajectoryCal.h"

//degrees to radians
double degToRad(double deg){
    while(deg > 360){
        deg -= 360;
    }
    return deg * PI / 180;
}

//north 0 to east 0
//clokwise to counterclockwise
double CompassRadToMathRad(double rad){
    double newRad = -1*rad + PI/2;
    if(newRad < 0){
        newRad += 2*PI;
    }
    return newRad;
}

//main EnTRY function
Seg basic_path(Packet data)
{
    Packet pack; //for storing complete path
    
    int i, limit,j,k;
    
    //unpacking packet
    double q1[3];
    double q2[3];
    double min_radius=data.min_rad;
    double start_altitude=data.start_altitude;
    double runway_altitude=data.runway_altitude;
    int angle=data.angle;
    double WIND_VELOCITY=data.windspeed;
    double baseline_g=data.baseline_g;
    
    for(i=0;i<3;i++)
    {
        q1[i]=data.p1[i];
        q2[i]=data.p2[i];
    }
    
    Result dubins=demo(q1,q2,min_radius, data.interval); //sending configs to demo to generate DP
    //dubins.arr =[long, lat, heading, ?unknown]
    
    Seg dubin_parts=split(dubins); //sending DP to split into segmentss
    
    dubin_parts=assign_altitude(dubin_parts, start_altitude, q1[0], q1[1], angle, data.baseline_g);//Send dubin_parts to assign_altitude() to get alti for each point
    
    //generates possible spiral segment with altitude
    Seg path_with_spiral= generate_spiral(dubin_parts,min_radius,angle,data.baseline_g,runway_altitude);
    
    path_with_spiral= find_extended_runway(path_with_spiral,q2[0],q2[1],q2[2],q1[0],q1[1],q1[2],start_altitude, runway_altitude, angle, min_radius, data.interval, data.baseline_g, data.dirty_g); //finds extended runway
    //    print_trajectory(path_with_spiral, angle, q2[0],q2[1],q2[2]); //saving to file
    
    return path_with_spiral;
}

void TrajectoryCal(struct TrajectoryData* ptr,
                   double user_lat,
                    double user_lon,
                    double user_z, // in feet
                    double user_heading,// in degree
                    double runway_lat,
                    double runway_lon,
                    double runway_z, // in feet
                    double runway_heading,// in degree
                    double interval,
                    double best_gliding_speed, // in knots
                    double best_gliding_ratio,
                    double dirty_gliding_ratio,
                    double wind_speed, // in knots
                    double wind_heading, // in degree
                    int catch_runway){
    memset(ptr, 0, sizeof(struct TrajectoryData));
    
    int filename=0;
    char alphabet='h';
    Packet dat; //creating a packet with constants
    
    dat.p1[0] = user_lon;
    dat.p1[1] = user_lat;
    dat.p1[2] = CompassRadToMathRad(degToRad(user_heading));
    
    dat.runway[0] = runway_lon;
    dat.runway[1] = runway_lat;
    dat.runway[2] = CompassRadToMathRad(degToRad(runway_heading));
    
    dat.interval= interval;
    dat.start_altitude=user_z/364173.0;
    dat.runway_altitude=runway_z/364173.0;
    dat.windspeed=(wind_speed*1.68781/364173.0);
    dat.wind_heading=CompassRadToMathRad(degToRad(wind_heading));
    dat.airspeed= (best_gliding_speed*1.68781/364173.0);
    dat.baseline_g=best_gliding_ratio;
    dat.dirty_g=dirty_gliding_ratio;
    dat.file_name=filename;
    dat.alphabet=alphabet;
    
    
    Packet dat_30; //condition specific variables will be initialized in this packet
    dat_30 = dat;
    dat_30.p2[0] = runway_lon;
    dat_30.p2[1] = runway_lat;
    dat_30.p2[2] = CompassRadToMathRad(degToRad(runway_heading));
    
    dat_30.angle=30;
    dat_30.min_rad=(best_gliding_speed*best_gliding_speed)/(11.29* tan(dat_30.angle*PI/180))/364173.0; //v^2/(G x tan(bank_angle))
    
    Seg basic_trajectory;
    memset(&basic_trajectory, 0, sizeof(Seg));
    basic_trajectory.extended = false;//initalize extended
    basic_trajectory = basic_path(dat_30); //get first_dubins
    
    //incase too far from runway and plane will and halfway to airport
    //detect anytime height is less than 0
    for(int i = 0; i < basic_trajectory.lenc1; ++i){
        if(basic_trajectory.C1[i][4] < 0){
            ptr->error_code = 1;
            return;
        }
    }
    
    for(int i = 0; i < basic_trajectory.lenc2; ++i){
        if(basic_trajectory.C2[i][4] < 0){
            ptr->error_code = 3;
            return;
        }
    }
    
    for(int i = 0; i < basic_trajectory.lensls; ++i){
        if(basic_trajectory.SLS[i][4] < 0){
            ptr->error_code = 2;
            return;
        }
    }
    
    for(int i = 0; i < basic_trajectory.lenspiral; ++i){
        if(basic_trajectory.Spiral[i][4] < 0){
            ptr->error_code = 4;
            return;
        }
    }
    
    //first curve
    double total_time1=c1_time(basic_trajectory,dat_30.airspeed,dat_30.min_rad);
    ptr->time_curveFirst = (total_time1);
    ptr->degree_curveFirst = azmth(basic_trajectory.SLS[basic_trajectory.lensls-1][2]);
    ptr->firstCurveStart_lat = basic_trajectory.C1[0][0];
    ptr->firstCurveStart_lon = basic_trajectory.C1[0][1];
    
    //straight line
    double alpha= fabs(basic_trajectory.SLS[2][2]-dat_30.wind_heading);
    double original_distance= horizontal(basic_trajectory.SLS[0][0], basic_trajectory.SLS[0][1], basic_trajectory.SLS[basic_trajectory.lensls-1][0], basic_trajectory.SLS[basic_trajectory.lensls-1][1]);
    double time_shift2=fabs(original_distance/ (dat_30.airspeed + ((dat_30.windspeed) * cos(alpha))));
    ptr->time_straight = (time_shift2);
    ptr->straightStart_lat = basic_trajectory.SLS[0][0];
    ptr->straightStart_lon = basic_trajectory.SLS[0][1];
    
    //second curve
    double total_time3=c2_time(basic_trajectory,dat_30.airspeed,dat_30.min_rad);
    ptr->time_curveSecond = (total_time3);
    ptr->degree_curveSecond = azmth(dat_30.p2[2]);
    ptr->secondCurveStart_lat = basic_trajectory.C2[0][0];
    ptr->secondCurveStart_lon = basic_trajectory.C2[0][1];
    
    //spiral for runway
    double total_time4 = 0;
    if(basic_trajectory.lenspiral>0) { //augmenting spiral
        total_time4 = basic_trajectory.lenspiral*(((2*PI*dat_30.min_rad)/dat_30.airspeed)/50);
        ptr->time_spiral = (total_time4);
        ptr->degree_spiral = azmth(dat_30.p2[2]);
        ptr->spiralStart_lat = basic_trajectory.Spiral[0][0];
        ptr->spiralStart_lon = basic_trajectory.Spiral[0][1];
    }
    
    //runway
    double time_shift5 = 0;
    //something strange here, when 'extended' is true -> if(extended) will not be executed;hence a '!' is added temporarily
    if(!basic_trajectory.extended) { //augmenting extended runway
        double original_start_x,original_start_y;
        if(basic_trajectory.lenspiral>0){
            original_start_x= basic_trajectory.Spiral[basic_trajectory.lenspiral-1][0];
            original_start_y= basic_trajectory.Spiral[basic_trajectory.lenspiral-1][1];
        }
        else{
            original_start_x= basic_trajectory.C2[basic_trajectory.lenc2-1][0];
            original_start_y= basic_trajectory.C2[basic_trajectory.lenc2-1][1];
        }
        double alpha= fabs(basic_trajectory.SLS[2][2]-dat_30.wind_heading);
        double original_distance= horizontal(dat_30.p2[0], dat_30.p2[1], original_start_x, original_start_y);
        time_shift5=fabs(original_distance/ (dat_30.airspeed + ((dat_30.windspeed) * cos(alpha))));
        ptr->time_extend = (time_shift5);
        ptr->extendedStart_lat = basic_trajectory.Spiral[basic_trajectory.lenspiral-1][0];
        ptr->extendedStart_lon = basic_trajectory.Spiral[basic_trajectory.lenspiral-1][1];
    }
    
    //in case calculation failure, output to user and log
    if(total_time1 < 0 || time_shift2 < 0 || total_time3 < 0 || total_time4 < 0 || time_shift5 < 0){
        printf("Calculation failure\n");
        ptr->error_code = -1;
        return;
    }
    
    //incase total_time1 is NaN or just doesn't exist
    //just return 0
    if(total_time1 != total_time1 || basic_trajectory.lenc1 < 0){
        ptr->time_curveFirst = 0;
    }
    if(time_shift2 != time_shift2 || basic_trajectory.lensls < 0){
        ptr->time_straight = 0;
    }
    if(total_time3 != total_time3 || basic_trajectory.lenc2 < 0){
        ptr->time_curveSecond = 0;
    }
    if(total_time4 != total_time4 && basic_trajectory.lenspiral < 0){
        ptr->time_spiral = 0;
    }
    if(time_shift5 != time_shift5){
        ptr->time_extend = 0;
    }
    return;
}
