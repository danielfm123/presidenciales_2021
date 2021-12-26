#https://www.servel.cl/resultados-en-excel-por-mesa-a-partir-del-ano-2012/
 
# -*- coding: utf-8 -*-
from selenium import webdriver
import selenium.webdriver.support as support
import selenium.webdriver.common as common
import time
import pandas as pd
import numpy as np
import sys
import re

xpath_generico = '//select[@id="{}"]/option'
campos = ["selRegion","selCircunscripcionSenatorial","selDistrito","selComunas","selCircunscripcionElectorales","selLocalesVotacion","selMesasReceptoras"]
wait_secs = 1
inicio = int(sys.argv[1])
fin = int(sys.argv[2])

#inicio = 0
#fin = 5

mesas = pd.read_excel("dimenciones_2da.xlsx")
 
class DataScrapper:
   
    def __init__(self,driver):
        self.driver = driver
        self.ultimo = []
   
    def scrap(self,intento = 0):
        try:
            boric =   self.driver.find_element_by_xpath('//*[@id="basic-table"]/table/tbody[1]/tr[2]/td[3]/small/span').text
            kast = self.driver.find_element_by_xpath('//*[@id="basic-table"]/table/tbody[1]/tr[5]/td[3]/small/span').text
            nulos =    self.driver.find_element_by_xpath('//*[@id="basic-table"]/table/tfoot/tr[2]/th[2]/strong').text
            blanco =   self.driver.find_element_by_xpath('//*[@id="basic-table"]/table/tfoot/tr[3]/th[2]/strong').text
            valores = [boric,kast,nulos,blanco]
            if(valores == self.ultimo and intento < 10):
                print("valores duplicados")
                time.sleep(wait_secs)
                return(self.scrap(intento + 1))
            else: 
                self.ultimo = valores
                print(valores)
                return(valores)
        except:
            print("retry scrap")
            time.sleep(wait_secs)
            return(self.scrap())
            
    def set_dim(self,dim):
        try:
            for n in range(len(dim)):
                dim_levels = driver.find_elements_by_xpath(xpath_generico.format(campos[n]))
                selected_level = np.where([x.is_selected() for x in dim_levels])[0][0]
                if(re.sub(" \(Descuadrada\)","",dim_levels[selected_level].text) != dim[n]):
                    select_level = np.where([re.sub(" \(Descuadrada\)","",x.text) == re.sub(" \(Descuadrada\)","",dim[n]) for x in dim_levels])[0][0]
                    dim_levels[select_level].click()
                    time.sleep(wait_secs) 
        except:
            print("pegado en:")
            print(dim)
            self.set_dim(dim)
 



#driver = webdriver.Chrome()
options = webdriver.FirefoxOptions()
options.headless = True
driver = webdriver.Firefox(options=options)
time.sleep(1)
driver.get("http://www.servelelecciones.cl/")
driver.set_window_size(1300,768)
time.sleep(1)
driver.find_element_by_xpath("/html/body/div[2]/div[1]/div[2]/div/ul/li[3]/a").click()
time.sleep(1)
ds = DataScrapper(driver)

votaciones = []
for nmesa in range(inicio,fin):
    mesa = mesas.iloc[nmesa]
    print(mesa)
    ds.set_dim(mesa)
    votacion_mesa = ds.scrap()
    votaciones.append( mesa.tolist() + votacion_mesa)

driver.close()

tabla = pd.DataFrame(votaciones,columns = ["region","circ_sen","distrito","comuna","circ_elec","local_vot","mesa","boric","kast","nulos","blancos"])
filename = "votos_2da_{}-{}.xlsx".format(inicio,fin)
tabla.to_excel(filename)
print(filename)
