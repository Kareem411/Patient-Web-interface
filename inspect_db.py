import sqlite3
import os

db_path = "project/instance/patient.db"

if os.path.exists(db_path):
    print(f"Database file exists: {db_path}")
    print(f"File size: {os.path.getsize(db_path)} bytes")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get all tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print(f"Tables: {tables}")
        
        if tables:
            # Check Patient table structure
            cursor.execute("PRAGMA table_info(Patient);")
            columns = cursor.fetchall()
            print(f"Patient table structure: {columns}")
            
            # Count records
            cursor.execute("SELECT COUNT(*) FROM Patient;")
            count = cursor.fetchone()[0]
            print(f"Number of patient records: {count}")
            
            if count > 0:
                # Show first few records (without passwords for security)
                cursor.execute("SELECT NID, username, mail, Fname, Lname, BD FROM Patient LIMIT 5;")
                records = cursor.fetchall()
                print(f"Sample records (first 5): {records}")
        
        conn.close()
        print("Database inspection completed successfully")
        
    except Exception as e:
        print(f"Error inspecting database: {e}")
else:
    print(f"Database file does not exist: {db_path}")
