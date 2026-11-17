import pandas as pd
import requests

# ── Change this path to where you downloaded the CSV ──────────────────────
CSV_PATH = r"C:\Development\transactions_labeled.csv"
DEVICE_TOKEN = "demo-ivan"
API_URL = "http://localhost:8000"

# ── Step 1: Register ───────────────────────────────────────────────────────
r = requests.post(f"{API_URL}/users/register",
                  json={"device_token": DEVICE_TOKEN})
print("Register:", r.status_code, r.json())

# ── Step 2: Load CSV ───────────────────────────────────────────────────────
df = pd.read_csv(CSV_PATH)
print(f"CSV loaded: {len(df)} rows")
print("Columns:", df.columns.tolist())

debit = df[df["is_debit"] == True].copy()
debit["timestamp"] = pd.to_datetime(debit["timestamp"]).dt.strftime("%Y-%m-%dT%H:%M:%S")
debit = debit.fillna("")

batch = []
for _, row in debit.iterrows():
    batch.append({
        "receipt_no":       str(row["receipt_no"]),
        "timestamp":        str(row["timestamp"]),
        "merchant_name":    str(row["merchant_name"]),
        "merchant_id":      str(row["merchant_id"]),
        "transaction_type": str(row["transaction_type"]),
        "amount":           float(row["amount"]),
        "balance_after":    float(row["balance"]),
        "is_debit":         bool(row["is_debit"]),
        "details":          str(row["details"]),
    })

print(f"Rows to sync: {len(batch)}")

# ── Step 3: Sync in chunks of 200 ─────────────────────────────────────────
for i in range(0, len(batch), 200):
    chunk = batch[i:i + 200]
    r = requests.post(f"{API_URL}/transactions/sync",
                      json={"device_token": DEVICE_TOKEN, "transactions": chunk})
    if r.status_code == 200:
        d = r.json()
        print(f"Chunk {i // 200 + 1}: synced={d['synced']} skipped={d['skipped']}")
    else:
        print(f"Chunk {i // 200 + 1} ERROR {r.status_code}: {r.text[:300]}")
        break

print("Done.")