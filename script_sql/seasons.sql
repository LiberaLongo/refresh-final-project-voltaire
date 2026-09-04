-- stagioni

-- usiamo la definizione "meteorologica" di stagioni ovvero:
--  ❄️ inverno meteorologico = dicembre, gennaio, febbraio
--  🌱 primavera meteorologica = marzo, aprile, maggio
--  ☀️ estate meteorologica = giugno, luglio, agosto
--  🍂 autunno meteorologico = settembre, ottobre, novembre

-- la definizione "astonomica" di stagione indica:

--  ☀️ Solstizio
--  Al solstizio, uno dei due emisferi è inclinato il più possibile verso il Sole.
--     Solstizio d'estate → giorno più lungo e Sole più alto → inizio dell'estate astronomica.
--     Solstizio d'inverno → giorno più corto e Sole più basso → inizio dell'inverno astronomico.
--  È il momento in cui raggiungiamo gli estremi del ciclo annuale dell'illuminazione.

--  🌗 Equinozio
--  Agli equinozi, invece, l'asse terrestre non è inclinato né particolarmente verso il Sole né particolarmente lontano da esso.
--  Il Sole si trova idealmente sopra l'equatore e giorno e notte sono quasi della stessa durata.
--     Equinozio di primavera → inizio della primavera astronomica.
--     Equinozio d'autunno → inizio dell'autunno astronomico.
--  È quindi naturale usare questi quattro eventi come "confini" delle stagioni:
--  sono punti ben definiti e fisicamente significativi del ciclo Terra-Sole.

-- pm10
drop view if exists gold.pm10_season;
create view gold.pm10_season as (
	select *,
		extract(year from data) as year,
		case
			when extract(month from data) in (12, 1, 2)
				then '1 - Inverno'
			when extract(month from data) in (3, 4, 5)
				then '2 - Primavera'
			when extract(month from data) in (6, 7, 8)
				then '3 - Estate'
			when extract(month from data) in (9, 10, 11)
				then '4 - Autunno'
		end as season
	from silver.pm10
);

select * from gold.pm10_season;

-- pm25
drop view if exists gold.pm25_season;
create view gold.pm25_season as (
	select *,
		extract(year from data) as year,
		case
			when extract(month from data) in (12, 1, 2)
				then '1 - Inverno'
			when extract(month from data) in (3, 4, 5)
				then '2 - Primavera'
			when extract(month from data) in (6, 7, 8)
				then '3 - Estate'
			when extract(month from data) in (9, 10, 11)
				then '4 - Autunno'
		end as season
	from silver.pm25
);

select * from gold.pm25_season;

-- co
drop view if exists gold.co_season;
create view gold.co_season as (
	select *,
		extract(year from data_inizio) as year,
		case
			when extract(month from data_inizio) in (12, 1, 2)
				then '1 - Inverno'
			when extract(month from data_inizio) in (3, 4, 5)
				then '2 - Primavera'
			when extract(month from data_inizio) in (6, 7, 8)
				then '3 - Estate'
			when extract(month from data_inizio) in (9, 10, 11)
				then '4 - Autunno'
		end as season
	from silver.co
);

select * from gold.co_season;

-- no2
drop view if exists gold.no2_season;
create view gold.no2_season as (
	select *,
		extract(year from data_inizio) as year,
		case
			when extract(month from data_inizio) in (12, 1, 2)
				then '1 - Inverno'
			when extract(month from data_inizio) in (3, 4, 5)
				then '2 - Primavera'
			when extract(month from data_inizio) in (6, 7, 8)
				then '3 - Estate'
			when extract(month from data_inizio) in (9, 10, 11)
				then '4 - Autunno'
		end as season
	from silver.no2
);

select * from gold.no2_season;

-- o3
drop view if exists gold.o3_season;
create view gold.o3_season as (
	select *,
		extract(year from data_inizio) as year,
		case
			when extract(month from data_inizio) in (12, 1, 2)
				then '1 - Inverno'
			when extract(month from data_inizio) in (3, 4, 5)
				then '2 - Primavera'
			when extract(month from data_inizio) in (6, 7, 8)
				then '3 - Estate'
			when extract(month from data_inizio) in (9, 10, 11)
				then '4 - Autunno'
		end as season
	from silver.o3
);

select * from gold.o3_season;
