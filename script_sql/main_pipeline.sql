--------------------------------------------------------
-- MAIN script file pipeline ETL e modellazione multidim
--------------------------------------------------------

-- creazione della dim_stazioni da aria_anagrafe_stazioni
--
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

--creazione della dim_parametri da aria_parametri_inquinanti
--
drop table if exists silver.dim_parametri CASCADE;
create table silver.dim_parametri as (
	select id_parametro, parametro, um, tmed_min, note
	from bronze.aria_parametri_inquinanti
	union
	select -1 as id_parametro, 'ND' as parametro, 'ND' as um, 0 as tmed_min, '--- valore parametro fittizio ---'
	order by id_parametro);

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
-- 			 si definisce un nuovo campo "ora" con l'ora mappando (00 .. 23) -> (0 ..23) 
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
-- 			 si definisce un nuovo campo "ora" con l'ora mappando (00 .. 23) -> (0 ..23) 
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


-- costruzione della tabella storici per CO in silver
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


-----------------------------------
--       VIEW in GOLD            --
-----------------------------------
-- creazione della view con le posizioni geografiche delle centraline stazioni di rilevamento
drop view if exists gold.mappa_geografica_stazioni;
create view gold.mappa_geografica_stazioni as ( 
	select stazione, comune, provincia, lon_geo, lat_geo from silver.dim_stazioni ds
	where ds.cod_staz != -1
	);

-- creazione view di valori medi annuali per provincia per anno del parametro PM10
drop view if exists gold.pm10_medie_annuali_provincie;
create view gold.pm10_medie_annuali_provincie as (
	select ds.provincia, EXTRACT(YEAR FROM p.data) as anno,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.pm10 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM10'  
	group by provincia, parametro, EXTRACT(YEAR FROM p.data), p.um
);

-- creazione view di valori medi mensili per provincia per mese+anno del parametro PM10
drop view if exists gold.pm10_medie_mensili_provincie;
create view gold.pm10_medie_mensili_provincie as (
	select ds.provincia, 
		EXTRACT(YEAR FROM p.data) as anno,
		EXTRACT(MONTH FROM p.data) as mese,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.pm10 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM10'  
	group by provincia, parametro, 
			EXTRACT(YEAR FROM p.data), 
			EXTRACT(MONTH FROM p.data),
			p.um
);

-- creazione view di valori medi annuali per provincia per anno del parametro PM2.5
drop view if exists gold.pm25_medie_annuali_provincie;
create view gold.pm25_medie_annuali_provincie as (
	select ds.provincia, EXTRACT(YEAR FROM p.data) as anno,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.pm25 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM2.5'  
	group by provincia, parametro, EXTRACT(YEAR FROM p.data), p.um
);

-- creazione view di valori medi mensili per provincia per mese+anno del parametro PM2.5
drop view if exists gold.pm25_medie_mensili_provincie;
create view gold.pm25_medie_mensili_provincie as (
	select ds.provincia, 
		EXTRACT(YEAR FROM p.data) as anno,
		EXTRACT(MONTH FROM p.data) as mese,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.pm25 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM2.5'  
	group by provincia, parametro, 
			EXTRACT(YEAR FROM p.data), 
			EXTRACT(MONTH FROM p.data),
			p.um
);

-- creazione view di valori medi annuali per provincia per anno del parametro NO2
drop view if exists gold.no2_medie_annuali_provincie;
create view gold.no2_medie_annuali_provincie as (
	select ds.provincia, EXTRACT(YEAR FROM p.data_inizio) as anno,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.no2 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'NO2 (Biossido di azoto)'  
	group by provincia, parametro, EXTRACT(YEAR FROM p.data_inizio), p.um
);

-- creazione view di valori medi mensili per provincia per mese+anno del parametro NO2
drop view if exists gold.no2_medie_mensili_provincie;
create view gold.no2_medie_mensili_provincie as (
	select ds.provincia, 
		EXTRACT(YEAR FROM p.data_inizio) as anno,
		EXTRACT(MONTH FROM p.data_inizio) as mese,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.no2 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'NO2 (Biossido di azoto)'  
	group by provincia, parametro, 
			EXTRACT(YEAR FROM p.data_inizio), 
			EXTRACT(MONTH FROM p.data_inizio),
			p.um
);

-- creazione view di valori medi annuali per provincia per anno del parametro O3
drop view if exists gold.o3_medie_annuali_provincie;
create view gold.o3_medie_annuali_provincie as (
	select ds.provincia, EXTRACT(YEAR FROM p.data_inizio) as anno,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.o3 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'O3 (Ozono)'  
	group by provincia, parametro, EXTRACT(YEAR FROM p.data_inizio), p.um
);

-- creazione view di valori medi mensili per provincia per mese+anno del parametro O3
drop view if exists gold.o3_medie_mensili_provincie;
create view gold.o3_medie_mensili_provincie as (
	select ds.provincia, 
		EXTRACT(YEAR FROM p.data_inizio) as anno,
		EXTRACT(MONTH FROM p.data_inizio) as mese,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.o3 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'O3 (Ozono)'  
	group by provincia, parametro, 
			EXTRACT(YEAR FROM p.data_inizio), 
			EXTRACT(MONTH FROM p.data_inizio),
			p.um
);

-- creazione view di valori medi annuali per provincia per anno del parametro CO
drop view if exists gold.co_medie_annuali_provincie;
create view gold.co_medie_annuali_provincie as (
	select ds.provincia, EXTRACT(YEAR FROM p.data_inizio) as anno,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.co p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'CO (Monossido di carbonio)'  
	group by provincia, parametro, EXTRACT(YEAR FROM p.data_inizio), p.um
);

-- creazione view di valori medi mensili per provincia per mese+anno del parametro co
drop view if exists gold.co_medie_mensili_provincie;
create view gold.co_medie_mensili_provincie as (
	select ds.provincia, 
		EXTRACT(YEAR FROM p.data_inizio) as anno,
		EXTRACT(MONTH FROM p.data_inizio) as mese,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.co p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'CO (Monossido di carbonio)'  
	group by provincia, parametro, 
			EXTRACT(YEAR FROM p.data_inizio), 
			EXTRACT(MONTH FROM p.data_inizio),
			p.um
);

