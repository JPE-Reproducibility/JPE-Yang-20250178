import pandas as pd
import os
import numpy as np
from tqdm import tqdm  # Add progress bar library
import multiprocessing as mp

# -------------------- CONFIG --------------------
# Adjust the number of cores you want to use for parallel processing.
NUM_CORES = 8
# folder_path = "PATH_TO_SIMILARITY_SCRATCH"
# pbcompanies_path = "PATH_TO_EXTERNAL_DRIVE/pbcompanies.csv"
# output_path = "PATH_TO_SIMILARITY_SCRATCH_output" 
ENT_ROOT = os.environ.get("EXPENSIVE_ML_ROOT", "PATH_TO_ENTTEMPLATES_DATA_ROOT")
folder_path = os.path.join(ENT_ROOT, "Analysis/python_Similarity/output")
pbcompanies_path = os.path.join(ENT_ROOT, "Analysis/Stata/invariant_data/pbcompanies.dta")
west_flag_path = os.path.join(ENT_ROOT, "Analysis/Stata/invariant_data/company_china_western_or_not.dta")

output_path = os.path.join(ENT_ROOT, "Analysis/python_Similarity/processed_western")

pbcompanies = (
    pd.read_stata(pbcompanies_path)
    .merge(pd.read_stata(west_flag_path), on="companyid", how="left")
)
pbcompanies = pbcompanies[['companyid', 'any_deal_western', 'hqcountry', 'yearfounded', 'firstfinancingdate']]
# Filter out US companies
pbcompanies = pbcompanies[pbcompanies['hqcountry'] != 'United States']

# Prepare percentiles
percentiles = {'1st': 0.01, '5th': 0.05, '10th': 0.1, '25th': 0.25}

# ------------------------------------------------
# Core processing logic wrapped into a function so it can be
# executed in parallel by multiple worker processes.
# ------------------------------------------------


def percentile_1(x):
    return np.percentile(x, 99)


def percentile_5(x):
    return np.percentile(x, 95)


def percentile_10(x):
    return np.percentile(x, 90)


def percentile_25(x):
    return np.percentile(x, 75)


def process_file(filename: str):
    """Process one similarity CSV and write processed output."""
    try:
        # Determine output filename first and skip if it already exists
        output_filename = filename.split(".")[0] + "_processed_western.csv"
        output_filepath = os.path.join(output_path, output_filename)

        if os.path.exists(output_filepath):
            print(f"Skip {filename}: processed file already exists → {output_filename}")
            return  # Skip further processing

        file_path = os.path.join(folder_path, filename)
        data = pd.read_csv(file_path, index_col=False)

        # Merge pbcompanies for company 1
        merged1 = (
            data.merge(
                pbcompanies,
                left_on="companyid1",
                right_on="companyid",
                how="left",
            )
            .rename(
                columns={
                    "hqcountry": "hqcountry1",
                    "yearfounded": "yearfounded1",
                    "firstfinancingdate": "firstfinancingdate1",
                    "any_deal_western": "any_deal_western1",
                }
            )
            .drop("companyid", axis=1)
        )

        # Merge pbcompanies for company 2
        data = (
            merged1.merge(
                pbcompanies,
                left_on="companyid2",
                right_on="companyid",
                how="left",
            )
            .rename(
                columns={
                    "hqcountry": "hqcountry2",
                    "yearfounded": "yearfounded2",
                    "firstfinancingdate": "firstfinancingdate2",
                    "any_deal_western": "any_deal_western2",
                }
            )
            .drop("companyid", axis=1)
        )

        # --------------------------------------------
        #  Copy the remaining transformation and aggregation logic
        # --------------------------------------------
        df = data.copy()

        target_countries = ["China"]

        mask_drop = df["hqcountry1"].isin(target_countries) & df["hqcountry2"].isin(
            target_countries
        )
        df = df[~mask_drop]

        mask_drop_neither = ~df["hqcountry1"].isin(target_countries) & ~df[
            "hqcountry2"
        ].isin(target_countries)

        df = df[~mask_drop_neither]

        mask_swap = df["hqcountry1"].isin(target_countries) & ~df[
            "hqcountry2"
        ].isin(target_countries)

        df.loc[mask_swap, ["companyid1", "companyid2"]] = df.loc[
            mask_swap, ["companyid2", "companyid1"]
        ].values
        df.loc[mask_swap, ["fullname1", "fullname2"]] = df.loc[
            mask_swap, ["fullname2", "fullname1"]
        ].values
        df.loc[mask_swap, ["hqcountry1", "hqcountry2"]] = df.loc[
            mask_swap, ["hqcountry2", "hqcountry1"]
        ].values
        df.loc[mask_swap, ["yearfounded1", "yearfounded2"]] = df.loc[
            mask_swap, ["yearfounded2", "yearfounded1"]
        ].values
        df.loc[mask_swap, ["firstfinancingdate1", "firstfinancingdate2"]] = df.loc[
            mask_swap, ["firstfinancingdate2", "firstfinancingdate1"]
        ].values
        df.loc[mask_swap, ["any_deal_western1", "any_deal_western2"]] = df.loc[
            mask_swap, ["any_deal_western2", "any_deal_western1"]
        ].values


        # --- Afteronly filter ---
        df = df[df['yearfounded1'] > df['yearfounded2']]

        df = df.sort_values(by="companyid1")

        # Task 1: Calculate similarity statistics with respect to WESTERN Chinese companies
        df_western = df[(df["hqcountry2"] == "China") & (df["any_deal_western2"] == 1)]
        df_nonwestern = df[(df["hqcountry2"] == "China") & (df["any_deal_western2"] == 0)]

        df_western_grouped = (
            df_western.groupby("companyid1")["similarity"]
            .agg(["mean", "max", percentile_1, percentile_5, percentile_10, percentile_25])
            .reset_index()
        )
        df_western_grouped.columns = [
            "companyid1",
            "cn_west_afteronly_similarity_mean",
            "cn_west_afteronly_similarity_max",
            "cn_west_afteronly_similarity_1%",
            "cn_west_afteronly_similarity_5%",
            "cn_west_afteronly_similarity_10%",
            "cn_west_afteronly_similarity_25%",
        ]

        df_nonwestern_grouped = (
            df_nonwestern.groupby("companyid1")["similarity"]
            .agg(["mean", "max", percentile_1, percentile_5, percentile_10, percentile_25])
            .reset_index()
        )
        df_nonwestern_grouped.columns = [
            "companyid1",
            "cn_nonwest_afteronly_similarity_mean",
            "cn_nonwest_afteronly_similarity_max",
            "cn_nonwest_afteronly_similarity_1%",
            "cn_nonwest_afteronly_similarity_5%",
            "cn_nonwest_afteronly_similarity_10%",
            "cn_nonwest_afteronly_similarity_25%",
        ]

        df_final = pd.merge(
            df_western_grouped, df_nonwestern_grouped, on="companyid1", how="outer"
        )

        # Save results
        df_final.to_csv(output_filepath, index=False)
        print(f"Finished, file saved to {output_filepath}")
    except Exception as e:
        print(f"Error processing {filename}: {e}")


# ------------------------------------------------
# Execute in parallel across all sector files
# ------------------------------------------------


if __name__ == "__main__":
    files = [f for f in os.listdir(folder_path) if f.endswith(".csv")]

    print(f"Processing {len(files)} files using {NUM_CORES} cores ...")

    with mp.Pool(processes=NUM_CORES) as pool:
        list(tqdm(pool.imap_unordered(process_file, files), total=len(files)))