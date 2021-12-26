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
campos = ["selRegion","selCircunscripcionSenatorial","selDistrito","selComunas","selCircunscripcionElectorales","selLocalesVotacion"]
wait_secs = 1

#inicio = int(sys.argv[1])
#fin = int(sys.argv[2])

mesas = pd.read_excel("dimenciones_1ra.xlsx")
mesas = mesas.groupby(by = ['region', 'circ_sen', 'distrito', 'comuna', 'circ_elec','local_vot']).head(1)
mesas = mesas.drop(["mesa"],1)

inicio = 0
fin = len(mesas)

class DataScrapper:
   
    def __init__(self,driver):
        self.driver = driver
        self.ultimo = []
        self.dim = None
   
    def scrap(self,intento = 0):
        try:
            votos = self.driver.find_element_by_xpath('//*[@id="basic-table"]')
            votos = pd.read_html(votos.get_attribute('innerHTML'))[0]
            votos = votos[votos.Mesa != "TOTAL"].dropna().drop(["% Participación"],1)
            try: 
                comparation = all(votos == self.ultimo)
            except:
                comparation = False
            if(False and intento < 10):
                print("valores duplicados")
                time.sleep(wait_secs)
                return(self.scrap(intento + 1))
            else: 
                self.ultimo = votos.copy()
                for c in campos:
                    dim_levels = driver.find_elements_by_xpath(xpath_generico.format(c))
                    selected_level = np.where([x.is_selected() for x in dim_levels])[0][0]
                    votos[c] = dim_levels[selected_level].text
                print(votos)
                return(votos)
        except:
            print("retry scrap")
            time.sleep(wait_secs)
            return(self.scrap(intento + 1))
            
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
driver.get("https://resultados.servelelecciones.cl/presidencialespv2021/provisorios/")
driver.set_window_size(1300,768)
time.sleep(1)
driver.find_element_by_xpath('//*[@id="menu"]/ul/li[5]/a').click()
driver.find_element_by_xpath("/html/body/div[2]/div[1]/div[2]/div/ul/li[3]/a").click()
time.sleep(1)
ds = DataScrapper(driver)
#self = ds


votaciones = pd.DataFrame()
for nmesa in range(inicio,fin):
    mesa = mesas.iloc[nmesa]
    print(mesa)
    ds.set_dim(mesa)
    votacion_mesa = ds.scrap()
    votaciones = votaciones.append( votacion_mesa)

driver.close()

filename = "participacion_1ra_{}-{}.xlsx".format(inicio,fin)
votaciones.to_excel(filename)
print(filename)
