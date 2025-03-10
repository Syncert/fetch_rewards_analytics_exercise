CREATE TABLE IF NOT EXISTS raw_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    raw_json TEXT NOT NULL,
    file_name TEXT NOT NULL,
    load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS silver_receipts (
    receipt_id TEXT PRIMARY KEY,
    user_id TEXT,
    total_spent DECIMAL(10,2),
    points_earned INTEGER,
    bonus_points INTEGER,
    purchase_date DATETIME,
    create_date DATETIME,
    date_scanned DATETIME,
    finished_date DATETIME,
    modify_date DATETIME,
    points_awarded_date DATETIME,
    purchased_item_count INTEGER,
    rewards_receipt_status TEXT
);

CREATE TABLE IF NOT EXISTS silver_receipt_items (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    receipt_id TEXT,
    barcode TEXT,
    description TEXT,
    final_price DECIMAL(10,2),
    item_price DECIMAL(10,2),
    quantity_purchased INTEGER,
    user_flagged_price DECIMAL(10,2),
    FOREIGN KEY (receipt_id) REFERENCES silver_receipts(receipt_id)
);

CREATE TABLE IF NOT EXISTS silver_users (
    user_id TEXT PRIMARY KEY,
    state TEXT,
    created_date DATETIME,
    last_login DATETIME,
    role TEXT,
    active BOOLEAN
);

CREATE TABLE IF NOT EXISTS silver_brands (
    brand_id TEXT PRIMARY KEY,
    barcode TEXT,
    brand_code TEXT,
    category TEXT,
    category_code TEXT,
    cpg TEXT,
    top_brand BOOLEAN,
    name TEXT
);