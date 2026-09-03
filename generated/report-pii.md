## Potential Personal Identifiable Information (PII)

⚠️ We found the following instances of potentially personally identifying information. This may be completely legitimate but might be worth checking. *As a reminder, privacy legislation in many countries (e.g. GDPR in EU) prohibits the dissemination of personal identifiable information without prior (and documented) consent of individuals.* If indeed you want to publish such information with your replication package, you should probably have obtained IRB approval for this - please check!

**Summary:**

- Data files with PII indicators: 0
- Variables flagged in data: 0
- Code files with PII references: 113
- PII references in code: 5345

### Summary of Flagged Files

| File Type | File | Variables/References | PII Categories |
|-----------|------|----------------------|----------------|
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

*See [Appendix](report-pii-appendix.md) for detailed listing of all flagged instances.*
