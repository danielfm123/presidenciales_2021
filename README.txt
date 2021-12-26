 
este es el codigo para realizar el webscraping de los votos de las elecciones presidenciales por mesa desde el sitio del serrvel.

el proceso se divide en 2 partes
1) descargar la lista de mesas lo que genera los archivos llamados dimesciones_xxx.xlsx

se realiza con el script dimensiones.py

2)Descargar los votos, que se divide en 4 partes
a) votos de primera vuelta
se realiza llamando a votaciones_primera.py N1, N2. Donde N1 y N2 corresponden a las mesas de dimesciones_xxx.xlsx, con esto se puede paralelizar el proceso
b) total de inscritos en pv con participacion_primera.py
c) votos de segunda vuelta, identico a a) pero con votaciones_segunda.py
d) total incritos en segunda vuelta, identico a b) pero con participacion_segunda.py (este paso es redundante por que el  total de inscritos es el mismo en ambas votaciones)

Luego con el script en R llamado compilar se pueden unir los xlsx que se generen de a) y c) para crear un compilado

