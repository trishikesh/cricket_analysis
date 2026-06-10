import os
import re
from pathlib import Path

import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
from dotenv import load_dotenv

# =========================
# PATHS / ENV
# =========================
BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

DATA_DIR = BASE_DIR / "ds"

# =========================
# CONFIG
# =========================
SNOWFLAKE_CONFIG = {
    "user": os.getenv("SNOWFLAKE_USER"),
    "password": os.getenv("SNOWFLAKE_PASSWORD"),
    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE", "CRICKET_WH"),
    "database": os.getenv("SNOWFLAKE_DATABASE", "CRICKET_ANALYTICS"),
    "schema": os.getenv("SNOWFLAKE_SCHEMA", "STAGING"),
    "role": os.getenv("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
}


# =========================
# HELPERS
# =========================
def validate_config():
    required = ["user", "password", "account", "warehouse", "database", "schema"]
    missing = [k for k in required if not SNOWFLAKE_CONFIG.get(k)]
    if missing:
        raise ValueError(f"Missing Snowflake config values in .env: {missing}")


def clean_name(name: str) -> str:
    name = str(name).strip().upper()
    name = re.sub(r"[^A-Z0-9]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    if not name:
        name = "COL"
    if name[0].isdigit():
        name = f"COL_{name}"
    return name


def make_unique_columns(columns):
    seen = {}
    result = []

    for col in columns:
        if col not in seen:
            seen[col] = 0
            result.append(col)
        else:
            seen[col] += 1
            result.append(f"{col}_{seen[col]}")
    return result


def preprocess_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    df.columns = [clean_name(col) for col in df.columns]
    df.columns = make_unique_columns(df.columns)

    df = df.dropna(how="all").copy()
    df = df.where(pd.notnull(df), None)

    # write_pandas works more reliably with a clean RangeIndex
    df = df.reset_index(drop=True)

    return df


def infer_snowflake_type(series: pd.Series) -> str:
    if pd.api.types.is_integer_dtype(series):
        return "NUMBER"
    elif pd.api.types.is_float_dtype(series):
        return "FLOAT"
    elif pd.api.types.is_bool_dtype(series):
        return "BOOLEAN"
    elif pd.api.types.is_datetime64_any_dtype(series):
        return "TIMESTAMP_NTZ"
    else:
        return "TEXT"


def build_create_table_sql(table_name: str, df: pd.DataFrame) -> str:
    columns_sql = []
    for col in df.columns:
        columns_sql.append(f'"{col}" {infer_snowflake_type(df[col])}')
    return f'CREATE OR REPLACE TABLE "{table_name}" ({", ".join(columns_sql)})'


def read_csv_safely(file_path: Path) -> pd.DataFrame:
    for encoding in ["utf-8", "utf-8-sig", "cp1252", "latin1"]:
        try:
            return pd.read_csv(file_path, encoding=encoding)
        except UnicodeDecodeError:
            pass

    raise ValueError(f"Unable to read file: {file_path.name}")


# =========================
# MAIN
# =========================
def main():
    validate_config()

    if not DATA_DIR.exists():
        raise FileNotFoundError(f"Data folder not found: {DATA_DIR}")

    csv_files = sorted(DATA_DIR.glob("*.csv"))
    if not csv_files:
        print(f"No CSV files found in {DATA_DIR}")
        return

    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    cursor = conn.cursor()

    try:
        cursor.execute(f'USE WAREHOUSE {SNOWFLAKE_CONFIG["warehouse"]}')
        cursor.execute(f'USE DATABASE {SNOWFLAKE_CONFIG["database"]}')
        cursor.execute(f'USE SCHEMA {SNOWFLAKE_CONFIG["schema"]}')

        for file_path in csv_files:
            print(f"Processing {file_path.name}...")

            try:
                df = read_csv_safely(file_path)

                if df.empty:
                    print(f"Skipping {file_path.name}: empty file")
                    continue

                df = preprocess_dataframe(df)
                table_name = clean_name(file_path.stem)

                cursor.execute(build_create_table_sql(table_name, df))

                success, nchunks, nrows, _ = write_pandas(
                    conn=conn,
                    df=df,
                    table_name=table_name,
                    database=SNOWFLAKE_CONFIG["database"],
                    schema=SNOWFLAKE_CONFIG["schema"],
                    auto_create_table=False,
                    overwrite=True,
                    quote_identifiers=True,
                )

                if success:
                    print(
                        f"Loaded {nrows} rows into "
                        f"{SNOWFLAKE_CONFIG['database']}.{SNOWFLAKE_CONFIG['schema']}.{table_name}"
                    )
                else:
                    print(f"Failed loading {file_path.name}")

            except Exception as e:
                print(f"Error processing {file_path.name}: {e}")

    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    main()