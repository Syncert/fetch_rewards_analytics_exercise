import sqlite3
import json
import os
from datetime import datetime

# Define path to the database
db_path = os.path.abspath("../../sqlite_db/fetch.db")

def get_latest_raw_data(cursor, file_name):
    """Fetch the latest JSON records for a given file name based on max load_timestamp."""
    cursor.execute("""
        SELECT raw_json FROM raw_data 
        WHERE file_name = ? 
        AND load_timestamp = (SELECT MAX(load_timestamp) FROM raw_data WHERE file_name = ?)
    """, (file_name, file_name))
    
    return cursor.fetchall()

def extract_oid(data):
    """Extracts the `$oid` field from MongoDB-style `_id` objects."""
    return data.get("$oid") if isinstance(data, dict) and "$oid" in data else data

def extract_date(data):
    """Converts MongoDB `$date` fields (milliseconds since epoch) into standard ISO timestamps."""
    if isinstance(data, dict) and "$date" in data:
        return datetime.utcfromtimestamp(data["$date"] / 1000).strftime("%Y-%m-%d %H:%M:%S")
    return data  # Return as is if not in special format

def build_silver_tables(db_path):
    conn = sqlite3.connect(db_path, timeout=10) # Waits for DB to be unlocked
    cursor = conn.cursor()

    ### Extract Latest Data for Each File ###

    #Logging
    print("Extracting latest data for receipts...")

    ##Process Receipts
    latest_receipts = get_latest_raw_data(cursor, "receipts.json")
    for row in latest_receipts:
        data = json.loads(row[0])  # Convert JSON string to dictionary

        # Extract and normalize data
        receipt_id = extract_oid(data.get("_id"))
        user_id = data.get("userId")
        total_spent = data.get("totalSpent")
        points_earned = data.get("pointsEarned")
        bonus_points = data.get("bonusPointsEarned")
        purchase_date = extract_date(data.get("purchaseDate"))
        create_date = extract_date(data.get("createDate"))
        date_scanned = extract_date(data.get("dateScanned"))
        finished_date = extract_date(data.get("finishedDate"))
        modify_date = extract_date(data.get("modifyDate"))
        points_awarded_date = extract_date(data.get("pointsAwardedDate"))
        purchased_item_count = data.get("purchasedItemCount")
        rewards_receipt_status = data.get("rewardsReceiptStatus")

        # Insert into silver_receipts
        cursor.execute("""
            INSERT OR REPLACE INTO silver_receipts (
                receipt_id, user_id, total_spent, points_earned, bonus_points,
                purchase_date, create_date, date_scanned, finished_date, modify_date,
                points_awarded_date, purchased_item_count, rewards_receipt_status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            receipt_id, user_id, total_spent, points_earned, bonus_points,
            purchase_date, create_date, date_scanned, finished_date, modify_date,
            points_awarded_date, purchased_item_count, rewards_receipt_status
        ))

        ## 🛒 Process Items in `rewardsReceiptItemList`
        items = data.get("rewardsReceiptItemList", [])
        for item in items:
            cursor.execute("""
                INSERT INTO silver_receipt_items (
                    receipt_id, barcode, description, final_price, item_price,
                    quantity_purchased, user_flagged_price
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                receipt_id,
                item.get("barcode"),
                item.get("description"),
                item.get("finalPrice"),
                item.get("itemPrice"),
                item.get("quantityPurchased"),
                item.get("userFlaggedPrice")
            ))

    #Logging
    print("Extracting latest data for Users...")

    ##Process Users
    latest_users = get_latest_raw_data(cursor, "users.json")
    for row in latest_users:
        data = json.loads(row[0])
        cursor.execute("""
            INSERT OR REPLACE INTO silver_users (
                user_id, state, created_date, last_login, role, active
            )
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            extract_oid(data.get("_id")),
            data.get("state"),
            extract_date(data.get("createdDate")),
            extract_date(data.get("lastLogin")),
            data.get("role"),
            data.get("active")
        ))
        
    #Logging
    print("Extracting latest data for brands...")

    ##Process Brands
    latest_brands = get_latest_raw_data(cursor, "brands.json")
    for row in latest_brands:
        data = json.loads(row[0])
        cpg_value = json.dumps(data.get("cpg")) if isinstance(data.get("cpg"), dict) else data.get("cpg")

        cursor.execute("""
            INSERT OR REPLACE INTO silver_brands (
                brand_id, barcode, brand_code, category, category_code, cpg, top_brand, name
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            extract_oid(data.get("_id")),
            data.get("barcode"),
            data.get("brandCode"),
            data.get("category"),
            data.get("categoryCode"),
            cpg_value,
            data.get("topBrand"),
            data.get("name")
        ))

    #Commit changes and close
    conn.commit()
    conn.close()

print(f"Building silver tables in {db_path}...")

# Run the script
build_silver_tables(db_path)
