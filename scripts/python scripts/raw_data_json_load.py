import sqlite3
import json
import os
from datetime import datetime

def insert_raw_data(file_path, db_path):
    """Insert NDJSON/JSONL file into the raw_data table in SQLite with filename and timestamp."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Extract filename from file_path
    file_name = os.path.basename(file_path)
    load_timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")  # UTC timestamp

    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue  # Skip empty lines
            
            try:
                data = json.loads(line)  # Parse JSON object
                cursor.execute(
                    "INSERT INTO raw_data (raw_json, file_name, load_timestamp) VALUES (?, ?, ?)",
                    (json.dumps(data), file_name, load_timestamp)
                )
            except json.JSONDecodeError as e:
                print(f"Skipping invalid JSON line in {file_name}: {line}")
                print(f"Error: {e}")

    conn.commit()
    conn.close()

# Define directory containing JSON files
raw_dir = os.path.abspath("../../json_data")
#Define path to db
db_path = os.path.abspath("../../sqlite_db/fetch.db")

# Iterate through each JSON file in the directory
for json_file in os.listdir(raw_dir):
    if json_file.endswith(".json"):
        full_path = os.path.join(raw_dir, json_file)
        print(f"Loading {full_path}...")
        insert_raw_data(full_path,db_path)
        print(f"Done loading {full_path}...")