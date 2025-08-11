import os
import shutil
from pathlib import Path
import zipfile
import pandas as pd
import subprocess  # for running shell commands in Python

# -----------------------
# Kaggle API setup
# -----------------------
# Path to kaggle.json (download from Kaggle account settings)
local_kaggle_json = Path.home() / "Downloads" / "kaggle.json"

# Create ~/.kaggle directory
kaggle_dir = Path.home() / ".kaggle"
kaggle_dir.mkdir(exist_ok=True)

# Copy kaggle.json to ~/.kaggle
shutil.copy(local_kaggle_json, kaggle_dir / "kaggle.json")

# Set file permissions
os.chmod(kaggle_dir / "kaggle.json", 0o600)

# -----------------------
# Download dataset
# -----------------------
subprocess.run([
    "kaggle", "datasets", "download", "ankitbansal06/retail-orders"
])

# -----------------------
# Unzip dataset
# -----------------------
with zipfile.ZipFile("retail-orders.zip", "r") as zip_ref:
    zip_ref.extractall(".")  # Extracts into current directory

# -----------------------
# Load and clean data
# -----------------------
df = pd.read_csv("orders.csv", na_values=['Not Available', 'unknown'])

# Standardize column names
df.columns = df.columns.str.lower()
df.columns = df.columns.str.replace(' ', '_')

# Create profit column
df['discount'] = (df['list_price']*df['discount_percent'])/100
df['sale_price'] = df['list_price']-df['discount']
df['profit'] = df['sale_price'] - df['cost_price']

# Convert date column
df['order_date'] = pd.to_datetime(df['order_date'], format="%Y-%m-%d")

# Drop unused columns
df.drop(columns=['list_price', 'cost_price', 'discount_percent'], inplace=True)

import mysql.connector
from sqlalchemy import create_engine

# MySQL database connection details
user = "root"         # your MySQL username
password = "k4a7t13"  # your MySQL password
host = "localhost"    # or IP address of your MySQL server
database = "retail_db" # database name

# Create SQLAlchemy engine
engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}/{database}")

# Export DataFrame to MySQL table
df.to_sql("df_orders", con=engine, if_exists="append", index=False)

