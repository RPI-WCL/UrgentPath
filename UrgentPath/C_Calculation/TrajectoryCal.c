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
    int i, limit,k;
    
//unpacking packet
    double q1[3];
	double q2[3];
	double min_radius=data.min_rad;
	double start_altitude=data.start_altitude;
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
	Seg path_with_spiral= generate_spiral(dubin_parts,min_radius,angle,data.baseline_g);

	path_with_spiral= find_extended_runway(path_with_spiral,q2[0],q2[1],q2[2],q1[0],q1[1],q1[2],start_altitude, angle, min_radius, data.interval, data.baseline_g, data.dirty_g); //finds extended runway
	//print_trajectory(path_with_spiral, angle, q2[0],q2[1],q2[2]); //saving to file
	
//	printf("No wind trajectory generated!\n");
	return path_with_spiral;
}

Seg2 model_wind(Seg path_with_spiral, Packet data)
{
        int i;
        
//unpacking packet
    double q1[3];
	double q2[3];
	double min_radius=data.min_rad;
	double start_altitude=data.start_altitude;
	int angle=data.angle;
	double WIND_VELOCITY = data.windspeed;	
	double WIND_HEADING =  data.wind_heading;
	double baseline_g=data.baseline_g;

    for(i=0;i<3;i++)
	{
		q1[i]=data.p1[i];
		q2[i]=data.p2[i];
	}
	
	Seg2 wind_path;	
	wind_path.spiral=false;
	wind_path.extended=false;
	wind_path.end_alt=0.0;

    Curve augmented_curve_A= wind_curveA(path_with_spiral,WIND_HEADING, WIND_VELOCITY, OMEGA_30_DEGREE_BANK, min_radius,start_altitude, q1[0], q1[1], angle, baseline_g, data.airspeed); //send first curve to be modified by wind
	wind_path.aug_C1=augmented_curve_A;

	Curve augmented_SLS= wind_SLS(path_with_spiral,WIND_HEADING, WIND_VELOCITY,augmented_curve_A,baseline_g, data.airspeed, data.dirty_g); //send middle straight line segment to be modified
	wind_path.aug_SLS=augmented_SLS;	
	Curve augmented_curve_B= wind_curveB(path_with_spiral,WIND_HEADING, WIND_VELOCITY,OMEGA_30_DEGREE_BANK, min_radius, augmented_SLS, angle,baseline_g, data.airspeed,q2[2]); //send second curve to be modified
	wind_path.aug_C2=augmented_curve_B;
	Curve augmented_spiral;
	augmented_spiral.spiral=false;
	Curve augmented_extended;
	augmented_extended.extended=false;

	if(path_with_spiral.lenspiral>0) //augmenting spiral
	{
		augmented_spiral= wind_spiral(path_with_spiral,WIND_HEADING, WIND_VELOCITY,OMEGA_30_DEGREE_BANK, min_radius, augmented_curve_B, angle,baseline_g, data.airspeed,q2[2]);
		wind_path.aug_SPIRAL=augmented_spiral;
		wind_path.spiral=true;
	}
	if(path_with_spiral.extended) //augmenting extended runway
	{
		augmented_extended= wind_extended(path_with_spiral,WIND_HEADING, WIND_VELOCITY, augmented_spiral, augmented_curve_B, q2[0],q2[1],q2[2],baseline_g, data.airspeed, data.dirty_g);
		wind_path.aug_EXTENDED=augmented_extended;
		wind_path.extended=true;

	}
	//save_wind_in_file(augmented_curve_A,  augmented_SLS, augmented_curve_B, augmented_spiral, augmented_extended, data.file_name, data.alphabet);//saves augmented path in file
    get_first_instruction(augmented_curve_A,  augmented_SLS, augmented_curve_B, augmented_spiral, augmented_extended, data.alphabet, wind_path.instructions);//get first instruction
    
	//calculate total shift in path
	if (wind_path.extended)
	{
		wind_path.total_shift= horizontal(data.runway[0], data.runway[1], wind_path.aug_EXTENDED.points[wind_path.aug_EXTENDED.len_curve-1][0], wind_path.aug_EXTENDED.points[wind_path.aug_EXTENDED.len_curve-1][1]);	
		wind_path.end_alt=wind_path.aug_EXTENDED.points[wind_path.aug_EXTENDED.len_curve-1][4];
	}
	else
	{
		if(wind_path.spiral)
		{
			wind_path.total_shift= horizontal(data.runway[0], data.runway[1], wind_path.aug_SPIRAL.points[wind_path.aug_SPIRAL.len_curve-1][0], wind_path.aug_SPIRAL.points[wind_path.aug_SPIRAL.len_curve-1][1]);
			wind_path.end_alt=wind_path.aug_SPIRAL.points[wind_path.aug_SPIRAL.len_curve-1][4];		
		}
		else
		{
			wind_path.total_shift= horizontal(data.runway[0], data.runway[1], wind_path.aug_C2.points[wind_path.aug_C2.len_curve-1][0], wind_path.aug_C2.points[wind_path.aug_C2.len_curve-1][1]);
			wind_path.end_alt=wind_path.aug_C2.points[wind_path.aug_C2.len_curve-1][4];		
	
		}
	}
//	printf("Wind modelled! \n");
	return wind_path;        
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
                    double wind_heading
                    ){
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

	Seg basic_trajectory=basic_path(dat_30); //get first_dubins

	Seg2 wind_1=model_wind(basic_trajectory,dat_30);
    
	double shift= wind_1.total_shift;
	double init_shift=shift; //used to stop loop if somehow exceeds instead of decreasing
	double wind_alt=wind_1.end_alt ;//altitude of last point of wind augmented

    printf("[%s]\n",wind_1.instructions);
    static char ret[1000];
    strcpy(ret,wind_1.instructions);
    return ret;
    
	if(false) //put false for not running catch runway code
	{
		//catch runway code starts here
		int iter=1;
		float distance=0.0; //adjuste this depending on shift. BASIS OF OUR HUERISTICS
		while(shift>0.000137)
		{
			distance=distance+shift;
			double reverse_wind_heading= wind_heading + PI; 

			Pair new_point=along_heading_at_distance(runway_x, runway_y, reverse_wind_heading, (distance));

			iter=iter+1;
			Packet dat_temp; //condition specific variables will be initialized now
			dat_temp=dat;

			dat_temp.p2[1]=new_point.y;
			dat_temp.p2[0]=new_point.x;
			dat_temp.p2[2]=runway_heading;
	
			dat_temp.angle=30;
			dat_temp.min_rad=(best_gliding_speed*best_gliding_speed)/(11.29* tan(dat_temp.angle*PI/180))/364173.0; //v^2/(G x tan(bank_angle))

			Seg basic_temp=basic_path(dat_temp); //get first_dubins

			Seg2 wind_temp=model_wind(basic_temp,dat_temp);
	

			shift= wind_temp.total_shift;
			wind_alt=wind_temp.end_alt;
		} 

	}
}
