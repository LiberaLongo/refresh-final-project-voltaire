-- verifiche sulla tabella anagrafe stazioni
-- la tabella non è una dimensione pura, può essere modellata in fatto + dim

-- quante sono le stazioni differenti?
select distinct aas.cod_staz from bronze.aria_anagrafe_stazioni aas ;
-- sono 54

-- ci sono errori nei parametri associati alle stazioni?
select distinct aas.stazione, aas.cod_staz, aas.comune, aas.indirizzo, 
				aas.provincia , aas.altezza, aas.coord_x, aas.coord_y,
				aas.lon_geo, aas.lat_geo, aas.sr, aas.sr_geo  
from  bronze.aria_anagrafe_stazioni aas;
-- no sono sempre 54


-- creazione della dim_stazioni
drop table if exists silver.dim_stazioni;
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

select * from silver.dim_stazioni ds ;

--creazione della dim_parametri
drop table if exists silver.dim_parametri;
create table silver.dim_parametri as (
	select id_parametro, parametro, um, tmed_min, note
	from bronze.aria_parametri_inquinanti
	union
	select -1 as id_parametro, 'ND' as parametro, 'ND' as um, 0 as tmed_min, '--- valore parametro fittizio ---'
	order by id_parametro);

select * from silver.dim_parametri;



-- prime bozze di join

-- costruzione della tabella storici per PM10 in silver
-- conversione dei dati tempo in tipo timestamp
drop table if exists silver.pm10;
create table silver.pm10 as (
	SELECT cod_staz, id_param, 
	to_timestamp(data_inizio , 'DD/MM/YYYY HH24') as data_inizio,  
	to_timestamp(data_inizio , 'DD/MM/YYYY HH24') as data_fine,
	valore, um FROM bronze.pm10
	);

-- elenco delle misure di una centralina specifica per il 2025
select ds.stazione, ds.comune, p.id_param, p.data_inizio, p.valore, p.um 
from silver.pm10 p 
join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
join silver.dim_parametri dp on dp.id_parametro = p.id_param 
where dp.parametro = 'PM10' and ds.stazione = 'PORTA SAN FELICE'
		and EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) = 2025 
order by data_inizio;


-- creazione della view con le posizioni geografiche delle centraline stazioni di rilevamento
drop view if exists gold.mappa_geografica_stazioni;
create view gold.mappa_geografica_stazioni as ( 
	select stazione, comune, provincia, lon_geo, lat_geo from silver.dim_stazioni ds
	where ds.cod_staz != -1
	);

-- elenco delle misure di una centralina specifica per il 2025
-- estraggo la media annuale
select ds.stazione, ds.comune, p.id_param, avg(p.valore), p.um 
from silver.pm10 p 
join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
join silver.dim_parametri dp on dp.id_parametro = p.id_param 
where dp.parametro = 'PM10' and ds.stazione = 'PORTA SAN FELICE'
		and EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) = 2025 
group by stazione, comune, id_param, p.um;

-- elenco delle misure di ogni centralina per il 2025
-- estraggo la media annuale
select ds.stazione, ds.comune, ds.provincia, dp.parametro, avg(p.valore), p.um 
from silver.pm10 p 
join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
join silver.dim_parametri dp on dp.id_parametro = p.id_param 
where dp.parametro = 'PM10' 
		and EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) = 2025 
group by stazione, comune, provincia, parametro, p.um;

-- elenco delle misure delle centraline, media per provincia per anno specifico
-- estraggo la media annuale
select ds.provincia, dp.parametro, EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) as anno,
		avg(p.valore) as media_annuale, p.um 
from silver.pm10 p 
join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
join silver.dim_parametri dp on dp.id_parametro = p.id_param 
where dp.parametro = 'PM10'  
group by provincia, parametro, EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')), p.um
;

-- creazione view di valori medi annuali per provincia per anno del parametro PM10
drop view if exists gold.medie_annuali_provincie;
create view gold.medie_annuali_provincie as (
	select ds.provincia, EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) as anno,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.pm10 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM10'  
	group by provincia, parametro, EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')), p.um
);

-- creazione view di valori medi mensili per provincia per mese+anno del parametro PM10
drop view if exists gold.medie_mensili_provincie;
create view gold.medie_mensili_provincie as (
	select ds.provincia, 
		EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) as anno,
		EXTRACT(MONTH FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')) as mese,
		dp.parametro, avg(p.valore) as media_annuale, p.um 
	from silver.pm10 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM10'  
	group by provincia, parametro, 
			EXTRACT(YEAR FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')), 
			EXTRACT(MONTH FROM to_timestamp(p.data_inizio , 'DD/MM/YYYY HH24')),
			p.um
);


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


-- creazione medie triennali provincie per determinare la provincie
-- più inquinate, si considerano gli ultimi tre anni 2023-2024-2025
drop view if exists gold.medie_triennali_provincie_pm10;
create view gold.medie_triennali_provincie_pm10 as (
	select ds.provincia, 
		dp.parametro, avg(p.valore) as media_triennale, p.um 
	from silver.pm10 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.parametro = 'PM10' and 
		EXTRACT(YEAR FROM (p.data_inizio)) >= 2023  
		and EXTRACT(YEAR FROM (p.data_inizio)) <= 2025
	group by provincia, parametro, p.um
	order by avg(p.valore) DESC);

drop view if exists gold.medie_triennali_provincie_pm25;
create view gold.medie_triennali_provincie_pm25 as (
	select ds.provincia, 
		dp.parametro, avg(p.valore) as media_triennale, p.um 
	from silver.pm25 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.id_parametro  = 111 and 
		EXTRACT(YEAR FROM (p.data_inizio)) >= 2023  
		and EXTRACT(YEAR FROM (p.data_inizio)) <= 2025
	group by provincia, parametro, p.um
	order by avg(p.valore) DESC);

drop view if exists gold.medie_triennali_provincie_no2;
create view gold.medie_triennali_provincie_no2 as (
	select ds.provincia, 
		dp.parametro, avg(p.valore) as media_triennale, p.um 
	from silver.no2 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.id_parametro  = 8 and 
		EXTRACT(YEAR FROM (p.data_inizio)) >= 2023  
		and EXTRACT(YEAR FROM (p.data_inizio)) <= 2025
	group by provincia, parametro, p.um
	order by avg(p.valore) DESC);

drop view if exists gold.medie_triennali_provincie_o3;
create view gold.medie_triennali_provincie_o3 as (
	select ds.provincia, 
		dp.parametro, avg(p.valore) as media_triennale, p.um 
	from silver.o3 p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.id_parametro  = 7 and 
		EXTRACT(YEAR FROM (p.data_inizio)) >= 2023  
		and EXTRACT(YEAR FROM (p.data_inizio)) <= 2025
	group by provincia, parametro, p.um
	order by avg(p.valore) DESC);

drop view if exists gold.medie_triennali_provincie_co;
create view gold.medie_triennali_provincie_co as (
	select ds.provincia, 
		dp.parametro, avg(p.valore) as media_triennale, p.um 
	from silver.co p 
	join silver.dim_stazioni ds on p.cod_staz = ds.cod_staz 
	join silver.dim_parametri dp on dp.id_parametro = p.id_param 
	where dp.id_parametro  = 10 and 
		EXTRACT(YEAR FROM (p.data_inizio)) >= 2023  
		and EXTRACT(YEAR FROM (p.data_inizio)) <= 2025
	group by provincia, parametro, p.um
	order by avg(p.valore) DESC);

-- fine creazione viste medie triennali ultimi tre anni
-------------------------------------------------------

-- creo tabella di relazione tra stazioni e parametri
-- in pratica si estraggono le coppie ID stazione e ID parametro
drop table if exists silver.staz_param;
create table silver.staz_param as (
	select aas.cod_staz , aas.id_param 
	from bronze.aria_anagrafe_stazioni aas
	)
;


-- verifiche sulla tabella bollettino misure aria
-----------------------------------------------
select count(*), bma.v_flag 
from bronze.bollettino_misure_aria bma 
group by bma.v_flag
order by count(*);
-- come prevedibile i dati sono validati in parte crescente da Temporanei
-- a Giornalieri e Mensili, i Semestrali sono ancora pochi

select min(bma.reftime::timestamp ) as inizio, 
       max(bma.reftime::timestamp ) as finali
from bronze.bollettino_misure_aria bma;
-- i dati attuali vanno da giugno 2026 ad agosto 2026

select min(bma.reftime::timestamp ) as inizio, 
       max(bma.reftime::timestamp ) as finali,
       'T - temporanea' as validazione
from bronze.bollettino_misure_aria bma
where bma.v_flag = 'T'
union
select min(bma.reftime::timestamp ) as inizio, 
       max(bma.reftime::timestamp ) as finali,
       'G - giornaliera' as validazione
from bronze.bollettino_misure_aria bma
where bma.v_flag = 'G'
union
select min(bma.reftime::timestamp ) as inizio, 
       max(bma.reftime::timestamp ) as finali,
       'M - mensile' as validazione
from bronze.bollettino_misure_aria bma
where bma.v_flag = 'M'
union
select min(bma.reftime::timestamp ) as inizio, 
       max (bma.reftime::timestamp ) as finali,
       'S - semestrale' as validazione
from bronze.bollettino_misure_aria bma
where bma.v_flag = 'S'
order by inizio
;


-- foto al 8/8/2026 ore 5:44
-- 3672		T
-- 22257	G
-- 46404	S
-- 114414	M
-------------
-- 2026-06-18 11:00:00.000	2026-07-01 00:00:00.000	S - semestrale
-- 2026-06-19 09:00:00.000	2026-08-01 00:00:00.000	M - mensile
-- 2026-07-01 06:00:00.000	2026-08-07 00:00:00.000	G - giornaliera
-- 2026-08-04 01:00:00.000	2026-08-08 00:00:00.000	T - temporanea

-- verifiche su due versioni del bollettino giornaliero di misure aria
select count (*) from bronze."bollettino_misure_aria_2026-08-11" bma 
join bronze.bollettino_misure_aria_old bmao on bmao._id = bma._id 
;
-- 123580
select count(*) from bronze."bollettino_misure_aria_2026-08-11" bma ;
-- 186881
select count(*) from bronze.bollettino_misure_aria_old bmao  ;
-- 186747
-- record vanno record vengono e record cambiano

select min(bma.reftime::timestamp) as inizio, max(bma.reftime::timestamp) as fine 
from bronze."bollettino_misure_aria_2026-08-11" bma ;

select min(bma.reftime::timestamp) as inizio, max(bma.reftime::timestamp) as fine 
from bronze."bollettino_misure_aria_old" bma ;
-- vengono droppati i valori vecchi
-- ma gli id delle misure restano
-- verifichiamo!

select * from bronze."bollettino_misure_aria_2026-08-11" bma 
where bma.reftime::date = '2026-07-17'and bma.variable_id = 5 and bma.station_id = 7000042
union 
select * from bronze.bollettino_misure_aria_old bmao 
where bmao.reftime::date = '2026-07-17'and bmao.variable_id = 5 and bmao.station_id = 7000042
;
-- porca paletta, cambiano gli _id :-D

-- vedere quante misure appaiono con validazioni differenti nei due bollettini
with tempo as (
	select bma.station_id , bma.variable_id ,
	   bmao.v_flag as v_old , bma.v_flag as v_new, 
	   bmao.reftime::timestamp, bma.reftime::timestamp 
	from bronze."bollettino_misure_aria_2026-08-11" bma 
	join bronze.bollettino_misure_aria_old bmao on 
	bma.station_id = bmao.station_id and bma.variable_id = bmao.variable_id 
	and bmao.reftime = bma.reftime and bma.v_flag != bmao.v_flag
	)
select * from tempo
;

select bma.station_id , bma.variable_id , bma.reftime, 
       bma.v_flag as v_flag_old, bma2.v_flag as v_flag_new
from bronze."bollettino_misure_aria_2026-08-11" bma 
join bronze."bollettino_misure_aria_2026-08-11_17-20-56" bma2 
on bma.station_id = bma2.station_id and bma.variable_id = bma2.variable_id and bma.reftime = bma2.reftime 
   and bma.v_flag != bma2.v_flag;
-- pare nessun aggiornamento dal vecchio bollettino scaricato questa notte
-- a quello di oggi alle 19:20
-- devo sistemare il prompt orario

-- CONTROLLO DI OWNERSHIP
-- verifica dei privilegi per lo schema e per la tabella
SELECT
    has_schema_privilege('voltoperator', 'bronze', 'USAGE') AS schema_usage,
    has_table_privilege('voltoperator', 'bronze.bollettino_misure_aria_2026-08-12_10-34-47', 'SELECT') AS table_select;

-- verifica di ownership di una tabella
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'bronze'
  AND tablename like '%bollettino_misure%';

-- chi possiede la nuova tabella?
SELECT pg_get_userbyid(c.relowner), c.relname
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'bronze'
  AND c.relname like '%bollettino%';

-- visualizza le acl per default ownwer
SELECT
    defaclrole::regrole AS owner_role,
    defaclnamespace::regnamespace AS schema_name,
    defaclacl
FROM pg_default_acl
WHERE defaclrole = 'voltadmin'::regrole
  AND defaclnamespace = 'bronze'::regnamespace;

------------------------------------------------------------------------
-- creazione ed aggiornamento della tabella cumulativa silver.bollettini
------------------------------------------------------------------------
-- creazione della tabella cumulativa silver.bollettini
CREATE TABLE silver.bollettini (
	station_id int8,
	variable_id int8,
	reftime text,
	value float8,
	v_flag text
	);
-- definisco il costraint indice necessario
CREATE UNIQUE INDEX idx_bollettini_station_variable_reftime
ON silver.bollettini (station_id, variable_id, reftime);

-- copia del bollettino in silver.staging_bollettino
drop table if exists silver.staging_bollettino;
create table silver.staging_bollettino as (
	select 	station_id, variable_id , reftime ,	value , v_flag
	from bronze."bollettino_misure_aria_2026-08-11_17-20-56" bma
	);

drop table if exists silver.staging_bollettino;
create table silver.staging_bollettino as (
	select 	station_id, variable_id , reftime ,	value , v_flag
	from bronze."bollettino_misure_aria_2026-08-12_15-35-38" bma
	);


-- aggiornamento della tabella cumulativa silver.bollettini
-- operazione da compiere ogni giorno, dopo lo scarico del bollettino giornaliero
-- rinominandolo silver.staging_bollettino
INSERT INTO silver.bollettini (
	station_id, variable_id, reftime, value, v_flag)
SELECT station_id, variable_id, reftime, value, v_flag
FROM silver.staging_bollettino
ON CONFLICT (station_id, variable_id, reftime)
DO UPDATE SET 
	value = EXCLUDED.value,
	v_flag = EXCLUDED.v_flag
;


-- Quanti sforamenti PM10 per ogni centralina per ogni anno
select ds.cod_staz , ds.comune , ds.indirizzo , ds.provincia, count(*) as superamenti, extract(year from p.data_fine::date)
from silver.pm10 p 
join silver.dim_parametri dp on dp.id_parametro = p.id_param 
join silver.dim_stazioni ds on ds.cod_staz = p.cod_staz 
where p.valore >= 50
group by ds.cod_staz , ds.comune , ds.indirizzo , ds.provincia, extract(year from p.data_fine::date) 
having count(*) >=35
order by superamenti desc;

-- Biossido di azoto
select n.cod_staz, count(*) 
from silver.no2 n
where n.data_fine::date = '2025-06-01' 
group by n.cod_staz; 

-- domanda: quante misure orarie vanno perse nelle rilevazioni?
-- per ogni stazione devo contare 24 misure
select n.cod_staz, n.data_fine::date, count(*) 
from silver.no2 n
group by n.cod_staz, n.data_fine::date
having count(*) < 24;

-- uso la query precedente e conto le eccezioni
with tabella as ( 
select n.cod_staz, n.data_fine::date, count(*) 
from silver.no2 n
group by n.cod_staz, n.data_fine::date
having count(*) < 24
)
select count(*) from tabella;
--109000 eccezioni
select count(*) from silver.no2 n ;
-- 6 milioni di record

select 109000. / (5955256./24) * 100.
--43,9% tantissime!!!
-- mancano tante misure

select min(n.data_inizio), max(n.data_inizio ) 
from silver.no2 n 

select count( distinct (n.data_inizio::date))
from silver.no2 n ;
-- 5844 giorni

select 5844*24
-- dovrebbero esserci 140256  misure orarie

select count(*) from silver.no2 n ;
-- 5.955.256

select count(distinct n.cod_staz) from silver.no2 n
-- 53 codici stazione per no2

select 5844*24*53
-- 7.433.568

-- vedere una distribuzione del numero di misure giornaliere per centralina per giornata
with tabella as (
select n.cod_staz, n.data_fine::date, count(*) as num_misure
from silver.no2 n
group by n.cod_staz, n.data_fine::date
)
select count(*) , num_misure
from tabella t
group by num_misure
order by num_misure desc;
-- cos'è che ha 28, 44 e addirittura 46 misure in un giorno?

with tabella as (
select n.cod_staz, n.data_fine::date, count(*) as num_misure
from silver.no2 n
group by n.cod_staz, n.data_fine::date
)
select count(*) , num_misure, cod_staz, data_fine::date
from tabella t
group by num_misure, cod_staz, data_fine::date
order by num_misure desc;

select * from silver.no2 n 
where n.cod_staz = 8000038 and data_fine::date = '2012-09-17'
;

select * from silver.no2 n 
where n.cod_staz = 8000038 and data_fine::date = '2012-09-18'
;

-- verifica sulle unicità delle misure in no2
select count(*), 'totale' as tipo 
from silver.no2 
union
select count(*), 'distinte' as tipo 
from (select distinct n.cod_staz, n.data_fine from silver.no2 n);
-- sono 5.954.670 le distinte
-- sono 5.955.256 le totali
-- differenza -> 586 da eliminare ETL

--controlliamo per co
select count(*), 'totale' as tipo 
from silver.co
union
select count(*), 'distinte' as tipo 
from (select distinct cod_staz, data_fine from silver.co);
--differenza -> 74

--controlliamo per o3
select count(*), 'totale' as tipo 
from silver.o3
union
select count(*), 'distinte' as tipo 
from (select distinct cod_staz, data_fine from silver.o3);
--differenza -> 4 milioni di righe
-- cosa sono tutti queste righe sballate?!? :-/ porca paletta!!!

-- quante sono le centraline che hanno raccolto dati in effetti sui vari inquinanti?
-- per quanto tempo?
-- TABELLA PROSPETTO PER STIMA NUMERO MISURE
drop table if exists silver.tabella_prospetto_stima_misure;
create table silver.tabella_prospetto_stima_misure as( 
select count(distinct p.cod_staz) as numero_centraline, 
		count(*) as numero_righe_misure, 
		max(data_inizio::date) - min(data_inizio::date) as giorni_misure_totali,
		'pm10' as tipo_inquinante from silver.pm10 p
union
select count(distinct cod_staz) as numero_centraline,
		count(*) as numero_righe_misure,
		max(data_inizio::date) - min(data_inizio::date) as giorni_misure_totali,
		'pm2.5' as tipo_inquinante from silver.pm25
union
select count(distinct cod_staz) as numero_centraline,
		count(*) as numero_righe_misure,
		max(data_inizio::date) - min(data_inizio::date) as giorni_misure_totali,
		'no2' as tipo_inquinante from silver.no2
union
select count(distinct cod_staz) as numero_centraline, 
		count(*) as numero_righe_misure,
		max(data_inizio::date) - min(data_inizio::date) as giorni_misure_totali,
		'o3' as tipo_inquinante from silver.o3
union 
select count(distinct cod_staz) as numero_centraline,
		count(*) as numero_righe_misure,
		max(data_inizio::date) - min(data_inizio::date) as giorni_misure_totali,
		'co' as tipo_inquinante from silver.co
order by tipo_inquinante
);

select * from silver.tabella_prospetto_stima_misure ;

select tpsm.numero_centraline , 
       tpsm.giorni_misure_totali ,
       tpsm.numero_centraline * tpsm.giorni_misure_totali as stima_misure_giornaliere,
       tpsm.numero_centraline * tpsm.giorni_misure_totali * 24 as stima_misure_orarie,
       tpsm.numero_righe_misure ,
       tpsm.tipo_inquinante 
from silver.tabella_prospetto_stima_misure tpsm 
order by tpsm.tipo_inquinante ;

-- alla ricerca del problema duplicazione milioni di righe O3
select o.cod_staz , o.data_inizio::date,  count(o.valore)  from silver.o3 o
group by cod_staz , o.data_inizio::date
order by count(o.valore) desc;

select cod_staz, data_inizio, valore 
from silver.o3
where cod_staz= 9000083 and data_inizio::date = '2024-11-13';

-- verifica dell'unicità delle misure in base a codice stazione data e valore misurato
select count(*) as conteggio, 'z - totale' as tipo
from bronze.o3 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from bronze.o3) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from bronze.o3)
order by tipo;
-- 3957135	a - due valori
-- 3957460	b - tre valori
-- 7915056	z - totale
--
-- in bronze ci sono comunque disallineamenti ma non come in silver
-- sono comunque un po' più del doppio, cosa sono?
-- 3957504	a - due valori
-- 3957504	b - tre valori
-- 7915056	z - totale

select count( distinct (o.cod_staz , o.data_inizio , o.data_fine ,
       o.id_param , o.valore , o.um ))       
from bronze.o3 o;
--3957504
select count( distinct (o.cod_staz , o.data_inizio , o.data_fine ,
       o.id_param , o.um ))       
from bronze.o3 o;


-- ci sono 325 misure doppie con valori differenti,
-- questo è un grosso problema, come lo trattiamo?
-- questo avviene solo in silver per un qualche problema di conversione stringa -> timestamp 
SELECT
    cod_staz,
    data_inizio,
    COUNT(DISTINCT valore) AS numero_misure,
    ARRAY_AGG(DISTINCT valore ORDER BY valore) AS misure
FROM silver.o3
GROUP BY cod_staz, data_inizio
HAVING COUNT(DISTINCT valore) > 1
ORDER BY cod_staz, data_inizio;

-- verifica unicità misure per pm10
select count(*) as conteggio, 'z - totale' as tipo
from silver.pm10 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from silver.pm10) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from silver.pm10)
order by tipo;
-- solo due misure duplicate

-- verifica unicità misure per pm25
select count(*) as conteggio, 'z - totale' as tipo
from silver.pm25 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from silver.pm25) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from silver.pm25)
order by tipo;
-- non ci sono misure duplicate

-- verifica unicità misure per no2
select count(*) as conteggio, 'z - totale' as tipo
from silver.no2 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from silver.no2) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from silver.no2)
order by tipo;
-- 5954670	a - due valori
-- 5955088	b - tre valori
-- 5955256	z - totale

-- verifica unicità misure per no2 dalla tabella origine in bronze
select count(*) as conteggio, 'z - totale' as tipo
from bronze.no2 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from bronze.no2) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from bronze.no2)
order by tipo;
-- 5955206	a - due valori
-- 5955206	b - tre valori
-- 5955256	z - totale
-- ci sono 50 dupliche?

select 5955256-5955088 as conteggio, 'discordanze' as tipo
union
select 5955256-5954670 as conteggio, 'dupliche' as tipo;
-- 168	discordanze
-- 586	dupliche

SELECT
    cod_staz,
    data_inizio,
    COUNT(DISTINCT valore) AS numero_misure,
    ARRAY_AGG(DISTINCT valore ORDER BY valore) AS misure
FROM silver.no2
GROUP BY cod_staz, data_inizio
HAVING COUNT(DISTINCT valore) > 1
ORDER BY cod_staz, data_inizio;

-- ricerca delle dupliche nel caso bronze.no2
SELECT
    cod_staz,
    data_inizio,
    COUNT(*) AS numero_righe
FROM bronze.no2
GROUP BY cod_staz, data_inizio
HAVING COUNT(*) > 1
ORDER BY cod_staz, data_inizio;
-- il codice stazione 8000038 dal 17/09/2012 00 al 19/09/2012 06
-- ha misure duplicate e sono esattamente 50

select * 
from bronze.no2 n 
where cod_staz = 8000038 and 
      (data_inizio like '%17/09/2012%' or
       data_inizio like '%18/09/2012%' or
       data_inizio like '%19/09/2012%')
;

-- stesse verifiche di cui sopra per CO
select count(*), 'conteggio totale' as tipo 
from bronze.co c 
union 
select count(distinct (cod_staz, data_inizio)), 'due valori' as tipo
from bronze.co;
-- 1028189	conteggio totale
-- 1028189	due valori
-- non ci sono errori di duplicazione misure 
-- questa verifica mi pare di averla già fatta

-- verifica unicità misure per co
-- in silver ci sono duplicati
select count(*) as conteggio, 'z - totale' as tipo
from silver.co 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from silver.co) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from silver.co)
order by tipo;
-- 74 dupliche, di cui
-- 19 misure doppie discordanti
SELECT
    cod_staz,
    data_inizio,
    COUNT(DISTINCT valore) AS numero_misure,
    ARRAY_AGG(DISTINCT valore ORDER BY valore) AS misure
FROM silver.co
GROUP BY cod_staz, data_inizio
HAVING COUNT(DISTINCT valore) > 1
ORDER BY cod_staz, data_inizio;

-- in bronze non ci sono duplicati
select count(*) as conteggio, 'z - totale' as tipo
from bronze.co 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from bronze.co) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from bronze.co)
order by tipo;

SELECT
    cod_staz,
    data_inizio,
    COUNT(DISTINCT valore) AS numero_misure,
    ARRAY_AGG(DISTINCT valore ORDER BY valore) AS misure
FROM bronze.co
GROUP BY cod_staz, data_inizio
HAVING COUNT(DISTINCT valore) > 1
ORDER BY cod_staz, data_inizio;
-- in bronze il problema non si presenta

-- ricerca di outlier in uno staging bollettino giornaliero di esempio
select sb.variable_id , dp.parametro , 
       min(sb.value) as minimo, max(sb.value) as max,
       dp.um 
from silver.staging_bollettino as sb
join silver.dim_parametri dp on dp.id_parametro =sb.variable_id 
group by sb.variable_id, dp.parametro , dp.um  
;

-- ricerca di outlier in storico pm10
select min(p.valore) as minimo, 
	   max(p.valore) as massimo,
	   Extract(year from p.data_inizio::date) as anno
from silver.pm10 p 
group by anno
order by anno;

-- ricerca di outlier in storico pm25
select min(p.valore) as minimo, 
	   max(p.valore) as massimo,
	   Extract(year from p.data_inizio::date) as anno
from silver.pm25 p 
group by anno
order by anno;

-- distribuzione per valori delle misure di PM10 (eventualmente per anno dato)
select p.valore, count(p.um) 
from bronze.pm10 p 
--where Extract(year from p.data_fine::date) = 2025
group by p.valore 
order by p.valore;
-- tutto ok a parte una insolita frequenza di valori == 0
-- rappresenta una misura statistica distorta ma non influente nel complesso

-- distribuzione per valori delle misure di PM2.5
select p.valore, count(p.um) 
from bronze.pm25 p 
--where Extract(year from p.data_fine::date) = 2025
group by p.valore 
order by p.valore;
-- tutto ok a parte una insolita frequenza di valori == 0
-- rappresenta una misura statistica distorta ma non influente nel complesso

-- distribuzione per valori delle misure di NO2
select n.valore, count(n.um) 
from bronze.no2 n  
--where Extract(year from p.data_fine::date) = 2025
group by n.valore 
order by n.valore;
-- ci sono 172 valori di misure negative che vanno espulse ETL
select *
from bronze.no2 n
where n.valore <0;

-- distribuzione per valori delle misure di O3
select n.valore, count(n.um) 
from bronze.o3 n  
--where Extract(year from p.data_fine::date) = 2025
group by n.valore 
order by n.valore;
-- ci sono 10 valori di misure negative che vanno espulse ETL
select *
from bronze.o3 as o
where o.valore < 0;

-- distribuzione per valori delle misure di O3 dopo pulizia ETL
select o.valore, count(o.um) 
from silver.o3 o  
--where Extract(year from p.data_fine::date) = 2025
group by o.valore 
order by o.valore;

-- distribuzione per valori delle misure di CO
select n.valore, count(n.um) 
from bronze.co n  
--where Extract(year from p.data_fine::date) = 2025
group by n.valore 
order by n.valore;


--
-- ESPLORAZIONI DISCORDANZE TIMESTAMP in SILVER
--
select *
from silver.o3 o
where o.cod_staz = 2000003 and o.data_inizio::text like '%2010-03-28 03%';

select *
from bronze.o3 o
where o.cod_staz = 2000003 and o.data_inizio::text like '%31/03/2024%';

select * from bronze.o3 limit 5;

show timezone;

SET DateStyle TO 'ISO, DMY';
show datestyle;

select count(*), left(o.data_inizio , 10)::date as data 
from bronze.o3 o 
where o.cod_staz = 2000003 and 
	  o.data_inizio::text like '%/2025%' and 
	  o.data_inizio::text like '%/03/%'
group by left(o.data_inizio , 10)::date;


----------------------------------------------------------------------
-- analisi problema duplicazioni l'ultima domenica di marzo cambio ora
-- a parte che ci sono misure doppie generali nei dati in partenza
-- al netto di ciò i giorni di cambio ora hanno comunque 24 misure
-- il che non dovrebbe essere perché ci sono solo 23 ore disponibili
select * from bronze.o3 o
where (o.data_inizio::text like '%29/03/2025%' or
      o.data_inizio::text like '%30/03/2025%' or 
      o.data_inizio::text like '%31/03/2025%')
      and o.cod_staz = 2000003
;

-- esplorazione giorni di cambio ora inversa
select * from bronze.o3 o
where (o.data_inizio::text like '%25/10/2025%' or
      o.data_inizio::text like '%26/10/2025%' or 
      o.data_inizio::text like '%27/10/2025%')
      and o.cod_staz = 2000003
;

-- funzionamento della trasformazione to_timestamp
-- dove si vede chiaramente il comportamento della funzione che accorpa due ore 
select *,
       to_timestamp(data_inizio , 'DD/MM/YYYY HH24') as data_inizio,  
	   to_timestamp(data_inizio , 'DD/MM/YYYY HH24') as data_fine
from bronze.o3 o
where o.data_inizio::text like '%30/03/2025%'
      and o.cod_staz = 2000003
;
-- anche il cast a timestamp senza time zone non elimina il problema
select *,
       to_timestamp(data_inizio , 'DD/MM/YYYY HH24')::timestamp as data_inizio,  
	   to_timestamp(data_inizio , 'DD/MM/YYYY HH24')::timestamp as data_fine
from bronze.o3 o
where o.data_inizio::text like '%30/03/2025%'
      and o.cod_staz = 2000003
;

-- verifica che data_inizio e data_fine siano correttamente posizionate in tutto il dataset
select distinct o.id_param from silver.o3 o ;
select distinct o.um from silver.o3 o ;

select left(o.data_inizio , 10), right(o.data_inizio, 2)::int from silver.o3 o 
limit 10;

-- c'è sempre la differenza di un'ora
-- i due campi sono ridondanti, è possibile eliminarne uno senza 
-- perdita di informazione
select * from silver.o3 o 
where not ((left(o.data_inizio , 10) = left (o.data_fine , 10) 
	  and (right(o.data_inizio, 2)::int + 1 = right(o.data_fine, 2)::int)))
	  and 
	  not ( to_timestamp(o.data_fine, 'DD/MM/YYYY HH24') = (to_timestamp(o.data_inizio, 'DD/MM/YYYY HH24') + INTERVAL '1 hour'))
;

-- verifica simile per la tabella misure NO2
select * from bronze.no2 n  
where not ((left(n.data_inizio , 10) = left (n.data_fine , 10) 
	  and (right(n.data_inizio, 2)::int + 1 = right(n.data_fine, 2)::int)))
	  and 
	  not ( to_timestamp(n.data_fine, 'DD/MM/YYYY HH24') = (to_timestamp(n.data_inizio, 'DD/MM/YYYY HH24') + INTERVAL '1 hour'))
;

-- verifica simile per la tabella misure CO
select * from bronze.co n  
where not ((left(n.data_inizio , 10) = left (n.data_fine , 10) 
	  and (right(n.data_inizio, 2)::int + 1 = right(n.data_fine, 2)::int)))
	  and 
	  not ( to_timestamp(n.data_fine, 'DD/MM/YYYY HH24') = (to_timestamp(n.data_inizio, 'DD/MM/YYYY HH24') + INTERVAL '1 hour'))
;

-- ci sono righe duplicate in pm10 e pm25?
select count(*), 'conteggi totali' as tipo
from bronze.pm10
union
select count ( distinct (cod_staz, data_inizio)), 'distinti' as tipo 
from bronze.pm10
;
-- 2 duplicati

select count(*), 'conteggi totali' as tipo
from bronze.pm25
union
select count ( distinct (cod_staz, data_inizio)), 'distinti' as tipo 
from bronze.pm25
;
-- nessun duplicato

select p.cod_staz , p.data_inizio, count(*)
from bronze.pm10 p 
group by p.cod_staz , p.data_inizio 
having count(*) > 1;

select * from bronze.pm10 p 
where (p.cod_staz = 2000003 and p.data_inizio = '04/06/2024 00') 
      or (p.cod_staz = 8000002 and p.data_inizio = '16/12/2024 00')
;

------------------------------------------------------------
-- altre cose -- esempio di uso di funzioni sql
--            -- preparazione di idw
------------------------------------------------------------
create or replace function silver.distanza (
	x1 double precision,
	y1 double precision,
	x2 double precision,
	y2 double precision)
returns double precision
language sql
IMMUTABLE
STRICT
PARALLEL SAFE
as $$
	select sqrt( 
		power (x2 - x1, 2) +
		power (y2 - y1, 2)
	);
$$

select silver.distanza(0, 0, 1, 1);

create or replace function silver.media_idw (
	v1 double precision,
	d1 double precision,
	v2 double precision,
	d2 double precision,
	v3 double precision,
	d3 double precision)
returns double precision
language sql
IMMUTABLE
STRICT
PARALLEL SAFE
as $$
	WITH pesi AS (
        SELECT
            1.0 / (d1 * d1) AS w1,
            1.0 / (d2 * d2) AS w2,
            1.0 / (d3 * d3) AS w3
    )
	SELECT
        (v1 * w1 + v2 * w2 + v3 * w3) / (w1 + w2 + w3)
    FROM pesi;
$$

-- verifica che un comune sia compreso tra tre centraline corrette
-- San Giovanni in Persiceto
select mctp.istat, 
       mctp.comune ,
       mctp.id_triangolo, 
       tp.v1 as vertice1, 
       tp.v2 as vertice2, 
       tp.v3 as vertice3,
       sp1.cod_staz as staz_1,
       sp2.cod_staz as staz_2,
       sp3.cod_staz as staz_3,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp1.c_x, sp1.c_y) as dist_vertice1,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp2.c_x, sp2.c_y) as dist_vertice2,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp3.c_x, sp3.c_y) as dist_vertice3
from bronze.mappa_comuni_triangoli_pm10 mctp
join bronze.triangoli_pm10 tp on mctp.id_triangolo = tp.id_triangolo
join bronze.stazioni_pm10 sp1 on tp.v1 =sp1.id_staz 
join bronze.stazioni_pm10 sp2 on tp.v2 =sp2.id_staz 
join bronze.stazioni_pm10 sp3 on tp.v3 =sp3.id_staz 
where mctp.istat = 37053;

-- vorrei trovare i tre valori, ad una data stabilita, delle tre centraline 
-- nel simplesso interessato
-- devo joinare tre volte, una per vertice, con la tabella bollettini
with bollettino as (
	select station_id, value, reftime
	from silver.bollettini
	where variable_id = 5 and reftime like '%08/07/2026%')
select mctp.istat, 
       mctp.comune,
       b1.reftime,
       mctp.id_triangolo, 
       tp.v1 as vertice1, 
       tp.v2 as vertice2, 
       tp.v3 as vertice3,
       sp1.cod_staz as staz_1,
       sp2.cod_staz as staz_2,
       sp3.cod_staz as staz_3,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp1.c_x, sp1.c_y) as dist_vertice1,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp2.c_x, sp2.c_y) as dist_vertice2,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp3.c_x, sp3.c_y) as dist_vertice3,
       b1.value as val_staz_1,
       b2.value as val_staz_2,
       b3.value as val_staz_3
from bronze.mappa_comuni_triangoli_pm10 mctp
join bronze.triangoli_pm10 tp on mctp.id_triangolo = tp.id_triangolo
join bronze.stazioni_pm10 sp1 on tp.v1 =sp1.id_staz 
join bronze.stazioni_pm10 sp2 on tp.v2 =sp2.id_staz 
join bronze.stazioni_pm10 sp3 on tp.v3 =sp3.id_staz 
join bollettino as b1 on b1.station_id = sp1.cod_staz 
join bollettino as b2 on b2.station_id = sp2.cod_staz 
join bollettino as b3 on b3.station_id = sp3.cod_staz 
where mctp.istat = 37053;

-- la stazione 4000002 non ha rilevamenti nei giorni prima del 7 agosto
select * from bronze.stazioni_pm10 as s
join silver.bollettini b on b.station_id = s.cod_staz 
where variable_id = 5 and b.reftime like '%08/07/2026%' and 
      (s.cod_staz = 7000041 or s.cod_staz = 8000038 or s.cod_staz = 4000002)
;


-- SECONDO TEST DI STIMA INQUINAMENTO PER UNO SPECIFICO COMUNE
-- prova di estrazione della media del valore di inquinamento 
-- CASO PESATA CON IDW - utilizzo della funzione silver.media_idw()
with tempo as (with bollettino as (
	select station_id, value, reftime
	from silver.bollettini
	where variable_id = 5 and reftime like '%08/07/2026%')
select mctp.istat, 
       mctp.comune,
       b1.reftime,
       mctp.id_triangolo, 
       tp.v1 as vertice1, 
       tp.v2 as vertice2, 
       tp.v3 as vertice3,
       sp1.cod_staz as staz_1,
       sp2.cod_staz as staz_2,
       sp3.cod_staz as staz_3,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp1.c_x, sp1.c_y) as dist_vertice1,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp2.c_x, sp2.c_y) as dist_vertice2,
       silver.distanza(mctp.coord_x, mctp.coord_y, sp3.c_x, sp3.c_y) as dist_vertice3,
       b1.value as val_staz_1,
       b2.value as val_staz_2,
       b3.value as val_staz_3
from bronze.mappa_comuni_triangoli_pm10 mctp
join bronze.triangoli_pm10 tp on mctp.id_triangolo = tp.id_triangolo
join bronze.stazioni_pm10 sp1 on tp.v1 =sp1.id_staz 
join bronze.stazioni_pm10 sp2 on tp.v2 =sp2.id_staz 
join bronze.stazioni_pm10 sp3 on tp.v3 =sp3.id_staz 
join bollettino as b1 on b1.station_id = sp1.cod_staz 
join bollettino as b2 on b2.station_id = sp2.cod_staz 
join bollettino as b3 on b3.station_id = sp3.cod_staz 
where mctp.istat = 37053)
select comune, reftime, 
       round (silver.media_idw(val_staz_1, dist_vertice1,
                        val_staz_2, dist_vertice2,
                        val_staz_3, dist_vertice3)::numeric, 0)
       as stima_inquinamento_pm10,
       'ug/m3' as "unità di misura"
from tempo
;



select * from bronze.mappa_comuni_triangoli_pm10 mctp ;

select * from bronze.stazioni_pm10 sp 

-- per caso python è disponibile in postgres?
SELECT *
FROM pg_available_extensions
;



-- ------------------------------------
-- verifica della costanza delle misure
-- ------------------------------------

-- quanti giorni nel bollettini
with tabella as 
(select min(b.reftime ), max(b.reftime ),
       to_timestamp(min(b.reftime), 'MM/DD/YYYY HH24')::date as data_minima,
       to_timestamp(max(b.reftime), 'MM/DD/YYYY HH24')::date as data_massima
from silver.bollettini as b)
select data_massima - data_minima
from tabella;

-- parametro PM10 
select b.station_id , count(b.value ) as n_misure
from silver.bollettini b 
where b.variable_id = 5
group by b.station_id 
order by n_misure DESC ;
-- le stazioni funzionanti all'estate 2026 sono 42 e non 51 come si è costruita la triangolazione Delaunay
-- bisogna quindi rivedere tutt
with tavola as (
select b.station_id , count(b.value ) as n_misure
from silver.bollettini b 
where b.variable_id = 5
group by b.station_id 
order by b.station_id
)
select station_id, round(n_misure/66., 2) as perc_mis
from tavola
order by perc_mis DESC;


-- parametro Ozono
with tavola as (
select b.station_id , count(b.value ) as n_misure
from silver.bollettini b 
where b.variable_id = 7
group by b.station_id 
order by b.station_id
)
select station_id, n_misure 
from tavola
order by n_misure DESC;

select 1462/1550.* 100;

select b.station_id , count(b.value ) as n_misure
from silver.bollettini b 
where b.variable_id = 128
group by b.station_id 
order by b.station_id ;

-- quali sono i parametri differenti rilasciati nei bollettini?
select distinct variable_id, dp.parametro 
from silver.bollettini b 
join silver.dim_parametri dp on dp.id_parametro = b.variable_id ;
-- 1	SO2 (Biossido di zolfo)
-- 5	PM10
-- 7	O3 (Ozono)
-- 8	NO2 (Biossido di azoto)
-- 9	NOX (Ossidi di azoto)
-- 10	CO (Monossido di carbonio)
-- 20	C6H6 (Benzene)
-- 21	C6H5-CH3 (Toluene)
-- 38	NO (Monossido di azoto)
-- 82	C6H4(CH3)2 (o-xylene)
-- 111	PM2.5



-- verificare nelle tabelle degli storici se ci sono stazioni che non sono più attive
-- pm10
select p.cod_staz , ds.comune , ds.indirizzo , ds.provincia  ,  min(data) as inizio_misure, max(data) as fine_misure  from silver.pm10 as p
join silver.dim_stazioni ds on ds.cod_staz = p.cod_staz 
group by p.cod_staz, ds.comune , ds.indirizzo , ds.provincia
order by max(data);
-- 6 stazioni dismesse

-- pm25
select p.cod_staz , ds.comune , ds.indirizzo , ds.provincia  ,  
       min(data) as inizio_misure, max(data) as fine_misure  
       from silver.pm25 as p
join silver.dim_stazioni ds on ds.cod_staz = p.cod_staz 
group by p.cod_staz, ds.comune , ds.indirizzo , ds.provincia
order by max(data);
-- 5 stazioni dismesse

-- O3 ozono
select p.cod_staz , ds.comune , ds.indirizzo , ds.provincia  ,  
       min(p.data_inizio ) as inizio_misure, max(p.data_inizio ) as fine_misure  
       from silver.o3 as p
join silver.dim_stazioni ds on ds.cod_staz = p.cod_staz 
group by p.cod_staz, ds.comune , ds.indirizzo , ds.provincia
order by max(p.data_inizio );
-- 1 sola stazione dismessa a Villa Minozzo

-- biossido di azoto no2
select p.cod_staz , ds.comune , ds.indirizzo , ds.provincia  ,  
       min(p.data_inizio ) as inizio_misure, max(p.data_inizio ) as fine_misure  
       from silver.no2 as p
join silver.dim_stazioni ds on ds.cod_staz = p.cod_staz 
group by p.cod_staz, ds.comune , ds.indirizzo , ds.provincia
order by max(p.data_inizio );
-- 4 stazioni dismesse

-- co monossido di carbonio
select p.cod_staz , ds.comune , ds.indirizzo , ds.provincia  ,  
       min(p.data_inizio ) as inizio_misure, max(p.data_inizio ) as fine_misure  
       from silver.co as p
join silver.dim_stazioni ds on ds.cod_staz = p.cod_staz 
group by p.cod_staz, ds.comune , ds.indirizzo , ds.provincia
order by max(p.data_inizio );
-- 9 stazioni dismesse

-- verifiche nei bollettini delle stazioni attive nel 2026
-- numero di stazioni attive per parametro di inquinamento
select b.variable_id, dp.parametro , count (distinct(b.station_id )) 
from silver.bollettini b
join silver.dim_parametri dp on dp.id_parametro = b.variable_id 
group by b.variable_id , dp.parametro 
order by b.variable_id ;

-- negli storici, dal 2020 al 2025 inclusi, 6 anni
-- verificare per ogni stazione e per ogni parametro
-- la percentuale delle misure sul totale teorico
select p.cod_staz , round(count(p.valore ) / 2192. *100 , 2) as perc_misure
from silver.pm10 p 
where p."data" >= '2020-01-01'::date and p."data" <= '2025-12-31'::date
group by p.cod_staz 
order by perc_misure DESC;

select '2025-12-31'::date - '2020-01-01'::date ;
-- 2192 giorni
select 2192*24;
-- 52608 ore

select p.cod_staz , round(count(p.valore ) / 2192. *100 , 2) as perc_misure
from silver.pm25 p 
where p."data" >= '2020-01-01'::date and p."data" <= '2025-12-31'::date
group by p.cod_staz 
order by perc_misure DESC;

select p.cod_staz , round(count(p.valore ) / 52608. *100 , 2) as perc_misure
from silver.o3 p 
where p.data_inizio  >= '2020-01-01'::date and p.data_inizio  <= '2025-12-31'::date
group by p.cod_staz 
order by perc_misure DESC;

select p.cod_staz , round(count(p.valore ) / 52608. *100 , 2) as perc_misure
from silver.no2 p 
where p.data_inizio  >= '2020-01-01'::date and p.data_inizio  <= '2025-12-31'::date
group by p.cod_staz 
order by perc_misure DESC;

select p.cod_staz , round(count(p.valore ) / 52608. *100 , 2) as perc_misure
from silver.co p 
where p.data_inizio  >= '2020-01-01'::date and p.data_inizio  <= '2025-12-31'::date
group by p.cod_staz 
order by perc_misure DESC;


------------------------------------------------------
-- query di servizio creazione view bollettini su gold
------------------------------------------------------
drop view if exists gold.bollettini;
create view gold.bollettini as ( 
	select station_id, ds.stazione, ds.comune, ds.indirizzo, ds.provincia,
		   variable_id, dp.parametro, dp.um,
	       reftime::date as giorno,
	       right(reftime, 5)::time as ora,
	       value, v_flag
	from silver.bollettini b
	join silver.dim_stazioni ds on ds.cod_staz = b.station_id 
	join silver.dim_parametri dp on dp.id_parametro = b.variable_id
	where variable_id in (5, 111, 7, 8, 10)
	);

-- seleziona i differenti parametri dei bollettini 
-- estrae l'elenco
	select distinct variable_id, dp.parametro
	from silver.bollettini b
	join silver.dim_stazioni ds on ds.cod_staz = b.station_id 
	join silver.dim_parametri dp on dp.id_parametro = b.variable_id
    where variable_id in (5, 111, 7, 8, 10)
    ;



-------------------------------------------------------
-- spostamento in blocco delle tabelle bollettini
-- dallo schema bronze allo schema bollettini
-------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS bollettini;

-- seleziona i nomi delle tabelle che voglio spostare
SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'bronze'
          AND tablename LIKE 'bollettino_misure_aria%'
;

-- sposta le tabelle 'bollettino_misure_aria%'
-- dallo schema bronze allo schema bollettini 
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'bronze'
          AND tablename LIKE 'bollettino_misure_aria%'
    LOOP
        EXECUTE format(
            'ALTER TABLE bronze.%I SET SCHEMA bollettini',
            r.tablename
        );
    END LOOP;
END $$;



------------------------------------------------------
-- esplorazioni sul reticolo geografico per forecast
------------------------------------------------------
select min(fp.latitude) as min_lat,
       max(fp.latitude) as max_lat,
       min(fp.longitude) as min_lon,
       max(fp.longitude) as max_lon
from gold.forecast_pm10 fp ;


select count (distinct fp.latitude)
from gold.forecast_pm10 fp ;
select distinct fp.latitude
from gold.forecast_pm10 fp
order by fp.latitude ;


select count (distinct fp.longitude)
from gold.forecast_pm10 fp ;


-- creazione della funzione SQL di calcolo del punto griglia approssimato
-- date le coordinate geografiche del punto qualunque interno alla griglia
-- l'intenso uso di ::NUMERIC è per evitare errori di arrotondamento
CREATE OR REPLACE FUNCTION silver.punto_griglia(
    p_lat NUMERIC,
    p_lon NUMERIC
)
RETURNS TABLE (
    lat_grid NUMERIC,
    lon_grid NUMERIC,
    lat_index INTEGER,
    lon_index INTEGER
)
LANGUAGE SQL
IMMUTABLE
AS $$
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
$$;

select silver.punto_griglia(43.7319283, 11.43);

-- la colonna 0 e la 1 indicano latitudine e longitudine di griglia
-- con valori sperabilmente esatti anche nella parte decimale
select lat_grid, lon_grid
from silver.punto_griglia(43.7319283, 11.43) as pg
;

-- in questo modo posso assegnare coordinate di griglia ai centroidi dei comuni
-- da bronze.comuni_geo posso costruire silver.comuni_geo_griglia
select istat, comune, sigla_provincia, lat, lng,
       p.lat_grid, p.lon_grid
from bronze.comuni_geo as cg
left join lateral silver.punto_griglia(cg.lat::numeric, cg.lng::numeric) p
ON TRUE;

-- creo la tabella
drop table if exists silver.comuni_geogrid CASCADE;
create table silver.comuni_geogrid as ( 
	select istat, comune, sigla_provincia, lat, lng,
           p.lat_grid, p.lon_grid, p.lat_index, p.lon_index
	from bronze.comuni_geo as cg
	left join lateral silver.punto_griglia(cg.lat::numeric, cg.lng::numeric) p
	ON TRUE
	);	

-- lanciamoci nel joinare le previsioni per comune
SELECT
    cg.comune, 
    ARRAY_AGG(f.pm10_conc ORDER BY f.time) AS previsioni
FROM silver.comuni_geogrid cg
FULL JOIN gold.forecast_pm10 f
    ON cg.lat_grid = f.latitude AND cg.lon_grid = f.longitude
GROUP BY
    cg.comune;

-- creo view forecast_comuni_pm10 con timestamp = ora
drop view if exists gold.forecast_comuni_pm10;
create view gold.forecast_comuni_pm10 as ( 
with forecast as (
	select current_date::timestamp + time * INTERVAL '1 hour' as ora,
    	   latitude as lat, longitude as lon, 
       	   p.lat_index, p.lon_index,
       	   pm10_conc as pm10
	from gold.forecast_pm10 fp 
	left join lateral silver.punto_griglia(fp.latitude::numeric, fp.longitude::numeric) p
	ON TRUE
	)
SELECT
    cg.comune, cg.sigla_provincia,
    f.ora, f.pm10
FROM silver.comuni_geogrid cg
JOIN forecast f
    ON cg.lat_index = f.lat_index AND cg.lon_index = f.lon_index 
);


-- devo creare una tabella da forecast che abbia gli indici discreti del reticolo per joinare in modo esatto
select time as ora,
       latitude as lat, longitude as lon, 
       p.lat_index, p.lon_index,
       pm10_conc as pm10
from gold.forecast_pm10 fp 
left join lateral silver.punto_griglia(fp.latitude::numeric, fp.longitude::numeric) p
ON TRUE
;

-- joino la forecast temporanea con gli indici interi alla tabella comuni_geogrid
with forecast as (
	select time as ora,
    	   latitude as lat, longitude as lon, 
       	   p.lat_index, p.lon_index,
       	   pm10_conc as pm10
	from gold.forecast_pm10 fp 
	left join lateral silver.punto_griglia(fp.latitude::numeric, fp.longitude::numeric) p
	ON TRUE
	)
SELECT
    cg.comune, cg.sigla_provincia,
    ARRAY_AGG(f.pm10 ORDER BY f.ora) AS previsioni
FROM silver.comuni_geogrid cg
JOIN forecast f
    ON cg.lat_index = f.lat_index AND cg.lon_index = f.lon_index 
GROUP BY
    cg.comune, cg.sigla_provincia
;



-- cosa succede di strano con i bollettini alle 5:20?!?
select count(*) from bollettini."bollettino_misure_aria_2026-09-08_05-20-51" bma;

select count(*) from bollettini."bollettino_misure_aria_2026-09-08_05-35-31" bma ;

select *, 'vecchia' as tab
from bollettini."bollettino_misure_aria_2026-09-08_05-20-51" bma 
where bma.station_id = 5000007 and bma.reftime = '08/10/2026 00:00'
union 
select *, 'nuova' as tab
from bollettini."bollettino_misure_aria_2026-09-08_05-35-31" bma 
where bma.station_id = 5000007 and bma.reftime = '08/10/2026 00:00'

	


