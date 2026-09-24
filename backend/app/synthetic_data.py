import pandas as pd
import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker()

# Define vendor templates based on "mpesa_statements.pdf"
systemic_vendors = [
    "Pay Bill Online to 4076367 - BEECH PROPERTIES LLP Acc. 1617022534",
    "Pay Bill Online to 828169-SPRINGREEN STIMA ACCOUNT Acc. 47001242420",
    "Pay Bill Online to 644028-MOJA EXPRESSWAY CO. LTD",
    "Customer Bundle Purchase to 244441SAFARICOM POSTPAID BUNDLES",
    "Recharge for Customer to 4093441SAFARICOM DATA BUNDLES"
]

discretionary_vendors = [
    "Merchant Payment Online to 7448346-WRAPPED FOODS",
    "Merchant Payment Online to 9120346-SLEEZYS",
    "Merchant Payment Online to 5047995-STRATHMORE UNIVERSITY CATERING",
    "Merchant Payment Online to 6780943 - NAIVAS LANGATA MIDLINK",
    "Merchant Payment Online to 7316094-TERRY CARE SALON & KINYOZI"
]

data = []
for _ in range(5000): # Generate 5,000 synthetic rows
    category = random.choice(["Systemic Lifestyle Costs", "Discretionary Spending"])
    if category == "Systemic Lifestyle Costs":
        details = random.choice(systemic_vendors)
    else:
        details = random.choice(discretionary_vendors)
        
    # Introduce noise (messy text) to simulate real-world variance
    if random.random() > 0.8:
        details = details + " by " + fake.name()
        
    data.append({
        "Receipt": fake.bothify(text='UI?5E6????', letters='ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
        "Details": details,
        "Withdrawn": round(random.uniform(-100, -3000), 2),
        "Category": category
    })

df = pd.DataFrame(data)
df.to_csv("synthetic_mpesa_spendIQ.csv", index=False)
print("Successfully generated 5,000 synthetic records!")
df.head()