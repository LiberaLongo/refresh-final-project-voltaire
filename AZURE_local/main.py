#!/usr/bin/env python3

import logging
import os
from sqlalchemy import create_engine, text
import pandas as pd
from pathlib import Path
import requests
from zoneinfo import ZoneInfo
import time
from datetime import datetime, timezone
import cdsapi
import zipfile
import xarray as xr


def connection_string():
	# legge le variabili di ambiente per la connessione al db
	HOST = os.getenv("DB_HOST")
	PORT = os.getenv("DB_PORT")
	DB_NAME = os.getenv("DB_NAME")
	USER = os.getenv("DB_USER")
	PASSWORD = os.getenv("DB_PASSWORD")

	# verifica su log che una variabile sia letta correttamente
	logging.info(f"DB_HOST = {HOST}")

	# costruisce la stringa di connessione al db
	if USER and PASSWORD and HOST and PORT and DB_NAME:
			connection_str = (
				f"postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB_NAME}"
			)
	else:
		logging.info("Errore: .env is not configured correctly --> connection_str contains None values")
		raise SystemExit(1)

	return connection_str

def bollettino_arpae():
	
#	crea il motore di connessione al db
	engine = create_engine(connection_string())

# download file csv con le misure giornaliere
# e le validazioni differenti T,G,M,S da ARPAE
# url = 'https://dati.arpae.it/datastore/dump/4dc855a1-6298-4b71-a1ae-d80693d43dcb?bom=True'

	logging.info("bollettino ARPAE: download csv da ARPAE")

	url = "https://dati.arpae.it/datastore/dump/4dc855a1-6298-4b71-a1ae-d80693d43dcb?bom=True"
	file_path = "/home/arpae.csv"

	for tentativo in range(3):
		try:
			response = requests.get(url, stream=True, timeout=120)
			response.raise_for_status()

			with open(file_path, "wb") as f:
				for chunk in response.iter_content(chunk_size=1024 * 1024):
					if chunk:
						f.write(chunk)

			print(f"CSV salvato in {file_path}")
			logging.info(f"bollettino ARPAE: CSV salvato in {file_path}")

			logging.info("bollettino ARPAE: lettura csv da ARPAE scaricato")
			df = pd.read_csv("/home/arpae.csv", encoding="utf-8-sig")

			logging.info("bollettino ARPAE: scrittura su db del bollettino misure aria")
			data_ora = datetime.now(ZoneInfo("Europe/Rome")).strftime("%Y-%m-%d_%H-%M-%S")
			df.to_sql(name=f"bollettino_misure_aria_{data_ora}", con=engine, schema="bollettini", 
					if_exists="replace", index=False)
# aggiunta della colonna 'timestamp_acquisizione' per l'ultimo bollettino
			df["time_acquisizione"] = datetime.now(ZoneInfo("Europe/Rome"))
			df.to_sql(name="ultimo_bollettino", con=engine, schema="bronze", 
					if_exists="replace", index=False)
			up_bollettini()
			
			break
		except requests.exceptions.HTTPError as e:
			if response.status_code == 502 and tentativo <= 2:
				logging.warning(f"bollettino ARPAE: Errore 502 Bad Gateway, tentativo {tentativo + 1} di 3. Riprovo tra {300 ** tentativo} secondi...")
				time.sleep(2 ** tentativo)
			else:
				raise

	logging.info("bollettino ARPAE: ---FINE FUNCTION APP---")
	
	return

def up_bollettini():
	engine = create_engine(connection_string())
	logging.info("update_bollettini: creato il motore di connessione al db completata")

# 	esegue l'update della tabella cumulativa bollettini
#   aggiornando con i valori di ultimo_bollettino giornaliero
	try:
		with engine.begin() as conn:
			conn.execute(
				text("""
					INSERT INTO silver.bollettini (
						station_id, variable_id, reftime, value, v_flag, time_acquisizione)
					SELECT station_id, variable_id, reftime, value, v_flag, time_acquisizione
					FROM bronze.ultimo_bollettino
					WHERE not (value is NULL or value < 0
						  or station_id is null 
						  or variable_id is null 
						  or reftime is null 
						  or v_flag is null) 
					ON CONFLICT (station_id, variable_id, reftime)
					DO UPDATE SET 
						value = EXCLUDED.value,
						v_flag = EXCLUDED.v_flag,
						time_acquisizione = EXCLUDED.time_acquisizione
					;					;
-- inserimento degli eventuali scarti in tabella
					INSERT INTO silver.etl_errata_bollettini (
						station_id, variable_id, reftime, value, v_flag, time_acquisizione)
						select station_id, variable_id, reftime, value, v_flag, time_acquisizione
						FROM bronze.ultimo_bollettino
						WHERE value is NULL or value < 0
							  or station_id is null 
							  or variable_id is null 
							  or reftime is null 
							  or v_flag is null 
					;
				""")
				)
	except Exception as e:
		logging.exception(f"update_bollettini: Errore durante l'aggiornamento della tabella cumulativa bollettini: {e}")
		raise

	logging.info("update_bollettini: aggiornata la tabella cumulativa bollettini. Completato, OK!")

	try:
		with engine.begin() as conn:
			conn.execute(
				text("""
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
			""")
		)
	except Exception as e:
		logging.exception(f"update_bollettini: Errore durante la creazione della view gold.bollettini: {e}")
		raise

	logging.info("update_bollettini: aggiornata la view gold.bollettini. Completato, OK!")

	return

def forecast():
	# Copernico - CAMS - pipeline forecast pm10
	# download dei dati CAMS (Copernicus Atmosphere Monitoring Service) 
	# dati ristretti all'area geografica compresa 
	# tra latitudine 45.2 e 44.0 e longitudine 9.0 e 13.0 (Italia settentrionale).

	today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

	# definisce il file per accesso a Copernicus
	cdsapirc = Path.home() / ".cdsapirc"
	logging.info("definisce il nome del file con key accesso")

	try:
		# Crea il file necessario a cdsapi
		cdsapirc.write_text(
			f"""url: https://ads.atmosphere.copernicus.eu/api 
			key: {os.environ["COPERNICUS_API_KEY"]}
			"""
			)
		logging.info("creato il file key accesso")

		dataset = "cams-europe-air-quality-forecasts"

		request = {
			"variable": ["particulate_matter_10um"],
			"model": ["ensemble"],
			"level": ["0"],
			"type": ["forecast"],
			"date": [today],
			"time": ["00:00"],
			"leadtime_hour": [str(i) for i in range(96)], 
			"data_format": "netcdf_zip",
			"area": [45.2, 9, 43.7, 13]
		}
		home = Path.home()
		zip_file = home / "pm10-forecast.nc.zip"
#       scarica il file zippato nella home

		logging.info("inizio richiesta a Copernico")
		client = cdsapi.Client()
		client.retrieve(dataset, request).download(zip_file)
		logging.info("fine richiesta a Copernico, ok.")

	finally:
		# Cancella sempre il file cdsapirc, anche in caso di errore
		logging.info("cancellazione file keys")
		if cdsapirc.exists():
			cdsapirc.unlink()
		logging.info("fine cancellazione file keys")

	# passo aggiuntivo unzip del pacchetto scaricato
	with zipfile.ZipFile(zip_file, "r") as zip_ref: 
		zip_ref.extractall(home)

	logging.info("fine unzip del file scaricato")

	# lettura del file .nc e conversione in dataframe pandas
	logging.info("conversione del file in dataframe")

	nc_file = home / "ENS_FORECAST.nc"
	ds = xr.open_dataset(nc_file)

	df = ds.to_dataframe().reset_index()

	engine = create_engine(connection_string())

#   caricamento della tabella su postgres
	logging.info("caricamento tabella su postgres...")
	df.to_sql(
		"forecast_pm10",
		engine,
		schema= "bronze",
		if_exists="replace",
		index=False
	)
	logging.info("caricamento tabella su postgres terminata. OK")

# creazione della tabella in silver forecast_comuni_pm10
	logging.info("inizio creazione table forecast_comuni_pm10")
	with engine.begin() as conn:
		conn.execute(text(""" 
			drop table if exists silver.forecast_comuni_pm10 CASCADE;
			create table silver.forecast_comuni_pm10 as ( 
				with forecast as (
					select 
					current_date::timestamp + time * INTERVAL '1 hour' as ora,
					latitude as lat, longitude as lon, 
						  p.lat_index, p.lon_index,
						  pm10_conc as pm10
					from bronze.forecast_pm10 fp 
					left join lateral silver.punto_griglia(fp.latitude::numeric, fp.longitude::numeric) p
					ON TRUE
					)
				SELECT cg.comune, cg.sigla_provincia, f.ora, f.pm10
				FROM silver.comuni_geogrid cg
				JOIN forecast f
				ON cg.lat_index = f.lat_index AND cg.lon_index = f.lon_index 
				);
			drop view if exists gold.forecast_comuni_pm10;
			create view gold.forecast_comuni_pm10 as (
				select comune, sigla_provincia, ora::date as giorno, extract(hour from ora) as ora, pm10
				from silver.forecast_comuni_pm10
				);
			"""))

	return
