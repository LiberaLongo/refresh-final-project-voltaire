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
from silver.o3 
union
select count(*) as conteggio, 'a - due valori' as tipo 
from (select distinct cod_staz, data_inizio from silver.o3) 
union
select count(*) as conteggio, 'b - tre valori' as tipo 
from (select distinct cod_staz, data_inizio, valore from silver.o3)
order by tipo;
-- 3957135	a - due valori
-- 3957460	b - tre valori
-- 7915056	z - totale


-- ci sono 325 misure doppie con valori differenti,
-- questo è un grosso problema, come lo trattiamo?
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

-- verifica unicità misure per co
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

-- distribuzione per valori delle misure di CO
select n.valore, count(n.um) 
from bronze.co n  
--where Extract(year from p.data_fine::date) = 2025
group by n.valore 
order by n.valore;



