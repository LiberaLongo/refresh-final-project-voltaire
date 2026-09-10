--------------------------------------------------------
-- MAIN script file pipeline ETL e modellazione multidim
--------------------------------------------------------

----------------
-- DIMENSIONI --
----------------

-- creazione della dim_stazioni da aria_anagrafe_stazioni
drop table if exists silver.dim_stazioni CASCADE;
create table silver.dim_stazioni as ( 
	select distinct aas.cod_staz, aas.stazione, aas.comune, aas.indirizzo, 
				aas.provincia , aas.altezza, aas.coord_x, aas.coord_y,
				aas.lon_geo, aas.lat_geo, aas.sr, aas.sr_geo  
	from  bronze.aria_anagrafe_stazioni aas
	union
	select -1 as cod_staz, 'ND' as stazione, 'ND' as comune, 'ND' as indirizzo, 'ND' as provincia,
		0 as altezza, 0 as coord_x, 0 as coord_y, 0 as lon_geo, 0 as lat_geo, 0 as sr, 0 as sr_geo
	order by cod_staz
);

-- creazione della dim_parametri da aria_parametri_inquinanti
drop table if exists silver.dim_parametri CASCADE;
create table silver.dim_parametri as (
	select id_parametro, parametro, um, tmed_min, note
	from bronze.aria_parametri_inquinanti
	union
	select -1 as id_parametro, 'ND' as parametro, 'ND' as um, 0 as tmed_min, '--- valore parametro fittizio ---'
	order by id_parametro
);

-- bridge
-- creo tabella di relazione tra stazioni e parametri
-- in pratica si estraggono le coppie ID stazione e ID parametro
drop table if exists silver.staz_param;
create table silver.staz_param as (
	select aas.cod_staz , aas.id_param 
	from bronze.aria_anagrafe_stazioni aas
	)
;

----------------
-- INQUINANTI --
----------------

-- PM10

-- costruzione della tabella storici per PM10 in silver
-- eliminazione di righe duplicate
drop table if exists silver.pm10_01;
create table silver.pm10_01 as (
	select distinct cod_staz, id_param, data_inizio, data_fine, valore, um
	from bronze.pm10
);
-- ETL modifica colonne data e ora 
-- e riporto in tabella finale
drop table if exists silver.pm10;
create table silver.pm10 as (
	select cod_staz, id_param,
	to_timestamp(left(data_inizio, 10), 'DD/MM/YYYY' )::date as data,
	right(data_inizio, 2)::int4 as ora,
	valore, um from silver.pm10_01
);

-- PM25

-- costruzione della tabella storici per PM25 in silver
-- eliminazione di righe duplicate
drop table if exists silver.pm25_01;
create table silver.pm25_01 as (
	select distinct cod_staz, id_param, data_inizio, data_fine, valore, um
	from bronze.pm25
);
-- ETL modifica colonne data e ora 
-- e riporto in tabella finale
drop table if exists silver.pm25;
create table silver.pm25 as (
	select cod_staz, id_param,
	to_timestamp(left(data_inizio, 10), 'DD/MM/YYYY' )::date as data,
	right(data_inizio, 2)::int4 as ora,
	valore, um from silver.pm25_01
);

-- NO2

-- costruzione della tabella storici per NO2 in silver
-- prima ETL si escludono i valori di misura < 0
drop table if exists silver.no2_01;
create table silver.no2_01 as (
	SELECT cod_staz, id_param, data_inizio,  data_fine, valore, um 
	FROM bronze.no2
	where valore >= 0
);
-- i valori di misura < 0 vengono riportati in tabella ETL_errata
drop table if exists silver.etl_errata_no2;
create table silver.etl_errata_no2 as (  
	select * from bronze.no2
	where valore < 0
);
-- seconda ETL si eliminano le righe duplicate
drop table if exists silver.no2_02;
create table silver.no2_02 as ( 
	SELECT distinct cod_staz, id_param, data_inizio, data_fine, valore, um 
	FROM silver.no2_01
);
-- terza ETL si elimina un campo ridondante data_fine
--           si definisce data_inizio come sola data -> left (data_inizio, 10)
--           si definisce un nuovo campo "ora" con l'ora mappando (00 .. 23) -> (0 ..23) 
drop table if exists silver.no2_03;
create table silver.no2_03 as (
	select cod_staz, id_param,
	to_timestamp(left(data_inizio, 10), 'DD/MM/YYYY' )::date as data_inizio,
	right(data_inizio, 2)::int4 as ora_inizio,
	valore, um
	from silver.no2_02
);
-- riporto dell'ultima tabella nella definitiva silver.no2
drop table if exists silver.no2;
create table silver.no2 as ( 
	SELECT cod_staz, id_param, data_inizio, ora_inizio, valore, um
	FROM silver.no2_03
);

-- O3

-- costruzione della tabella storici per O3 in silver
-- prima ETL si escludono i valori di misura < 0
drop table if exists silver.o3_01;
create table silver.o3_01 as (
	SELECT cod_staz, id_param, 
	data_inizio, data_fine,
	valore, um FROM bronze.o3
	where valore >= 0
);
-- i valori di misura < 0 vengono riportati in tabella ETL_errata
drop table if exists silver.etl_errata_o3;
create table silver.etl_errata_o3 as (  
	select * from bronze.o3
	where valore < 0
);
-- seconda ETL si eliminano le misure duplicate
drop table if exists silver.o3_02;
create table silver.o3_02 as (
	select distinct cod_staz, id_param, data_inizio, data_fine, valore, um 
	from silver.o3_01
);
-- terza ETL si elimina un campo ridondante data_fine
--           si definisce data_inizio come sola data -> left (data_inizio, 10)
--           si definisce un nuovo campo "ora" con l'ora mappando (00 .. 23) -> (0 ..23) 
drop table if exists silver.o3_03;
create table silver.o3_03 as (
	select cod_staz, id_param,
	to_timestamp(left(data_inizio, 10), 'DD/MM/YYYY' )::date as data_inizio,
	right(data_inizio, 2)::int4 as ora_inizio,
	valore, um
	from silver.o3_02
);
-- riporto dell'ultima tabella nella definitiva silver.o3
drop table if exists silver.o3;
create table silver.o3 as (
	select cod_staz, id_param, data_inizio, ora_inizio, valore, um from silver.o3_03 as o
);

-- CO

-- conversione dei dati tempo in tipo timestamp::date
-- cancellazione della data_fine e creazione colonna ora_inizio
drop table if exists silver.co CASCADE;
create table silver.co as (
	SELECT cod_staz, id_param, 
	to_timestamp(left(data_inizio, 10), 'DD/MM/YYYY' )::date as data_inizio,
	right(data_inizio, 2)::int4 as ora_inizio,
	valore, um 
	FROM bronze.co
);

-----------------------
-- fatto misurazioni --
-----------------------

-- creazione fatto_misure come unione delle tabelle sugli inquinanti in silver
DROP TABLE if exists silver.fatto_misure_00;
CREATE TABLE silver.fatto_misure_00 as (
SELECT cod_staz, id_param, "data" as giorno, ora, valore
FROM silver.pm10
UNION ALL
SELECT cod_staz, id_param, "data" as giorno, ora, valore
FROM silver.pm25
UNION ALL 
SELECT cod_staz, id_param, data_inizio as giorno, ora_inizio as ora, valore
FROM silver.co
UNION ALL
SELECT cod_staz, id_param, data_inizio as giorno, ora_inizio as ora, valore
FROM silver.no2
UNION ALL
SELECT cod_staz, id_param, data_inizio as giorno, ora_inizio as ora, valore
FROM silver.o3
);

-- usiamo la definizione "meteorologica" di stagioni ovvero:
--  ❄️ inverno meteorologico = dicembre, gennaio, febbraio
--  🌱 primavera meteorologica = marzo, aprile, maggio
--  ☀️ estate meteorologica = giugno, luglio, agosto
--  🍂 autunno meteorologico = settembre, ottobre, novembre

drop table if exists silver.fatto_misure CASCADE;
create table silver.fatto_misure as (
	select cod_staz, id_param, giorno, ora, valore,
		case
			when extract(month from giorno) in (12, 1, 2)
				then 1
			when extract(month from giorno) in (3, 4, 5)
				then 2
			when extract(month from giorno) in (6, 7, 8)
				then 3
			when extract(month from giorno) in (9, 10, 11)
				then 4
		end as id_season
	from silver.fatto_misure_00
);

-- dimensione stagioni
drop table if exists silver.dim_season;
create table silver.dim_season as (
	select 1 as id_season, 'Inverno' as name
	union all
	select 2 as id_season, 'Primavera' as name
	union all
	select 3 as id_season, 'Estate' as name
	union all
	select 4 as id_season, 'Autunno' as name
);

-- view in gold
drop view if exists gold.fatto_misure;
create view gold.fatto_misure as (
	select * from silver.fatto_misure fm 
);

----------------
-- ranking eu --
----------------

-- costruzione della tabella silver per il ranking europeo delle città
drop table if exists silver.city_ranking CASCADE;
create table silver.city_ranking as (
	SELECT "Country" as country, 
		"City name" as city_name, 
		"Population in the city" as population, 
		"City Centroids Latitude" as lat, 
		"City Centroids Longitude" as long,
		"Rank" as rank, 
		"Fine particulate matter (ug/m3)" as pm25, 
		"Rank (PM2.5)" as rank_pm25,
		"Ozone (ug/m3)" as o3, 
		"Rank (O3)" as rank_o3, 
		"Nitrogen dioxide (ug/m3)" as no2, 
		"Rank (NO2)" as rank_no2
	FROM bronze.cityranking_eu
);

-----------------------------------
--       VIEW in GOLD            --
-----------------------------------
-- creazione della view con le posizioni geografiche delle centraline stazioni di rilevamento
drop view if exists gold.mappa_geografica_stazioni;
create view gold.mappa_geografica_stazioni as ( 
	select stazione, comune, provincia, lon_geo, lat_geo from silver.dim_stazioni ds
	where ds.cod_staz != -1
);

-- costruzione della vista gold.city_ranking per il ranking europeo delle città
drop view if exists gold.city_ranking;
create view gold.city_ranking as (
	SELECT country, city_name, population, 
		   lat, long, rank, pm25, rank_pm25, o3, rank_o3, no2, rank_no2
	FROM silver.city_ranking
);

-- dim_season
drop view if exists gold.dim_season;
create view gold.dim_season as 
	SELECT id_season, "name"
	FROM silver.dim_season;
-- dim_stazioni
drop view if exists gold.dim_stazioni;
create view gold.dim_stazioni as
	SELECT cod_staz, stazione, comune, indirizzo, provincia, altezza, coord_x, coord_y, lon_geo, lat_geo, sr, sr_geo
	FROM silver.dim_stazioni;
-- dim_inquinanti (from dim_parametri)
drop view if exists gold.dim_inquinanti;
create view gold.dim_inquinanti as
	SELECT id_parametro as id_param, 
	       parametro as inquinante, 
	       um, tmed_min, note
	FROM silver.dim_parametri
	WHERE id_parametro in (5, 7, 8, 10, 111);
-- bridge
drop view if exists gold.bridge_staz_param;
create table gold.bridge_staz_param as
	SELECT cod_staz, id_param
	FROM silver.staz_param;

--------------
-- FORECAST --
--------------

-- allestimento tabelle e funzioni per la pipeline forecast

-- creazione della funzione silver.punto_griglia
-- per l'assegnazione di punto griglia al centroide dei comuni
CREATE OR REPLACE FUNCTION silver.punto_griglia(p_lat numeric, p_lon numeric)
 RETURNS TABLE(lat_grid numeric, lon_grid numeric, lat_index integer, lon_index integer)
 LANGUAGE sql
 IMMUTABLE
AS $function$
    WITH indici AS (
        SELECT
            ROUND((p_lat - 43.75::NUMERIC) / 0.1::NUMERIC)::INTEGER AS i,
            ROUND((p_lon - 9.05::NUMERIC)  / 0.1::NUMERIC)::INTEGER AS j
    )
    SELECT
        43.75::NUMERIC + i * 0.1::NUMERIC,
        9.05::NUMERIC  + j * 0.1::NUMERIC,
        i,
        j
    FROM indici
    WHERE i BETWEEN 0 AND 14
      AND j BETWEEN 0 AND 39;
$function$
;

-- creazione tabella silver.comuni_geogrid
-- per associazione dei singoli comuni al punto griglia
drop table if exists silver.comuni_geogrid CASCADE;
create table silver.comuni_geogrid as ( 
	select istat, comune, sigla_provincia, lat, lng,
           p.lat_grid, p.lon_grid, p.lat_index, p.lon_index
	from bronze.comuni_geo as cg
	left join lateral silver.punto_griglia(cg.lat::numeric, cg.lng::numeric) p
	ON TRUE
);

----------------
-- BOLLETTINI --
----------------

-- creazione della tabella cumulativa silver.bollettini
-- CREATE TABLE silver.bollettini (
-- 	station_id int8,
-- 	variable_id int8,
-- 	reftime text,
-- 	value float8,
-- 	v_flag text
-- 	);
-- -- definisco il costraint indice necessario
-- CREATE UNIQUE INDEX idx_bollettini_station_variable_reftime
-- ON silver.bollettini (station_id, variable_id, reftime);
