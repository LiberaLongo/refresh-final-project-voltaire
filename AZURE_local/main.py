#!/usr/bin/env python3
import logging
from m_read import read
from m_upload_db import import_to_db

import datetime;

def my_main():
	# premessa: oggi otteniamo i dati di ieri

	# oggi
	today = datetime.date.today()
	# i 3 giorni precedenti
	yesterday		= today - datetime.timedelta(days=1)
	two_days_ago	= today - datetime.timedelta(days=2)
	three_days_ago	= today - datetime.timedelta(days=3)

	array_of_days = [
			yesterday,
			two_days_ago,
			three_days_ago
		]

	logging.info(f"days: {array_of_days} - definizione array giorni")

	logging.info("start - lettura dei json e popolamento della tabella")
	#tabella vuota
	table = []
	for day in array_of_days:
		# popolo la tabella con i dati presi dai json
		table = read(day, table)
	logging.info("end - lettura dei json e popolamento della tabella")

	logging.info("table = [")
	for i in table:
		logging.info(f"\t{i} ,")
	logging.info("]")

	# specifico come chiamare le colonne
	columns = [
		"timestamp", "provincia",
		"id_stazione", "stazione", "tipo_stazione",
		"pm25", "pm10", "pm10_sup_giorni",
		"o3_media_oraria_max", "o3_media_8_ore_max", "o3_sup_ore",
		"no2", "co", "c6h6", "so2", "no2_sup_ore"
	]

	# importo la tabella su postgres
	import_to_db(table, columns)
