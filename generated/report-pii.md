## Potential Personal Identifiable Information (PII)

⚠️ We found the following instances of potentially personally identifying information. This may be completely legitimate but might be worth checking. *As a reminder, privacy legislation in many countries (e.g. GDPR in EU) prohibits the dissemination of personal identifiable information without prior (and documented) consent of individuals.* If indeed you want to publish such information with your replication package, you should probably have obtained IRB approval for this - please check!

**Summary:**
- Data files with PII indicators: 58
- Variables flagged in data: 437
- Code files with PII references: 113
- PII references in code: 5345

### Summary of Flagged Files

| File Type | File | Variables/References | PII Categories |
|-----------|------|----------------------|----------------|
| Data | `All_VC_Comp_Deal_Investor_2022-2024.csv` | 35 | name, lname, loc, location, address, city, country, phone, fax, email, lat, url, social |
| Data | `CountryDataset.2024019.supplemented.xlsx` | 61 | country, name, lat |
| Data | `EM_policy_constraints.csv` | 2 | name, country |
| Data | `EM_policy_constraints.dta` | 2 | name, country |
| Data | `LP.csv` | 4 | name, loc, location, city |
| Data | `LP.dta` | 4 | name, loc, location, city |
| Data | `OECD_list.csv` | 1 | country |
| Data | `OECD_list.dta` | 1 | country |
| Data | `WDI_full.xlsx` | 4 | country, name |
| Data | `company_level_predictions_v2.csv` | 13 | lname, name, country |
| Data | `company_level_predictions_v2.dta` | 13 | lname, name, country |
| Data | `country_crosswalk.csv` | 2 | country |
| Data | `country_crosswalk.dta` | 2 | country |
| Data | `country_panel.csv` | 1 | country |
| Data | `country_panel.dta` | 1 | country |
| Data | `critical_subseg.csv` | 5 | network, son, lname, name |
| Data | `critical_subseg.dta` | 5 | network, son, lname, name |
| Data | `crosswalk.xlsx` | 2 | country, lname, name |
| Data | `figure1c_IPO_CapitalIQ_to_PB_EM_0901,Final.xlsx` | 24 | name, country |
| Data | `figure1c_IPO_CapitalIQ_to_PB_US_Final.xlsx` | 5 | name, country |
| Data | `figure1c_IPO_CapitalIQ_to_PB_nonEM_nonUS.With JL Additions.xlsx` | 38 | name, country |
| Data | `indicators_WDI_MtV_corrected.xlsx` | 2 | name, block, loc |
| Data | `indicators_WDI_MtV_from_existing_no_trade2.xlsx` | 2 | name, block, loc |
| Data | `indicators_WDI_MtV_from_scratch_allassigned.xlsx` | 2 | name, block, loc |
| Data | `indicators_WDI_MtV_gpt_assigned.xlsx` | 2 | name, block, loc |
| Data | `ne_10m_admin_0_countries.dbf` | 34 | name, lon |
| Data | `ne_10m_populated_places.dbf` | 40 | name, city, lat, lon |
| Data | `opendatasoft.csv` | 10 | name, country, lat, coord |
| Data | `patent_countrysector_similarity_2000_2013_100k_new_china.csv` | 2 | country |
| Data | `patent_countrysector_similarity_2000_2013_100k_new_china.dta` | 2 | country |
| Data | `patent_sector_labels_grantyear.csv` | 1 | country |
| Data | `patent_sector_labels_grantyear.dta` | 1 | country |
| Data | `patent_sector_labels_new_grantyear.csv` | 1 | country |
| Data | `patent_sector_labels_new_grantyear.dta` | 1 | country |
| Data | `pbcompanies.csv` | 18 | name, lname, loc, location, address, city, country, phone, fax, email, url, social |
| Data | `pbcompanies.dta` | 18 | name, lname, loc, location, address, city, country, phone, fax, email, url, social |
| Data | `pbdealinvestor.csv` | 3 | name |
| Data | `pbdealinvestor.dta` | 3 | name |
| Data | `pbdeals.csv` | 5 | name, lat, loc, location |
| Data | `pbdeals.dta` | 5 | name, lat, loc, location |
| Data | `pbinvestors.csv` | 12 | name, lname, loc, location, address, city, country, phone, fax, email |
| Data | `pbinvestors.dta` | 12 | name, lname, loc, location, address, city, country, phone, fax, email |
| Data | `pbmarketmap_22_24.csv` | 1 | lname, name |
| Data | `pbmarketmap_v2.csv` | 1 | name |
| Data | `policy_constrained_sectors.csv` | 1 | name |
| Data | `policy_constrained_sectors.dta` | 2 | name, lname |
| Data | `similarity_at_sector_x_country_x_year.csv` | 3 | lname, name, country, lat |
| Data | `similarity_at_sector_x_country_x_year.dta` | 3 | lname, name, country, lat |
| Data | `similarity_compiled.csv` | 2 | name, lname |
| Data | `similarity_compiled_western.csv` | 1 | lname, name |
| Data | `simplemaps.csv` | 6 | city, lat, country, name |
| Data | `table1_panelC_Copy of VC Returns 2024Q4 v2.xlsx` | 1 | street |
| Data | `tableA1_VCpc.xlsx` | 1 | country |
| Data | `tableA1_published_values.csv` | 1 | country |
| Data | `un_polity_china.csv` | 1 | country |
| Data | `un_polity_china.dta` | 2 | country |
| Data | `worldwide_pairs_filtered_no_EPO_countries.csv` | 5 | country, lname, name |
| Data | `worldwide_pairs_filtered_no_EPO_countries.dta` | 5 | country, lname, name |
| Code | `00_run_all.py` | 4 | name |
| Code | `01_generate_analysis_v2.do` | 97 | loc, lat, country, name, lname, lon, location |
| Code | `01_prepare_manifest.py` | 1 | name |
| Code | `02_generate_suitability.py` | 83 | country, loc, name, zip, lat, lon, block |
| Code | `02_train_bert_categories.py` | 16 | son, lat, lname, name |
| Code | `03_predict_companies.py` | 7 | lname, name |
| Code | `03a_generate_populated_places.do` | 9 | loc, lat, city, lon, name |
| Code | `03b_generate_controls.py` | 20 | country, loc, name, lon, phone, lat |
| Code | `03c_generate_regression_auxiliary.do` | 133 | loc, country, lname, name, second, lat, location, lon |
| Code | `04_generate_regression_corrected_120623.do` | 40 | loc, lat, country, lname, name, block |
| Code | `04_make_predicted_positive.py` | 14 | name, lname |
| Code | `05_make_company_level_predictions.py` | 13 | country, name, lname |
| Code | `05a_generate_postregression_inputs.do` | 22 | loc, country, name, block |
| Code | `05b_generate_suitability_gdp_component.do` | 9 | loc, country |
| Code | `05c_generate_regression_alltype_by_cat.do` | 63 | loc, second, lat, country, name, lname, lon, block |
| Code | `05d_generate_dealcount_alltype_cluster.do` | 30 | loc, lname, name, country, lon |
| Code | `05e_generate_pre_period_deals.do` | 7 | loc, lname, name, country |
| Code | `05f_generate_similarity_western.do` | 21 | loc, name, lname, country |
| Code | `05g_generate_regression_validation_countrypair.do` | 88 | loc, country, name, lat, lon, lname |
| Code | `05h_generate_deal_22_24.do` | 67 | loc, lat, name, lname, country, lon |
| Code | `05i_generate_regression_00_24_integrated.do` | 17 | loc, country, lname, name, block |
| Code | `06a_generate_patent_citations_from_raw.py` | 22 | loc, location, country, name |
| Code | `06b_generate_patent_layers.py` | 48 | country, lname, name, loc |
| Code | `06c_supplement_regression_patents.do` | 8 | loc, lname, name, country |
| Code | `07b_generate_patent_geolocation_from_raw.py` | 22 | loc, location, city, country, lat, lon, name |
| Code | `07c_generate_company_geolocation.py` | 58 | country, name, lname, loc, city, location, lat, coord, lon |
| Code | `07d_generate_analysis_city.do` | 131 | loc, lat, name, city, lon, location, country, lname |
| Code | `08a_generate_regression_a13_variants.py` | 4 | name, country |
| Code | `08b_generate_regression_figureA11_dropped.do` | 28 | loc, name, block, country, lon, lat |
| Code | `09_generate_simulated_deals.do` | 142 | loc, lat, lon, country, name, lname, block |
| Code | `09_generate_simulated_deals.sh` | 9 | lat, name |
| Code | `bert_pipeline_lib.py` | 32 | name, lname, block, loc, son |
| Code | `figure_1.py` | 44 | lat, block, loc, son, zip, name |
| Code | `figure_2.do` | 3 | loc |
| Code | `figure_3.do` | 26 | loc, name, country, lat, block |
| Code | `figure_4.do` | 3 | loc |
| Code | `figure_A1.py` | 30 | name, country, loc |
| Code | `figure_A10.py` | 14 | name, country, zip, loc |
| Code | `figure_A11.do` | 7 | loc |
| Code | `figure_A12.do` | 17 | loc, country, lname, name |
| Code | `figure_A13.do` | 3 | loc |
| Code | `figure_A14.do` | 11 | loc |
| Code | `figure_A15.do` | 7 | loc |
| Code | `figure_A16.do` | 3 | loc |
| Code | `figure_A17.do` | 32 | loc, city, lat, country, name |
| Code | `figure_A2.do` | 11 | loc, country, name |
| Code | `figure_A3.do` | 5 | loc, name, lat |
| Code | `figure_A4.py` | 6 | name, son, loc |
| Code | `figure_A5.py` | 7 | name, second, lat, lname |
| Code | `figure_A6.do` | 18 | loc, country, name, lat |
| Code | `figure_A7.py` | 16 | lat, lon, name, country, block, loc |
| Code | `figure_A8.py` | 5 | name, country, lat |
| Code | `figure_A9.py` | 16 | name, country, lat, loc |
| Code | `generate_all.sh` | 8 | name, lat, country, loc, location, city |
| Code | `install.do` | 5 | loc |
| Code | `make_patent_sector_labels.py` | 25 | name, country, loc, lat, location |
| Code | `patent_additional_prediction_100k_china_win.ipynb` | 63 | lat, name, country, loc, location, son, block, second, network, house |
| Code | `patent_additional_prediction_win.ipynb` | 90 | lat, name, son, block, loc, second, network, house |
| Code | `patent_family_exercise.ipynb` | 167 | lat, name, loc, location, country, lname, block |
| Code | `patent_prediction_analysis.ipynb` | 33 | lat, son, loc, location, country, name, lname |
| Code | `patent_prediction_analysis_new100k.ipynb` | 29 | lat, loc, location, name, country, lname |
| Code | `patent_similarity.ipynb` | 157 | lat, country, name, loc, son, block, second, house, network, lname |
| Code | `patent_similarity.py` | 14 | country, lat, name |
| Code | `paths.do` | 7 | loc, lat |
| Code | `predict_only.py` | 14 | lat, name, lname |
| Code | `predict_patent_sectors.py` | 33 | loc, location, lat, name, country |
| Code | `run_all.sh` | 2 | name, lat |
| Code | `similarity_clean.ipynb` | 70 | lat, country, name, loc, lname, second |
| Code | `similarity_clean.py` | 27 | name, country, loc, lname, lat |
| Code | `similarity_clean_detail_western.py` | 30 | lat, country, name, loc, lname |
| Code | `similarity_compile_2025.ipynb` | 855 | name, block, loc, son, lat, house, network, second, lon, lname, country |
| Code | `similarity_mac.ipynb` | 278 | lat, lname, name, house, block, loc, second |
| Code | `slurm_predict_patents_batch_01.sh` | 5 | name, url, block, loc |
| Code | `table_1.py` | 22 | son, country, name, street |
| Code | `table_2.do` | 29 | loc, country |
| Code | `table_3.do` | 26 | loc, country, name |
| Code | `table_4.do` | 49 | loc, name, country |
| Code | `table_5.do` | 10 | loc, country |
| Code | `table_6.do` | 35 | loc, name, country |
| Code | `table_7.do` | 24 | loc, country, name |
| Code | `table_8.do` | 33 | loc, country, name |
| Code | `table_A1.py` | 41 | name, country, loc |
| Code | `table_A10.do` | 15 | loc, name, country |
| Code | `table_A11.do` | 12 | loc, country, block, lname, name |
| Code | `table_A12.do` | 31 | loc, country, block, lname, name |
| Code | `table_A13.do` | 15 | loc, country |
| Code | `table_A14.do` | 105 | loc, block, country, name |
| Code | `table_A15.do` | 35 | loc, phone, country |
| Code | `table_A16.do` | 19 | loc, country |
| Code | `table_A17.do` | 16 | loc, country |
| Code | `table_A18.do` | 40 | loc, country |
| Code | `table_A2.do` | 85 | loc, name, country, lname |
| Code | `table_A20.do` | 20 | loc, country |
| Code | `table_A21.do` | 15 | loc, country, name |
| Code | `table_A22.do` | 24 | loc, country |
| Code | `table_A23.do` | 22 | loc, country |
| Code | `table_A24.do` | 22 | loc, country |
| Code | `table_A25.do` | 16 | loc, country |
| Code | `table_A26.do` | 16 | loc, country |
| Code | `table_A27.do` | 8 | loc, country |
| Code | `table_A28.do` | 12 | loc, country |
| Code | `table_A29.do` | 51 | loc, city, lat, country, name |
| Code | `table_A30.do` | 57 | loc, city, lat, country, name |
| Code | `table_A4.do` | 20 | loc, country, lat, name, lon, lname |
| Code | `table_A5.do` | 22 | loc, country |
| Code | `table_A6.do` | 18 | loc, lname, name, country |
| Code | `table_A7.do` | 19 | loc, country |
| Code | `table_A8.do` | 27 | loc, lat, country |
| Code | `table_A9.do` | 12 | loc, country |
| Code | `train_predict_crossvalidate_mac.py` | 13 | name, lname, loc, lat |
| Code | `train_predict_pat01.ipynb` | 26 | loc, location, country, lname, name, son |
| Code | `train_predict_patent_full.ipynb` | 804 | loc, lname, name, lat, son, second |
| Code | `train_predict_v2-1.ipynb` | 18 | name, lname, loc, lat |

*See [Appendix](report-pii-appendix.md) for detailed listing of all flagged instances.*
