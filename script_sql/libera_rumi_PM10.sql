-- costruzione della tabella storici per PM10 in silver
-- eliminazione di righe duplicate
drop table if exists silver.pm10_00_distinct ;
create table silver.pm10_00_distinct as (
	select distinct cod_staz, id_param, data_inizio, data_fine, valore, um
	from bronze.pm10
);

-- quante righe erano duplicate e ho rimosso?
select count(*), 'bronze' as t from bronze.pm10
union all
select count(*), 'silver' as t from silver.pm10_00_distinct;
-- 2 righe in meno

-- ETL modifica colonne data e ora 
-- e riporto in tabella finale
drop table if exists silver.pm10 cascade;
create table silver.pm10 as (
	select cod_staz, id_param,
	to_timestamp(left(data_inizio, 10), 'DD/MM/YYYY' )::date as data,
	right(data_inizio, 2)::int4 as ora,
	valore, um from silver.pm10_00_distinct
	order by data, cod_staz
);

-- stagioni
drop view if exists gold.pm10_season;
create view gold.pm10_season as (
	select *,
		extract(year from data) as year,
		case
			when extract(month from data) in (12, 1, 2)
				then 1
			when extract(month from data) in (3, 4, 5)
				then 2
			when extract(month from data) in (6, 7, 8)
				then 3
			when extract(month from data) in (9, 10, 11)
				then 4
		end as season_numero,
		case
			when extract(month from data) in (12, 1, 2)
				then 'Inverno'
			when extract(month from data) in (3, 4, 5)
				then 'Primavera'
			when extract(month from data) in (6, 7, 8)
				then 'Estate'
			when extract(month from data) in (9, 10, 11)
				then 'Autunno'
		end as name_season
	from silver.pm10
);

select * from gold.pm10_season;

-- Superamenti dei limiti di legge.
-- Per ogni centralina e comune:
-- quante volte all'anno vengono superate le soglie?
-- Quali comuni rischiano le sanzioni europee?

-- anno civile
drop view if exists gold.pm10_superamenti_anno_civile;
create view gold.pm10_superamenti_anno_civile as
with limite as (
	select valore_limite
	from bronze.criteri_superamento
	where
		inquinante_parametro = 'PM10'
		and periodo_mediazione = 'anno civile'
		and now()
			between inizio_validita::date
				and fine_validita::date
)
select a.year, a.cod_staz, dim.provincia, a.media_pm10
from (
	select year, cod_staz, media_pm10
	from (
		select
			extract(year from data) as year,
			cod_staz,
			avg(valore) as media_pm10
		from silver.pm10
		group by extract(year from data), cod_staz
		order by extract(year from data), cod_staz
	)
	where media_pm10 >= limite
) as a
join silver.dim_stazioni as dim
	on dim.cod_staz = a.cod_staz;

select * from gold.pm10_superamenti_anno_civile;
-- select * from bronze.criteri_superamento;

-- 1 giorno
--drop view if exists gold.pm10_superamenti_1giorno;
--create view gold.pm10_superamenti_1giorno as
--select extract(year from data) as year, cod_staz, count(*)
--from (
--	select cod_staz, data, valore
--	from silver.pm10
--	where valore >= (
--		select valore_limite
--		from bronze.criteri_superamento
--		where
--			inquinante_parametro = 'PM10'
--			and periodo_mediazione = '1 giorno'
--			and now()
--				between inizio_validita::date
--					and fine_validita::date
--	)
--)
--group by year, cod_staz
--join ... silver.dim_stazioni;

--drop view if exists gold.pm10_superamenti_1giorno;
--create view gold.pm10_superamenti_1giorno as
-- 50 (valore da non superare ogni giorno)
with limite as (
	select valore_limite
	from bronze.criteri_superamento
	where
		inquinante_parametro = 'PM10'
		and periodo_mediazione = '1 giorno'
		and now()
			between inizio_validita::date
				and fine_validita::date
),
-- 35 (volte all'anno)
volte as (
	select numero_superamenti
	from bronze.criteri_superamento
	where
		inquinante_parametro = 'PM10'
		and periodo_mediazione = '1 giorno'
		and now()
			between inizio_validita::date
				and fine_validita::date
)
select * from 

-- controlliamo il criterio
select * from silver.pm10;

-- affidabilita` delle misure
-- affidabilita` = giorni con misura / giorni attesi

drop view gold.pm10_affidabilita_misure;
create view gold.pm10_affidabilita_misure as
select a.cod_staz, dim.provincia, media_percentuale
from (
	select cod_staz, avg(percentuale) as media_percentuale
	from (
		select
			cod_staz,
			extract (year from data) as year,
			count(*) as numero_misure,
			(count(*) / 365.0) * 100 AS percentuale
		from silver.pm10
		group by cod_staz, extract (year from data)
		order by cod_staz, year
	)
	group by cod_staz
) as a
join silver.dim_stazioni as dim
	on a.cod_staz = dim.cod_staz
	
select * from gold.pm10_affidabilita_misure;
