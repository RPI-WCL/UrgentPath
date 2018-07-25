import os
import sys
import time
from PIL import Image
import concurrent.futures
from itertools import repeat

MAX_WORKER_NUMBER = 6

workplace_path = os.getcwd() + "/download_content/"

def JPG2PNG(filename):
    image = Image.open(filename+".jpg")
    image.save(filename+".png")
    
def PNG_black2transparent(filename):
    image = Image.open(filename+".png").convert("RGBA")
    pixdata = image.load()

    width, height = image.size
    for y in range(height):
        for x in range(width):
            r,g,b,a = pixdata[x, y]
            if(     r >= 83
                and r <= 87
                and g >= 83
                and g <= 87
                and b >= 83
                and b <= 87):
                pixdata[x, y] = (255, 255, 255, 0)
            if(     r >= 110
                and r <= 114
                and g >= 110
                and g <= 114
                and b >= 110
                and b <= 114):
                pixdata[x, y] = (255, 255, 255, 0)
    image.save(filename+".png", "PNG")

def removeJPG(filename):
    os.remove(filename+".jpg")

def process(zoom,lon,lat):
    filepath = workplace_path+zoom+"/"+lon+"/"+lat
    filename = filepath.rsplit('.',1)[0]
    #print(filename)
    JPG2PNG(filename)
    PNG_black2transparent(filename)
    removeJPG(filename)

def progressBar(value, endvalue, bar_length=20):
    percent = float(value) / endvalue
    arrow = '-' * int(round(percent * bar_length)-1) + '>'
    spaces = ' ' * (bar_length - len(arrow))
    sys.stdout.write("\rPercent: [{0}] {1}%".format(arrow + spaces, int(round(percent * 100))))
    sys.stdout.flush()
    
if __name__ == "__main__":
    zoom_list = os.listdir(workplace_path)
    for zoom in zoom_list:
        print("\n!!!zoom:"+zoom)
        counter = 0
        lon_list = os.listdir(workplace_path+zoom+"/")
        for lon in lon_list:
            #print("lon:"+lon)
            counter+=1
            progressBar(counter,len(lon_list),50)
            #start = time.time()
            with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKER_NUMBER) as executor:
                lat_list = os.listdir(workplace_path+zoom+"/"+lon+"/")
                for _ in executor.map(process,repeat(zoom),repeat(lon),lat_list):
                    pass
            #print("Elasped:"+str(time.time()-start))