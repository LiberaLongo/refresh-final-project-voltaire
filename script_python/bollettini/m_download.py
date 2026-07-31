#!/usr/bin/env python3
import logging
import json
import requests
import time
from urllib.parse import parse_qs, urlparse
from m_filename import create_name

def download(day):
	logging.info(f"day = {day}")
	day_url = str(day).replace("-", "")
	logging.info(f"day_url = {day_url}")
	url = f"https://apps.arpae.it/REST/bollettini_qa/{day_url}"

	response = requests.get(url)
	response.raise_for_status()  # Raises an exception for HTTP errors
	my_json = response.json()  # converte il JSON in dict/list Python

	# formatto il json come voglio io
	formattazione_documento = json.dumps(my_json, indent=4, ensure_ascii=False)

	output_file = create_name(day)

	with open(output_file, "w", encoding="utf-8") as f:
		f.write(formattazione_documento)
		f.write('\n')
