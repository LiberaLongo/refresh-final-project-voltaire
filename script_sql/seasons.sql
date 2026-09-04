-- stagioni

-- pm10
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

-- pm25
drop view if exists gold.pm25_season;
create view gold.pm25_season as (
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
				then 1
			when extract(month from data_inizio) in (3, 4, 5)
				then 2
			when extract(month from data_inizio) in (6, 7, 8)
				then 3
			when extract(month from data_inizio) in (9, 10, 11)
				then 4
		end as season_numero,
		case
			when extract(month from data_inizio) in (12, 1, 2)
				then 'Inverno'
			when extract(month from data_inizio) in (3, 4, 5)
				then 'Primavera'
			when extract(month from data_inizio) in (6, 7, 8)
				then 'Estate'
			when extract(month from data_inizio) in (9, 10, 11)
				then 'Autunno'
		end as name_season
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
				then 1
			when extract(month from data_inizio) in (3, 4, 5)
				then 2
			when extract(month from data_inizio) in (6, 7, 8)
				then 3
			when extract(month from data_inizio) in (9, 10, 11)
				then 4
		end as season_numero,
		case
			when extract(month from data_inizio) in (12, 1, 2)
				then 'Inverno'
			when extract(month from data_inizio) in (3, 4, 5)
				then 'Primavera'
			when extract(month from data_inizio) in (6, 7, 8)
				then 'Estate'
			when extract(month from data_inizio) in (9, 10, 11)
				then 'Autunno'
		end as name_season
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
				then 1
			when extract(month from data_inizio) in (3, 4, 5)
				then 2
			when extract(month from data_inizio) in (6, 7, 8)
				then 3
			when extract(month from data_inizio) in (9, 10, 11)
				then 4
		end as season_numero,
		case
			when extract(month from data_inizio) in (12, 1, 2)
				then 'Inverno'
			when extract(month from data_inizio) in (3, 4, 5)
				then 'Primavera'
			when extract(month from data_inizio) in (6, 7, 8)
				then 'Estate'
			when extract(month from data_inizio) in (9, 10, 11)
				then 'Autunno'
		end as name_season
	from silver.o3
);

select * from gold.o3_season;
