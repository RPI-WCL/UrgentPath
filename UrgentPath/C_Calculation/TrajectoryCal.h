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


//extern int helloworld2(void);


Seg basic_path(Packet data);
Seg2 model_wind(Seg path_with_spiral, Packet data);

extern char* TrajectoryCal(void);
