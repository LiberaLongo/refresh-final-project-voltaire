# Delaunay, crea un reticolo triangolare irregolare a partire 
# dall'insieme delle stazioni di rilevamento ARPAE

# input:    aria_anagrafe_stazioni_pm10.csv
#           comuni_geo_xy.csv
# output:   stazioni_pm10.csv 
#           triangoli_pm10.csv 
#           mappa_comuni_triangoli.csv 
#           mappa_comuni_triangoli.txt (ridondante, ma utile per debug)

import sys
import pandas as pd
import numpy as np
from scipy.spatial import Delaunay

# legge il csv con l'elenco delle stazioni che rilevano PM10
df_stazioni = pd.read_csv('aria_anagrafe_stazioni_pm10.csv', sep= ',', index_col=False)
print ('Lettura del file csv con elenco stazioni PM10: ok!')

points = df_stazioni[['Coord_X', 'Coord_Y']].to_numpy()
print ('creazione array numpy con le coordinate delle stazioni: ok!')

'''
print ('stampa indice e punti stazioni (da 0 a 50 sono 51 stazioni)')
for i, elemento in enumerate(points):
    print(i, elemento)

print ('\nSono in totale', len(points), "stazioni")
print ('------------------------------------------------')
'''

stazioni_pm10_df = pd.DataFrame({
    "id_staz": range(len(df_stazioni)),
    "c_x": df_stazioni["Coord_X"],
    "c_y": df_stazioni["Coord_Y"],
    "cod_staz": df_stazioni["Cod_staz"]})

print ('creazione dataframe stazioni PM10: ok!')

# print (df_stazioni)
# print (stazioni_pm10_df)
# salvo il dataframe nel nuovo file csv per tabella stazioni_pm10.csv
stazioni_pm10_df.to_csv('stazioni_pm10.csv', index=False)
print ('salvataggio dataframe stazioni PM10 in csv: ok!')

# costruisce la triangolazione Delaunay
tri = Delaunay(points)
print ('costruita la triangolazione Delaunay: ok!')

'''
# elenco delle terne indicizzate
print ('terne di vertici indicizzate')
print ('----------------------------')
for i, vertices in enumerate(tri.simplices):
    print(i, vertices)
print ('\nSono in totale', len(tri.simplices), "triangoli")
print ('------------------------------------------------')
'''

# codice vecchio
'''
triangoli_pm10_df = pd.DataFrame({
    "id_triangolo": range(len(df_stazioni)),
    "c_x": df_stazioni["Coord_X"],
    "c_y": df_stazioni["Coord_Y"],
    "cod_staz": df_stazioni["Cod_staz"]})
'''

triangoli_pm10_df = pd.DataFrame(tri.simplices, columns=['v1', 'v2', 'v3'])
triangoli_pm10_df.index.name = 'id_triangolo'
# aggiunta riga valori fittizi
triangoli_pm10_df.loc[-1] = [None, None, None]
# print (triangoli_pm10_df)
print ('creazione dataframe triangoli PM10: ok!')

# salvo il dataframe nel nuovo file csv per tabella triangoli_pm10.csv
triangoli_pm10_df.to_csv('triangoli_pm10.csv', index=True)
print ('salvataggio dataframe triangoli PM10 in csv: ok!')

'''
#visualizzazione del reticolo triangolare
import matplotlib.pyplot as plt

plt.triplot(points[:,0], points[:,1], tri.simplices)
plt.plot(points[:,0], points[:,1], 'o')
plt.show()
'''

# legge il csv con l'elenco dei comuni della Emilia Romagna
df_comuni = pd.read_csv('comuni_geo_xy.csv', sep= ',', index_col=0)
print ('Lettura del file csv con elenco comuni Emilia Romagna: ok!')

print (df_comuni)

#qui definisco le coordinate lineari dei comuni della Emilia Romagna
query_points = df_comuni[["coord_x", "coord_y"]].to_numpy()

'''
print ('Elenco dei centroidi dei comuni')
for i, comuni in enumerate(query_points):
    print(i, comuni)
print ('\nSono in totale', len(query_points), "Comuni")
print ('------------------------------------------------')
'''

# per ogni comune:
# se cade in un triangolo, assegna indice del triangolo in cui cade 
# altrimenti assegna -1 (fuori dal reticolo triangolare)
idx = tri.find_simplex(query_points)
print ('assegnazione indice triangolo ai comuni: ok!')

mappa_comuni_triangoli_df = pd.DataFrame({
    "id_comune": range(len(df_comuni)),
    "istat": df_comuni.index,    
    "comune": df_comuni["comune"],
    "sigla_provincia": df_comuni["sigla_provincia"],
    "coord_x": df_comuni["coord_x"],
    "coord_y": df_comuni["coord_y"],
    "id_triangolo": idx})
mappa_comuni_triangoli_df.to_csv('mappa_comuni_triangoli.csv', index=False)
print ('salvataggio dataframe mappa comuni triangoli in csv: ok!')

# scrive in un file
with open('mappa_comuni_triangoli.txt', 'w') as f:
    for i, valore in enumerate(idx):
        f.write(f'{i}: {valore}\n')
print ('salvataggio mappa comuni triangoli in txt: ok!')
