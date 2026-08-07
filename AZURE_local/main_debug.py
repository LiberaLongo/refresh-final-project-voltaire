#!/usr/bin/env python3

import logging
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
import pandas as pd

def my_main_debug():
	HOST = os.getenv("DB_HOST")
	PORT = os.getenv("DB_PORT")
	DB_NAME = os.getenv("DB_NAME")
	USER = os.getenv("DB_USER")
	PASSWORD = os.getenv("DB_PASSWORD")

	logging.info(f"DB_HOST = {HOST}")
	return HOST


