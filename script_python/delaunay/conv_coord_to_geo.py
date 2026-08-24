# Converte coordinate metriche in coordinate geografiche 
# (latitudine e longitudine) utilizzando GeoPandas e Shapely.

import geopandas as gpd
from shapely.geometry import Point

gdf = gpd.GeoDataFrame(
    {
        "X":[651070.4],
        "Y":[4944283.5]
    },
    geometry=[
        Point(651070.4,4944283.5)
    ],
    crs="EPSG:32632"
)

gdf_wgs84 = gdf.to_crs("EPSG:4326")

print(gdf_wgs84.geometry)
