-- costruzione della tabella storici per PM25 in silver
-- eliminazione di righe duplicate
drop table if exists silver.pm25_00_distinct;
create table silver.pm25_00_distinct as (
	select distinct cod_staz, id_param,
		data_inizio, data_fine, valore, um
	from bronze.pm25
);

-- quante righe erano duplicate e ho rimosso?
--select count(*) from bronze.pm25
--union all
--select count(*) from silver.pm25_00_distinct;
-- nessuna

-- ETL modifica colonne data e ora 
-- e riporto in tabella finale
drop table if exists silver.pm25 cascade;
create table silver.pm25 as (
	select cod_staz, id_param,
		to_timestamp(
			left(data_inizio, 10), 'DD/MM/YYYY' )::date
		as data,
		right(data_inizio, 2)::int4 as ora,
		valore, um
	from silver.pm25_00_distinct
	order by data, cod_staz
);

-- stagioni
drop view if exists gold.pm25_season;
create view gold.pm25_season as (
	select *,
	    case
	        when extract(month from data) in (12, 1, 2)
	        	then concat(extract(year from data), '_Inverno')
	        when extract(month from data) in (3, 4, 5)
	        	then concat(extract(year from data), '_Primavera')
	        when extract(month from data) in (6, 7, 8)
	        	then concat(extract(year from data), '_Estate')
	        when extract(month from data) in (9, 10, 11)
	        	then concat(extract(year from data), '_Autunno')
	    end as season
	from silver.pm25
);

-- select * from gold.pm25_season;

-- Superamenti dei limiti di legge.
-- Per ogni centralina e comune:
-- quante volte all'anno vengono superate le soglie?
-- Quali comuni rischiano le sanzioni europee?

-- anno civile
drop view if exists gold.pm25_superamenti;
create view gold.pm25_superamenti as
select year, cod_staz, media_pm25
from (
	select
		extract(year from data) as year,
		cod_staz,
		avg(valore) as media_pm25
	from silver.pm25
	group by extract(year from data), cod_staz
	order by extract(year from data), cod_staz
)
where media_pm25 >= (
	select valore_limite
	from bronze.criteri_superamento
	where
		inquinante_parametro = 'PM2.5'
		and periodo_mediazione = 'anno civile'
		and now()
			between inizio_validita::date
				and fine_validita::date
);

-- select * from gold.pm25_superamenti;
-- select * from bronze.criteri_superamento;

