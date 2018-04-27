//
//  TrajectoryCal.c
//  UrgentPath
//
//  Created by Jiashun Gou on 4/3/18.
//  Copyright © 2018 Jiashun Gou. All rights reserved.
//

#include "TrajectoryCal.h"

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

char* TrajectoryCal(double user_x,
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
                    int catch_runway){
    int filename=0;
    char alphabet='h';
    Packet dat; //creating a packet with constants
    
    dat.p1[0] = user_x;
    dat.p1[1] = user_y;
    dat.p1[2] = user_heading;
    
    dat.runway[0] = runway_x;
    dat.runway[1] = runway_y;
    dat.runway[2] = runway_heading;
    
    dat.interval= interval;
    dat.start_altitude=user_z; //initial altitude
    dat.runway_altitude=runway_z;
    dat.windspeed=(wind_speed*1.68781/364173.0);
    dat.wind_heading=wind_heading;
    dat.airspeed= (best_gliding_speed*1.68781/364173.0);
    dat.baseline_g=best_gliding_ratio;
    dat.dirty_g=dirty_gliding_ratio;
    dat.file_name=filename;
    dat.alphabet=alphabet;
    
    
    Packet dat_30; //condition specific variables will be initialized in this packet
    dat_30 = dat;
    dat_30.p2[0] = runway_x;
    dat_30.p2[1] = runway_y;
    dat_30.p2[2] = runway_heading;
    
    dat_30.angle=30;
    dat_30.min_rad=(best_gliding_speed*best_gliding_speed)/(11.29* tan(dat_30.angle*PI/180))/364173.0; //v^2/(G x tan(bank_angle))
    
    Seg basic_trajectory;
    memset(&basic_trajectory, 0, sizeof(Seg));
    basic_trajectory = basic_path(dat_30); //get first_dubins
    
    static char ret[1000*5];
    
    for(int i = 0; i < basic_trajectory.lenc1; ++i){
        if(basic_trajectory.C1[i][4] < 0){
            strcpy(ret,"No route can be found");
            return ret;
        }
    }
    
    for(int i = 0; i < basic_trajectory.lenc2; ++i){
        if(basic_trajectory.C2[i][4] < 0){
            strcpy(ret,"No route can be found");
            return ret;
        }
    }
    
    for(int i = 0; i < basic_trajectory.lensls; ++i){
        if(basic_trajectory.SLS[i][4] < 0){
            strcpy(ret,"No route can be found");
            return ret;
        }
    }
    
    for(int i = 0; i < basic_trajectory.lenspiral; ++i){
        if(basic_trajectory.Spiral[i][4] < 0){
            strcpy(ret,"No route can be found");
            return ret;
        }
    }
    
    char inst1[1000];
    char inst2[1000];
    char inst3[1000];
    char inst4[1000];
    char inst5[1000];
    
    double total_time=c1_time(basic_trajectory,dat_30.airspeed,dat_30.min_rad);
    sprintf(inst1,"30 degree bank for %d seconds",(int)(total_time+0.5));
    
    double alpha= fabs(basic_trajectory.SLS[2][2]-dat_30.wind_heading);
    double original_distance= horizontal(basic_trajectory.SLS[0][0], basic_trajectory.SLS[0][1], basic_trajectory.SLS[basic_trajectory.lensls-1][0], basic_trajectory.SLS[basic_trajectory.lensls-1][1]);
    double time_shift2=fabs(original_distance/ (dat_30.airspeed + ((dat_30.windspeed) * cos(alpha))));
    sprintf(inst2,"Straight line glide for %d seconds",(int)(time_shift2+0.5));
    
    double total_time3=c2_time(basic_trajectory,dat_30.airspeed,dat_30.min_rad);
    sprintf(inst3,"30 degree bank for %d seconds",(int)(total_time3+0.5));
    
    if(basic_trajectory.lenspiral>0) { //augmenting spiral
        double total_time4 = basic_trajectory.lenspiral*(((2*PI*dat_30.min_rad)/dat_30.airspeed)/50);
        sprintf(inst4,"30 degree bank spiral for %d seconds",(int)(total_time4+0.5));
    }
    
    if(basic_trajectory.extended) { //augmenting extended runway
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
        double time_shift5=fabs(original_distance/ (dat_30.airspeed + ((dat_30.windspeed) * cos(alpha))));
        sprintf(inst5,"Dirty configuration straight glide for %d seconds",(int)(time_shift5+0.5));
    }
    
    strcpy(ret,inst1);
    strcat(ret,"\n");
    strcat(ret,inst2);
    strcat(ret,"\n");
    strcat(ret,inst3);
    strcat(ret,"\n");
    strcat(ret,inst4);
    strcat(ret,"\n");
    strcat(ret,inst5);
    return ret;
}
