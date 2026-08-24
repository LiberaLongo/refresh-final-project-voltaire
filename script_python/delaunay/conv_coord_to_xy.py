# Converte coordinate geografiche (latitudine e longitudine)
# in coordinate metriche, utilizzando GeoPandas e Shapely.

import geopandas as gpd
from shapely.geometry import Point

# punto in lat/lon
lon = 11.354062
lat = 44.48267

gdf = gpd.GeoDataFrame(
    {
        "id": [1]
    },
    geometry=[Point(lon, lat)],
    crs="EPSG:4326"
)

# trasformazione in UTM 32N
gdf_utm = gdf.to_crs("EPSG:32632")

print(gdf_utm.geometry.x.iloc[0])
print(gdf_utm.geometry.y.iloc[0])