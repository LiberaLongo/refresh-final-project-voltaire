#!/usr/bin/env python3
import logging
import json
import sys
from m_filename import get_name
from m_download import download

def add_row_to_table (table, day, info, dict = {}):
	logging.info(info)
	# "prov": "BO",
	provincia = info.get("prov", "NON DISPONIBILE")
	# "idstazione": "7000014",
	id_stazione = info.get("idstazione", "NON DISPONIBILE")
	# "stazione": "GIARDINI MARGHERITA",
	stazione = info.get("stazione", "NON DISPONIBILE")
	# "tipostazione": "Urbana Fondo",
	tipo_stazione = info.get("tipostazione", "NON DISPONIBILE")
	# "pm10": "  10",
	pm10 = info.get("pm10", "NON DISPONIBILE")
	# "pm25": "   6",
	pm25 = info.get("pm25", "NON DISPONIBILE")
	# "no2": "  19",
	no2 = info.get("no2", "NON DISPONIBILE")
	# "o3mediaorariamax": " 113",
	o3_media_oraria_max = info.get("o3mediaorariamax", "NON DISPONIBILE")
	# "o3media8oremax": " 105",
	o3_media_8_ore_max = info.get("o3media8oremax", "NON DISPONIBILE")
	# "benzene": "",
	benzene = info.get("benzene", "NON DISPONIBILE")
	# "co": "",
	co = info.get("co", "NON DISPONIBILE")
	# "so2": "",
	so2 = info.get("so2", "NON DISPONIBILE")
	# "pm10supgiorni": "5",
	pm10_sup_giorni = info.get("pm10supgiorni", "NON DISPONIBILE")
	# "no2supore": "0",
	no2_sup_ore = info.get("no2supore", "NON DISPONIBILE")
	# "o3supore": "0",
	o3_sup_ore = info.get("o3supore", "NON DISPONIBILE")
	# "o3supgiorni": "42"
	tupla = (day, provincia,
			id_stazione, stazione, tipo_stazione,
			pm25, pm10, pm10_sup_giorni,
			o3_media_oraria_max, o3_media_8_ore_max, o3_sup_ore,
			no2, co, benzene, so2, no2_sup_ore)
	table.append(tupla)

	return table

def read(today, table = []):
	logging.info("start - funzione read()")

	logging.info("legge il nome del file da leggere")
	# nome del file da leggere
	file_name = get_name(today)

	try:
		f = open(file_name, "r", encoding="utf-8")
	except FileNotFoundError:
		# download_page(n)
		download(today)
		f = open(file_name, "r", encoding="utf-8")

	logging.info("legge il file ed estrae il json")
	# leggo il file ed estraggo il json
	with f:
		my_json = json.load(f)

	# estraggo le informazioni che mi servono
	# con l'obbiettivo di creare una tabella
	
	province_str = [
		"bo"  # Bologna
		, "fe"  # Ferrara
		, "fc"  # Forli`-Cesena
		, "mo"  # Modena
		, "pr"  # Parma
		, "pc"  # Piacenza
		, "ra"  # Ravenna
		, "re"  # Reggio Emilia
		, "rn"  # Rimini
	]
	#logging.info(f"province = {province_list}")

	# province_str contiene le sigle/nome delle province da cercare
	# (es. ["re", "mo", "bo"]).
	for prov in province_str:

		# Recupera la lista associata alla provincia.
		# Se la provincia non esiste nel dizionario, usa una lista vuota.
		provincia = my_json.get(prov, [])

		# La provincia contiene una LISTA di record.
		# Ogni record è un dizionario con "timestamp", "data", ecc.
		for record in provincia:

			# Estrai il timestamp.
			# Se manca, usa una stringa vuota per evitare errori.
			timestamp = record.get("timestamp", "")
			info_list = record.get("data", {})

			# logging.info(f"timestamp = {timestamp}")
			# logging.info(f"today = {today}")
			# Controlla se il timestamp inizia con una delle date cercate.
			# if timestamp.startswith(str(today)):
			# 	logging.info("timestamp ok")
			for info in info_list:
				table = add_row_to_table(table, timestamp, info)

	# lo carico su dbeaver (azure)

	# in sequito vorremmo vedere gli ultimi 3 giorni

	logging.info("end - funzione read(), ritorna la 'table' popolata")

	return table

def read_all(date, page):
	for n in range (1, page):
		read(date, n)
