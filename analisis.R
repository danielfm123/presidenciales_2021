library(tidyverse)
library(openxlsx)
library(ggthemes)

dataset_raw =  read.csv("com_clust_tot.csv") 

dataset_raw %>% group_by(origen) %>% summarise_if(is.numeric,sum) %>% write.xlsx("totales.xlsx")

dataset_raw %>% select(-com_clust) %>% group_by(origen) %>% summarise_if(is.numeric,sum) %>% ungroup() %>% mutate_if(is.numeric,~./sum(.))

dataset = dataset_raw %>% 
  gather("destino","porcentaje",-origen,-com_clust) %>% 
  rename(votos = porcentaje) %>% 
  group_by(origen,destino) %>% 
  summarise(votos = sum(votos),.groups = "drop") %>% 
  ungroup() %>% 
  mutate(porcentaje = votos/sum(votos)) %>% 
  group_by(origen) %>% 
  mutate(porcentaje_origen = votos/sum(votos)) %>% 
  group_by(destino) %>% 
  mutate(porcentaje_destino = votos/sum(votos)) %>% 
  ungroup() %>% 
  mutate(origen = str_remove_all(origen,"_pv$"),
         destino = str_remove_all(destino,"^delta_|^detla_"))

dataset


ggplot(dataset,aes(destino,votos,fill = origen)) + geom_bar(stat = "identity")

ggplot(dataset,aes(destino,porcentaje,fill = origen)) + geom_bar(stat = "identity")

ggplot(dataset,aes(porcentaje_origen,origen,fill = destino)) + 
  geom_bar(stat = "identity") +
  theme_light() +
  ggthemes::scale_fill_tableau() +
  ggtitle("Traspaso de votos desde primera vuelta a segunda")

ggsave("pesos.png",width = 8,height = 6)
