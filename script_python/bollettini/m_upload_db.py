import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
import pandas as pd

def import_to_db(table, columns):

	load_dotenv(".env")

	USER = os.getenv("DB_USER")
	PASSWORD = os.getenv("DB_PASSWORD")
	HOST = os.getenv("DB_HOST")
	PORT = os.getenv("DB_PORT")
	DB_NAME = os.getenv("DB_NAME")

	if USER and PASSWORD and HOST and PORT and DB_NAME:
		connection_str = (
			f"postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB_NAME}"
		)
	else:
		print("Errore: .env is not configured correctly --> connection_str contains None values")
		raise SystemExit(1)

	print(f"connectrion_str = {connection_str}")

	# mi assicuro che bronze esista, e ese non esiste lo creo
	schema_name = "bronze"
	with engine.connect() as conn:
		conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
		conn.commit()

	engine = create_engine(connection_str)

	# mi assicuro che bronze esista, e ese non esiste lo creo
	schema_name = "bronze"
	with engine.connect() as conn:
		conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
		conn.commit()

	df = pd.DataFrame(table, columns=columns)

	df.to_sql(
		"bollettino",
		engine,
		schema="bronze",
		if_exists="replace",
		index=False
	)
