library(tidyverse)
library(readxl)
library(openxlsx)

dat = read_excel("votos1.xlsx") %>% 
  mutate(mesa=str_remove_all(mesa," \\(Descuadrada\\)"))

mas_unida = str_split(dat$mesa,"-") %>% map_dbl(length) %>% max
dat = dat %>% 
  separate(mesa,sep="-",paste0("m",1:mas_unida),remove = F) %>% 
  gather(numero_mesa,mesa_separada,-region,-circ_sen,-distrito,-comuna,-circ_elec ,-local_vot,-mesa,-boric,-kast,-provoste,-sanchez,-meo,-parisi,-artes,-nulos,-blanco) %>% 
  filter(!is.na(mesa_separada)) %>% 
  select(-numero_mesa) %>% 
  group_by(region,circ_sen,distrito,comuna,circ_elec ,local_vot,mesa) %>% 
  mutate_if(is.numeric,~./n()) %>% 
  mutate(numero = n()) 

write.xlsx(dat,"mesas_sep.xlsx")
