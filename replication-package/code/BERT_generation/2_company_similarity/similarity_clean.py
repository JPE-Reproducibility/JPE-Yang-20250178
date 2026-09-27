import pandas as pd
import os
import numpy as np
# folder_path = "PATH_TO_EXTERNAL_DRIVE/similarity"
# pbcompanies_path = "PATH_TO_EXTERNAL_DRIVE/pbcompanies.csv"
# output_path = "PATH_TO_EXTERNAL_DRIVE/similarity_output" 

folder_path = r"PATH_TO_SIMILARITY_SCRATCH"
pbcompanies_path = r"PATH_TO_SIMILARITY_SCRATCH/pbcompanies.csv"
output_path = folder_path

pbcompanies = pd.read_csv(pbcompanies_path)
# Prepare percentiles
percentiles = {'10th': 0.1, '25th': 0.25}


# Iterate over files
for filename in os.listdir(folder_path):
    if filename.endswith(".csv"):  # check file extension, adjust if needed
        file_path = os.path.join(folder_path, filename)
        data = pd.read_csv(file_path)
        print('data imported')
        pbcompanies=pbcompanies[['companyid','hqcountry','yearfounded','firstfinancingdate']]
        data = data.merge(pbcompanies, left_on='companyid1', right_on='companyid', how='left').rename(columns={'hqcountry': 'hqcountry1','yearfounded':'yearfounded1','firstfinancingdate':'firstfinancingdate1'}).drop('companyid', axis=1)
        data = data.merge(pbcompanies, left_on='companyid2', right_on='companyid', how='left').rename(columns={'hqcountry': 'hqcountry2','yearfounded':'yearfounded2','firstfinancingdate':'firstfinancingdate2'}).drop('companyid', axis=1)

        print('dataframe is merged')
        # Make a copy of the original dataframe
        df = data.copy()

        # Define the target countries
        target_countries = ["China", "United States"]

        # Drop rows where both countries are either China or the United States
        mask_drop = df['hqcountry1'].isin(target_countries) & df['hqcountry2'].isin(target_countries)
        df = df[~mask_drop]

        # Drop rows where neither 'hqcountry1' nor 'hqcountry2' is China or the United States
        mask_drop_neither = ~df['hqcountry1'].isin(target_countries) & ~df['hqcountry2'].isin(target_countries)
        df = df[~mask_drop_neither]

        # Swap values if 'hqcountry1' is US or China and 'hqcountry2' is not US or China
        mask_swap = df['hqcountry1'].isin(target_countries) & ~df['hqcountry2'].isin(target_countries)

        df.loc[mask_swap, ['companyid1', 'companyid2']] = df.loc[mask_swap, ['companyid2', 'companyid1']].values
        df.loc[mask_swap, ['fullname1', 'fullname2']] = df.loc[mask_swap, ['fullname2', 'fullname1']].values
        df.loc[mask_swap, ['hqcountry1', 'hqcountry2']] = df.loc[mask_swap, ['hqcountry2', 'hqcountry1']].values
        df.loc[mask_swap, ['yearfounded1', 'yearfounded2']] = df.loc[mask_swap, ['yearfounded2', 'yearfounded1']].values
        df.loc[mask_swap, ['firstfinancingdate1', 'firstfinancingdate2']] = df.loc[mask_swap, ['firstfinancingdate2', 'firstfinancingdate1']].values

        print('data filtered')
        df = df.sort_values(by='companyid1')


        # Task 1: Calculate average, 10%, 25% similarity for each 'companyid1' with all Chinese and US companies

        # Filter for Chinese and US companies
        df_china = df[df['hqcountry2'] == 'China']
        df_us = df[df['hqcountry2'] == 'United States']

        # Define function for 10% and 25% percentile
        def percentile_10(x):
            return np.percentile(x, 90)
        def percentile_25(x):
            return np.percentile(x, 75)

        # Calculate metrics for Chinese companies
        df_china_grouped = df_china.groupby('companyid1')['similarity'].agg(['mean', percentile_10, percentile_25]).reset_index()
        df_china_grouped.columns = ['companyid1', 'china_similarity_mean', 'china_similarity_10%', 'china_similarity_25%']

        # Calculate metrics for US companies
        df_us_grouped = df_us.groupby('companyid1')['similarity'].agg(['mean', percentile_10, percentile_25]).reset_index()
        df_us_grouped.columns = ['companyid1', 'us_similarity_mean', 'us_similarity_10%', 'us_similarity_25%']

        # Merge the Chinese and US metrics together
        df_grouped = pd.merge(df_china_grouped, df_us_grouped, on='companyid1', how='outer')

        print('task 1 finished')
        # Task 2: Consider only pairs where 'yearfounded1' is larger than 'yearfounded2'

        # Filter DataFrame
        df_afteronly = df[df['yearfounded1'] > df['yearfounded2']]

        # Calculate metrics for Chinese companies
        df_china_grouped_afteronly = df_afteronly[df_afteronly['hqcountry2'] == 'China'].groupby('companyid1')['similarity'].agg(['mean', percentile_10, percentile_25]).reset_index()
        df_china_grouped_afteronly.columns = ['companyid1', 'china_similarity_mean_afteronly', 'china_similarity_10%_afteronly', 'china_similarity_25%_afteronly']

        # Calculate metrics for US companies
        df_us_grouped_afteronly = df_afteronly[df_afteronly['hqcountry2'] == 'United States'].groupby('companyid1')['similarity'].agg(['mean', percentile_10, percentile_25]).reset_index()
        df_us_grouped_afteronly.columns = ['companyid1', 'us_similarity_mean_afteronly', 'us_similarity_10%_afteronly', 'us_similarity_25%_afteronly']

        # Merge the Chinese and US metrics together
        df_grouped_afteronly = pd.merge(df_china_grouped_afteronly, df_us_grouped_afteronly, on='companyid1', how='outer')

        print('task 2 finished')
        # Finally merge both dataframes (task 1 and task 2) together
        df_final = pd.merge(df_grouped, df_grouped_afteronly, on='companyid1', how='outer')

        print('final data compiled')
        # Save to CSV
        output_filename = filename.split('.')[0] + '_processed.csv'
        df_final.to_csv(os.path.join(output_path, output_filename))
        print('finished')