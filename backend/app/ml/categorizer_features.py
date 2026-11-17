
import numpy as np
import pandas as pd

# Types whose category is fixed. No ML needed.
RULE_TYPES = {
    'fee':             'invisible',
    'loan_repayment':  'invisible',
    'savings_deposit': 'invisible',
    'airtime':         'convenience',
    'data_bundle':     'convenience',
    'withdrawal':      'necessity',
}

def make_features(df):
    # Text = merchant name + transaction type (+ a flag if paid as a small business)
    name = df['merchant_name'].fillna('').astype(str).str.lower()
    ttype = df['transaction_type'].fillna('').astype(str)
    smallbiz = df['details'].fillna('').astype(str).str.contains(
        'Small Business|Micro SME', case=False, regex=True)
    out = pd.DataFrame(index=df.index)
    out['text'] = name + ' ' + ttype + np.where(smallbiz, ' smallbiz', '')
    out['log_amount'] = np.log1p(df['amount'].astype(float))
    return out[['text', 'log_amount']]

def categorize(df, model, threshold=0.6):
    # Rules first, model for the rest. Returns category, confidence, source, needs_review.
    res = pd.DataFrame(index=df.index)
    res['category'] = None
    res['confidence'] = np.nan
    res['source'] = None

    rule_mask = df['transaction_type'].isin(RULE_TYPES)
    res.loc[rule_mask, 'category'] = df.loc[rule_mask, 'transaction_type'].map(RULE_TYPES)
    res.loc[rule_mask, 'confidence'] = 1.0
    res.loc[rule_mask, 'source'] = 'rule'

    ml_mask = ~rule_mask
    if ml_mask.any():
        proba = model.predict_proba(make_features(df[ml_mask]))
        res.loc[ml_mask, 'category'] = model.classes_[proba.argmax(axis=1)]
        res.loc[ml_mask, 'confidence'] = proba.max(axis=1)
        res.loc[ml_mask, 'source'] = 'model'

    res['needs_review'] = (res['source'] == 'model') & (res['confidence'] < threshold)
    return res
