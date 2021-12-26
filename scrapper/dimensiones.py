#https://www.servel.cl/resultados-en-excel-por-mesa-a-partir-del-ano-2012/
 
# -*- coding: utf-8 -*-
from selenium import webdriver
import selenium.webdriver.support as support
import selenium.webdriver.common as common
import time
import pandas as pd

xpath_generico = '//select[@id="{}"]/option'
campos = ["selRegion","selCircunscripcionSenatorial","selDistrito","selComunas","selCircunscripcionElectorales","selLocalesVotacion","selMesasReceptoras"]
#url_votacion = "http://pv.servelelecciones.cl/"
url_votacion = "http://www.servelelecciones.cl/"

print(url_votacion)

def get_levels(n = 0,ids=dict()):
    levels = driver.find_elements_by_xpath(xpath_generico.format(campos[n]))[1:]
    l = 0
    if(n < 6):
        while l < len(levels):
            level = levels[l]
            level.click()
            time.sleep(1)
            ids[campos[n]] = level.text
            get_levels(n+1, ids)
            l = l + 1
    else:
        for level in levels:
            this_level = [ids[x] for x in campos[:6]] + [level.text]
            dimensions.append(this_level)        
            print(this_level)
     
options = webdriver.FirefoxOptions()
options.headless = True
driver = webdriver.Firefox(options=options)
time.sleep(1)
driver.get(url_votacion)
driver.set_window_size(1300,768)
time.sleep(1)
driver.find_element_by_xpath("/html/body/div[2]/div[1]/div[2]/div/ul/li[3]/a").click()
time.sleep(1)
dimensions = []
get_levels()

tabla = pd.DataFrame(dimensions,columns = ["region","circ_sen","distrito","comuna","circ_elec","local_vot","mesa"])
tabla.to_excel("dimenciones_2da.xlsx")

driver.close()
