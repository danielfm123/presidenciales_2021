library(openxlsx)
library(plyr)
library(reshape2)
library(ggplot2)
# library(CVXR)
# library(clue)

#Cargar datos
primera.raw = read.xlsx("votos1.xlsx")
segunda.raw = read.xlsx("votos2.xlsx")
primera.votos.raw = read.xlsx("participacion_1ra.xlsx")
segunda.votos.raw = read.xlsx("participacion_2da.xlsx")

#data_cleaning participacion
primera.votos = primera.votos.raw
primera.votos$votos_mesa = NULL

#data cleaning primera
primera = primera.raw
primera[is.na(primera)] = 0
# primera$total = rowSums(primera[,c("goic", "kast", "pinera", "guillier", "sanchez","meo","artes","navarro","nulos","blanco")])
colnames(primera)[-1:-7] = paste0(colnames(primera)[-1:-7],"_pv")
primera = transform(primera,mesa = gsub(" \\(Descuadrada\\)","",mesa))
primera = merge(primera, primera.votos)
primera = transform(primera, noVoto_pv = total_mesa - boric_pv-kast_pv-provoste_pv-artes_pv-meo_pv-parisi_pv-sichel_pv-nulos_pv-blanco_pv)
primera$total_mesa = NULL
head(primera)

votos_pv = ddply(melt(primera[, -1:-7], variable.name = "candidato", value.name = "votos"), "candidato",summarise, votos = sum(votos))
ggplot( subset(votos_pv, !candidato %in% c("total_pv","total_mesa") ) ) + 
  geom_bar(aes(candidato, votos), stat = "identity") + 
  theme(axis.text.x = element_text(angle = 60,hjust = 1))
ggsave("totales_pv.png",width = 8,height = 6)

#data cleaning Segunda vuelta
segunda = segunda.raw
segunda[is.na(segunda)] = 0
colnames(segunda)[-1:-7] = paste0(colnames(segunda)[-1:-7],"_sv")
segunda = transform(segunda,mesa = gsub(" \\(Descuadrada\\)","",mesa))
segunda = merge(segunda, primera.votos)
segunda = transform(segunda, noVoto_sv = total_mesa - boric_sv - kast_sv - nulos_sv - blancos_sv)
segunda$total_mesa = NULL
head(segunda)

votos_sv = ddply(melt(segunda[, -1:-7], variable.name = "candidato", value.name = "votos"), "candidato",summarise, votos = sum(votos))
ggplot( subset(votos_sv, candidato != "total_mesa") ) + 
  geom_bar(aes(candidato, votos), stat = "identity") + 
  theme(axis.text.x = element_text(angle = 60,hjust = 1))
ggsave("totales_sv.png",width = 8,height = 6)

# Creando dataset
dataset = merge(primera,segunda,by=colnames(primera)[1:7])
write.xlsx(dataset,"dataset.xlsx",overwrite = T)
any(is.na(dataset))
head(dataset)


# Modelo planteado como un problem de minimización cuadratico
# get_model = function(dataset){
#   votos_ant = as.matrix(dataset[, c(
#     "noVoto_pv",
#     "boric_pv",
#     "kast_pv",
#     "provoste_pv",
#     "artes_pv",
#     "meo_pv",
#     "parisi_pv",
#     "sichel_pv",
#     "nulos_pv",
#     "blanco_pv"
#   )])
#   
#   
#   
#   # Opt1 --------------------------------------------------------------------
#   
#   
#   #Crear variables de desición, que porcenaje se cede a cada dimencion
#   delta_boric <- Variable(ncol(votos_ant))
#   delta_kast <- Variable(ncol(votos_ant))
#   delta_nulos <- Variable(ncol(votos_ant))
#   delta_blancos <- Variable(ncol(votos_ant))
#   delta_no <- Variable(ncol(votos_ant))
#   
#   #FUnción objetivo
#   obj <- Minimize(sum(square(votos_ant %*% delta_boric - dataset$boric_sv), 
#                       square(votos_ant %*% delta_kast - dataset$kast_sv),
#                       square(votos_ant %*% delta_nulos - dataset$nulos_sv),
#                       square(votos_ant %*% delta_blancos - dataset$blancos_sv),
#                       square(votos_ant %*% delta_no - dataset$noVoto_sv)
#   ) )
#   # Restricciones
#   constr <- list(delta_boric >= 0,
#                  delta_kast >= 0,
#                  delta_nulos >= 0,
#                  delta_blancos >= 0,
#                  delta_no >= 0,
#                  delta_boric + delta_kast + delta_nulos + delta_blancos + delta_no == 1 #Los votos se conservan
#   )
#   
#   #Resolver el modelo
#   prob <- Problem(obj,constr)
#   result <- solve(prob,solver="OSQP")
#   result$value
#   result$status
#   result$num_iters
#   
#   
#   #Extraer resultados
#   porcentajes = data.frame(origen_voto = colnames(votos_ant),
#                            a_pinera = result$getValue(delta_boric),
#                            a_guiller = result$getValue(delta_kast),
#                            a_blanco= result$getValue(delta_blancos),
#                            a_nulo = result$getValue(delta_nulos),
#                            a_noVoto = result$getValue(delta_no)
#                            # si_voto = sol$x[1:9] + sol$x[10:18],
#                            # no_voto = 1 - sol$x[1:9] - sol$x[10:18]
#   )
#   print(porcentajes)
#   
#   
#   
#   totales = data.frame(origen_voto = colnames(votos_ant),porcentajes[,-1] * colSums(votos_ant))
#   print(totales)
#   
#   return(list(porcentajes = porcentajes,
#               totales = totales ))
# }
# 
# 
# 
# #Llamar a la función para cada región
# region = dlply(dataset,"region",get_model)
# region_totales_det = ldply(region, function(x) x[["totales"]])
# write.xlsx(region_totales_det,"output_votos_por_region.xlsx")
# # tabla con todos los votos sumados
# region_totales = ddply(region_totales_det,"origen_voto",summarise, a_pinera = sum(a_pinera), a_guiller = sum(a_guiller), a_blanco = sum(a_blanco), a_nulo = sum(a_nulo),a_noVoto = sum(a_noVoto))
# write.xlsx(region_totales_det,"output_votos.xlsx")
# 
# # Graficos
# ggplot(melt(region_totales, variable.name = "receptor", value.name = "votos")) + 
#   geom_bar(aes(origen_voto,votos,group = receptor, fill = receptor),stat = "identity") + 
#   theme(axis.text.x = element_text(angle = 60,hjust = 1))
# 
# ggplot(melt(region_totales, variable.name = "receptor", value.name = "votos")) + 
#   geom_bar(aes(receptor,votos,group = origen_voto, fill = origen_voto),stat = "identity") + 
#   theme(axis.text.x = element_text(angle = 60,hjust = 1))
# ggsave("totales_por_candidato.png",width = 8,height = 6)
# 
# Calculo ponderado de porcentajes
region_pje_det = ldply(region, function(x) x[["porcentajes"]])
write.xlsx(region_pje_det,"output_porcentajes_por_region.xlsx")
total_region_pv = melt(
  primera,
  id.vars = c("region"),
  measure.vars = c("goic_pv", "kast_pv", "pinera_pv", "guillier_pv", "sanchez_pv","meo_pv","artes_pv","navarro_pv","nulos_pv","blanco_pv","noVoto_pv"),
  value.name = "votos",
  variable.name = "origen_voto"
)
total_region_pv = ddply(total_region_pv,c("region","origen_voto"),summarise,total_votos_pv = sum(votos,na.rm = T))
region_beta = merge(total_region_pv,region_pje_det,by = colnames(total_region_pv)[1:2], suffixes = c("_tot","_pje"))
region_beta = ddply(
  region_beta,
  "origen_voto",
  summarise,
  a_pinera = sum(a_pinera * total_votos_pv) / sum(total_votos_pv),
  a_guiller = sum(a_guiller * total_votos_pv) / sum(total_votos_pv),
  a_blanco = sum(a_blanco * total_votos_pv) / sum(total_votos_pv),
  a_nulo = sum(a_nulo * total_votos_pv) / sum(total_votos_pv),
  a_noVoto = sum(a_noVoto * total_votos_pv) / sum(total_votos_pv)
)
write.xlsx(region_beta,"output_porcentajes.xlsx")

# Grafico
ggplot(melt(region_beta, variable.name = "receptor", value.name = "porcentaje")) +
  geom_bar(aes(origen_voto,porcentaje,group = receptor, fill = receptor),stat = "identity") +
  theme(axis.text.x = element_text(angle = 60,hjust = 1))
ggsave("porcentajes_por_candidato.png",width = 8,height = 6)
