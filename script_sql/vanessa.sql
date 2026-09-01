-- costruzione della tabella silver per il ranking europeo delle città
drop table if exists silver.city_ranking;
create table silver.city_ranking as (
	SELECT "Country" as country, 
		"City name" as city_name, 
		"Population in the city" as population, 
		"City Centroids Latitude" as lat, 
		"City Centroids Longitude" as long,
		"Rank" as rank, 
		"Fine particulate matter (ug/m3)" as pm25, 
		"Rank (PM2.5)" as rank_pm25,
		"Ozone (ug/m3)", 
		"Rank (O3)" as rank_o3, 
		"Nitrogen dioxide (ug/m3)", 
		"Rank (NO2)" as rank_no2
	FROM bronze.cityranking_eu
);