#!/usr/bin/env python3

import logging
import os
from sqlalchemy import create_engine, text
import pandas as pd
from pathlib import Path
import requests
from datetime import datetime
from zoneinfo import ZoneInfo

def my_main_debug():
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

#	crea il motore di connessione al db
	engine = create_engine(connection_str)

# download file csv con le misure giornaliere
# e le validazioni differenti T,G,M,S da ARPAE
# url = 'https://dati.arpae.it/datastore/dump/4dc855a1-6298-4b71-a1ae-d80693d43dcb?bom=True'

	logging.info("main_debug: download csv da ARPAE")

	url = "https://dati.arpae.it/datastore/dump/4dc855a1-6298-4b71-a1ae-d80693d43dcb?bom=True"
	file_path = "/home/arpae.csv"

	response = requests.get(url, stream=True, timeout=120)
	response.raise_for_status()

	with open(file_path, "wb") as f:
		for chunk in response.iter_content(chunk_size=1024 * 1024):
			if chunk:
				f.write(chunk)

	print(f"CSV salvato in {file_path}")
	logging.info(f"main_debug: CSV salvato in {file_path}")

	logging.info("main_debug: lettura csv da ARPAE scaricato")
	df = pd.read_csv("/home/arpae.csv", encoding="utf-8-sig")

	logging.info("main_debug: scrittura su db del bollettino misure aria")
	data = datetime.now(ZoneInfo("Europe/Rome")).strftime("%Y-%m-%d")
	data_ora = datetime.now(ZoneInfo("Europe/Rome")).strftime("%Y-%m-%d_%H-%M-%S")
	df.to_sql(name=f"bollettino_misure_aria_{data_ora}", con=engine, schema="bronze", 
			   if_exists="replace", index=False)
	df.to_sql(name="staging_bollettino", con=engine, schema="silver", 
			   if_exists="replace", index=False)
	
	logging.info("main_debug: ---FINE FUNCTION APP---")
	
	return

def up_bollettini():
	# legge le variabili di ambiente per la connessione al db
	HOST = os.getenv("DB_HOST")
	PORT = os.getenv("DB_PORT")
	DB_NAME = os.getenv("DB_NAME")
	USER = os.getenv("DB_USER")
	PASSWORD = os.getenv("DB_PASSWORD")
	logging.info("update_bollettini: lettura variabili di ambiente per la connessione al db")

#	costruisce la stringa di connessione al db
	if USER and PASSWORD and HOST and PORT and DB_NAME:
			connection_str = (
				f"postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB_NAME}"
			)
	else:
		logging.info("Errore: .env is not configured correctly --> connection_str contains None values")
		raise SystemExit(1)
	logging.info("update_bollettini: costruita la stringa di connessione al db completata")

#	crea il motore di connessione al db
	engine = create_engine(connection_str)
	logging.info("update_bollettini: creato il motore di connessione al db completata")

# 	esegue l'update della tabella cumulativa bollettini
#   aggiornando con i valori di staging_bollettino giornaliero
	try:
		with engine.begin() as conn:
			conn.execute(
				text("""
					INSERT INTO silver.bollettini (
						station_id, variable_id, reftime, value, v_flag)
					SELECT station_id, variable_id, reftime, value, v_flag
				FROM silver.staging_bollettino
				ON CONFLICT (station_id, variable_id, reftime)
				DO UPDATE SET 
					value = EXCLUDED.value,
					v_flag = EXCLUDED.v_flag
				;
            """)
        )
	except Exception as e:
		logging.exception(f"update_bollettini: Errore durante l'aggiornamento della tabella cumulativa bollettini: {e}")
		raise

	logging.info("update_bollettini: aggiornata la tabella cumulativa bollettini. Completato, OK!")

	return

