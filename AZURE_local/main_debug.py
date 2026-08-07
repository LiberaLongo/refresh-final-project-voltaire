#!/usr/bin/env python3

import logging
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
import pandas as pd

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
# 	verifica che la stringa sia corretta
#   magari meglio non mettere la password nei prompt di debug
	logging.info(f"connectrion_str = {connection_str}")

#	crea il motore di connessione al db
	engine = create_engine(connection_str)

# crea uno schema fittizio giusto per testare la connessione al db
	schema_name = "ciccio_pasticcio"
	with engine.connect() as conn:
		conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
		conn.commit()

	return



