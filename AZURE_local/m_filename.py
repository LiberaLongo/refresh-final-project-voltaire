import logging
import os
from dotenv import load_dotenv
from pathlib import Path

def get_folder():
	load_dotenv(".env")
	return os.getenv("DOWNLOAD_FOLDER")

def create_name(day):
	folder = get_folder()
	# scelgo il nome del file del bollettino
	name_file = "bollettino_" + str(day)

	# stringa path
	path = f"{folder}/{name_file}.json"
	logging.info(f"path_bollettino = {path}")
	return Path(path)

def get_name(date):
	folder = get_folder()
	return Path(f"{folder}bollettino_{date}.json")
