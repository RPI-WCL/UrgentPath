import requests
import os
import sys
import concurrent.futures
from itertools import repeat
import time

MAX_WORKER_NUMBER = 1
INIT_LAT_POS = 0

mapType = ["vfrc","sectc","wacc","ifrlc","ehc"]
chosen_mapType = mapType[0]

workplace_path = os.getcwd() + "/download_content/"
blank = requests.get("http://vfrmap.com/20180524/tiles/"+chosen_mapType+"/10/0/0.jpg")

def download_image(zoom_int,lat_int,lon_int):
    zoom = str(zoom_int)
    lat = str(lat_int)
    lon = str(lon_int)
    #print("!!!["+zoom+","+lat+","+lon+"]")
    url = "http://vfrmap.com/20180524/tiles/vfrc/"+zoom+"/"+lat+"/"+lon+".jpg"
    
    file_path = zoom+"/"+lat+"/"+lon+".jpg"
    if not os.path.exists(os.path.dirname(workplace_path+file_path)):
        os.makedirs(os.path.dirname(workplace_path+file_path))
    if not os.path.isfile(workplace_path+file_path):
        tmp_img = requests.get(url)
        if(tmp_img.content == blank.content):
            return
        with open(workplace_path+file_path, "wb") as f:
            f.write(tmp_img.content)

#zoom range is [zoom_min,zoom_max]
def scraper(zoom_min,zoom_max):
    for zoom in range(zoom_min,zoom_max+1):
        print("\n!!!Working on zoom ["+str(zoom)+"]")
        limit = 2**zoom
        for lat in range(INIT_LAT_POS,limit):
            print("lat:"+str(lat)+"/"+str(limit))
            start = time.time()
            directory_path = str(zoom)+"/"+str(lat)+"/"
            if not os.path.exists(os.path.dirname(workplace_path+directory_path)):
                os.makedirs(os.path.dirname(workplace_path+directory_path))
            with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKER_NUMBER) as executor:
                lon = range(0,limit)
                for _ in executor.map(download_image,repeat(zoom),repeat(lat),lon):
                    pass
            #print("Elasped:"+str(time.time()-start))
            #delete file if no image inside
            if not os.listdir(workplace_path+"/"+str(zoom)+"/"+str(lat)+"/"):
                os.rmdir(workplace_path+"/"+str(zoom)+"/"+str(lat))

def progressBar(value, endvalue, bar_length=20):
    percent = float(value) / endvalue
    arrow = '-' * int(round(percent * bar_length)-1) + '>'
    spaces = ' ' * (bar_length - len(arrow))
    sys.stdout.write("\rPercent: [{0}] {1}%".format(arrow + spaces, int(round(percent * 100))))
    sys.stdout.flush()

#1st argument: min zoom will start from
#2nd argument: max zoom will reach
#3rd argument: max number of thread will create (optional,default is 18)
#4th argument: initial position of latitude (optional,default is 0)
if __name__ == "__main__":
    if(len(sys.argv) < 3):
        print("needs at least 2 arguments")
        sys.exit(-1)
    else:
        min = int(sys.argv[1])
        max = int(sys.argv[2])

    if(min < 1 or max > 10):
        print("min needs to no smaller than 1, max needs to be no larger than 10")
        sys.exit(-1)
    print("Working directory:"+workplace_path)
    print("Working zoom:["+sys.argv[1]+","+sys.argv[2]+"]")
    
    if(len(sys.argv) >= 4):
        MAX_WORKER_NUMBER = int(sys.argv[3])
        print("Number of workers:["+sys.argv[3]+"]")
    
    if(len(sys.argv) >= 5):
        INIT_LAT_POS = int(sys.argv[4])
        print("Initial latitude position ["+sys.argv[4]+"]")

    scraper(min,max)
