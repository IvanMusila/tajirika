
# forecast_utils.py — shared between Colab (training) and FastAPI (serving).
# DO NOT edit one copy without updating the other.

import warnings, json, joblib
import numpy as np
import pandas as pd
from pathlib import Path
from prophet import Prophet

warnings.filterwarnings('ignore')

MIN_WEEKS_FOR_PROPHET = 8
RENT_THRESHOLD        = 8000
SAVINGS_TYPES         = {'savings_deposit'}

def build_daily_series(df, exclude_types=None):
    if exclude_types is None:
        exclude_types = SAVINGS_TYPES
    spend = df[
        df['is_debit'] &
        ~df['transaction_type'].isin(exclude_types)
    ].copy()
    spend['date'] = pd.to_datetime(spend['timestamp']).dt.date
    daily = (spend.groupby('date')['amount'].sum()
                  .reset_index()
                  .rename(columns={'date': 'ds', 'amount': 'y'}))
    daily['ds'] = pd.to_datetime(daily['ds'])
    full_range = pd.date_range(daily['ds'].min(), daily['ds'].max(), freq='D')
    daily = (daily.set_index('ds')
                  .reindex(full_range, fill_value=0)
                  .rename_axis('ds')
                  .reset_index())
    return daily

def split_large_payments(df, threshold=RENT_THRESHOLD):
    # Step 1: remove savings entirely from spend
    spend_df = df[
        df['is_debit'] &
        ~df['transaction_type'].isin(SAVINGS_TYPES)
    ].copy()
    # Step 2: any single payment >= threshold leaves the daily series,
    # regardless of category (handles Absa 140k, Cisco 45k, one-off large sends)
    is_large = spend_df['amount'] >= threshold
    return spend_df[~is_large].copy(), spend_df[is_large].copy()

def monthly_large_avg(large_df):
    if large_df.empty:
        return 0.0
    large_df = large_df.copy()
    # Only count non-invisible merchants that recur >= 2 times (i.e. rent)
    # Drops one-off large payments like Absa 140k and Cisco 45k
    recurring = large_df[
        ~large_df['category'].isin(['invisible'])
    ].groupby('merchant_id').filter(lambda x: len(x) >= 2)
    if recurring.empty:
        return 0.0
    recurring['month'] = pd.to_datetime(recurring['timestamp']).dt.to_period('M')
    return recurring.groupby('month')['amount'].sum().median()

def cold_start_summary(df, balance):
    daily = build_daily_series(df)
    if daily.empty or daily['y'].sum() == 0:
        return {'method': 'cold_start', 'runway_days': None,
                'daily_avg': 0, 'monthly_forecast': 0,
                'forecast_df': None, 'model': None,
                'message': 'No spend history yet.'}
    daily_avg = daily['y'].mean()
    runway    = int(balance / daily_avg) if daily_avg > 0 else 999
    return {
        'method':           'cold_start',
        'runway_days':      runway,
        'daily_avg':        round(daily_avg, 2),
        'monthly_forecast': round(daily_avg * 30, 2),
        'forecast_df':      None,
        'model':            None,
        'message':          f'Using trailing average ({len(daily)} days of history).',
    }

def fit_prophet(daily_df):
    m = Prophet(
        weekly_seasonality=True,
        yearly_seasonality=True,
        daily_seasonality=False,
        seasonality_mode='multiplicative',
        changepoint_prior_scale=0.01,
        changepoint_range=0.95,   
        seasonality_prior_scale=10,
    )
    m.add_seasonality(name='monthly', period=30.5, fourier_order=5)
    m.fit(daily_df)
    return m

def make_forecast(model, periods=30):
    future   = model.make_future_dataframe(periods=periods, freq='D')
    forecast = model.predict(future)
    return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].copy()

def compute_runway(balance, forecast_df, large_monthly_avg=0):
    daily_large = large_monthly_avg / 30
    cum = 0.0
    for i, row in enumerate(forecast_df.itertuples()):
        daily = max(float(row.yhat), 0) + daily_large
        cum  += daily
        if cum >= balance:
            return i + 1
    avg_daily = max(forecast_df['yhat'].clip(lower=0).mean(), 1)
    return int(balance / avg_daily)

def what_if(balance, forecast_df, tx_df, category, reduce_pct, large_monthly_avg=0):
    spend = tx_df[
        tx_df['is_debit'] &
        ~tx_df['transaction_type'].isin(SAVINGS_TYPES)
    ]
    if spend.empty or spend['amount'].sum() == 0:
        return compute_runway(balance, forecast_df, large_monthly_avg), 0
    cat_share = (
        spend[spend['category'] == category]['amount'].sum() /
        spend['amount'].sum()
    )
    reduction_factor = cat_share * (reduce_pct / 100)
    adj = forecast_df.copy()
    adj['yhat']       = adj['yhat']       * (1 - reduction_factor)
    adj['yhat_lower'] = adj['yhat_lower'] * (1 - reduction_factor)
    adj['yhat_upper'] = adj['yhat_upper'] * (1 - reduction_factor)
    new_runway = compute_runway(balance, adj, large_monthly_avg)
    monthly_forecast = max(forecast_df['yhat'].clip(lower=0).sum(), 0)
    saved_ksh = monthly_forecast * cat_share * (reduce_pct / 100)
    return new_runway, round(saved_ksh, 2)

def fit_user_forecast(df, balance, user_id='user'):
    regular_df, large_df = split_large_payments(df)

    # Exclude loan repayments and invisible transactions from the forecast series.
    # These are lumpy and unpredictable (Fuliza spikes, bank transfers).
    # Their monthly average is added back as a fixed daily cost in runway calc.
    forecast_df = regular_df[
        ~regular_df['transaction_type'].isin({'loan_repayment'}) &
        ~regular_df['category'].isin({'invisible'})
    ].copy()
    daily = build_daily_series(forecast_df)

    # Invisible + loan monthly avg (spread as fixed daily cost alongside rent)
    invis_monthly = regular_df[
        regular_df['transaction_type'].isin({'loan_repayment'}) |
        regular_df['category'].isin({'invisible'})
    ].copy()
    invis_monthly['month'] = pd.to_datetime(invis_monthly['timestamp']).dt.to_period('M')
    invisible_monthly_avg = float(invis_monthly.groupby('month')['amount'].sum().median())

    large_monthly = monthly_large_avg(large_df)
    total_fixed_monthly = large_monthly + invisible_monthly_avg
    model    = fit_prophet(daily)
    forecast = make_forecast(model, periods=30)
    runway   = compute_runway(balance, forecast.tail(30), total_fixed_monthly)
    daily_avg = max(forecast.tail(30)['yhat'].clip(lower=0).mean(), 0)
    monthly   = round(daily_avg * 30 + total_fixed_monthly, 2)

    return {
        'method':                'prophet',
        'runway_days':           runway,
        'daily_avg':             round(daily_avg, 2),
        'monthly_forecast':      monthly,
        'large_monthly_avg':     round(large_monthly, 2),
        'invisible_monthly_avg': round(invisible_monthly_avg, 2),
        'forecast_df':           forecast,
        'model':                 model,
        'message':               f'Prophet fitted on {len(daily)} days of history.',
        'user_id':               user_id,
    }
