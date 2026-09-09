-- allestimento iniziale creazione degli schemi
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS bollettini;

-- creazione tavola silver.bollettini cumulativa dei bollettini giornalieri
CREATE TABLE silver.bollettini (
	station_id int8 NULL,
	variable_id int8 NULL,
	reftime text NULL,
	value float8 NULL,
	v_flag text NULL,
	time_acquisizione timestamptz NULL
);

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


