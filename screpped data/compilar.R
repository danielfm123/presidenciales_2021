library(readxl)
library(openxlsx)
library(plyr)

folder = "votos1/"
files = dir(folder,pattern = "xlsx$")
files = paste0(folder,files)

compilado = ldply(files,read_xlsx)
head(compilado)

compilado[,1] = NULL
compilado[,-1:-7] = colwise(as.numeric)(compilado[,-1:-7])

sum(compilado[,-1:-7],na.rm = T)


write.xlsx(compilado, "votos1.xlsx",overwrite = T)
