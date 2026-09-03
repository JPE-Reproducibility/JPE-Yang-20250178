### `README` Analysis

👉 We are considering the file at 

```
/Users/florianoswald/actions-runner/_work/JPE-Yang-20250178/JPE-Yang-20250178/replication-package/JPE_replication_for_submission/README.pdf 
```
to be the relevant `README`.


**Wrong `README` location warning:**

The `README` file needs to be placed at the root of your replication package. **Please fix.**

#### Keyword search

👉 We searched the readme for keywords to help the reproducibility team. This is only for internal use. 

_Replicator_: The line numbers refer to the readme file printed above.


Line 7 : mixed public/confidential nature of the package requires it.
Line 13 : data only:  confidential-data-not-for-publication/Analysis/  is empty at
Line 28 : • confidential-data-not-for-publication/  — the proprietary inputs (PitchBook
Line 28 : • confidential-data-not-for-publication/  — the proprietary inputs (PitchBook
Line 31 : Editor under the journal's confidential-data exemption, for the sole purpose of the
Line 34 : learning outputs (BERT sector classifications and SBERT text-similarity measures) that are          too computationally intensive to regenerate in the pipeline and are not bit-reproducible
Line 39 : ☒ Confidential data used in this paper and not provided as part of the public
Line 43 : through surveys or experiments. All sources, access procedures, and terms are described
Line 53 : outside  confidential-data-not-for-publication/ . The contents of that folder are
Line 54 : provided to the Data Editor only, under the confidential-data exemption granted for this
Line 64 : terms of the confidential folder.
Line 73 : PitchBoo  pbdeals.dta ,         confidential-data-not-    Data  PitchBook          Data.Na                                            Provi
Line 81 : ML-      9 files in             confidential-data-not-    Data  derived; see
Line 89 : Capital IQ  3                  confidential-data-not-    Data  S&P Global
Line 161 : Global    CountryDataset.20240 workbook: confidential-data- work authors (this
Line 171 : Curated   Global VC_0525.xlsx    confidential-data-not-for-    Data  NSF NSB
Line 196 : PitchBook (confidential)
Line 202 : Stata  .dta  /  .csv ; the variable lists for all PitchBook files are reproduced in full in the Data
Line 205 : pulled in 2025). PitchBook data are proprietary and may not be redistributed; researchers
Line 209 : journal's confidential-data exemption, to be destroyed after the reproducibility checks;
Line 212 : Machine-learning outputs derived from PitchBook and PATSTAT text (confidential)
Line 213 : confidential-data-not-for-publication/Raw/BERT_prediction_resource/  holds the
Line 223 : licensed inputs), they are confidential. Every file's producing code, model,
Line 227 : Capital IQ (confidential)
Line 234 : edits are part of the shipped workbook and are not mechanically reproducible. Capital IQ          is proprietary (https://www.capitaliq.spglobal.com; institutional subscription); the
Line 236 : State Street (confidential)
Line 257 : Hurun China Rich List (confidential)
Line 262 : Zero2IPO (confidential)
Line 329 : confidential)
Line 332 : (CountryDataset.2024019.supplemented.xlsx; confidential folder) combining VC activity,
Line 353 : 6/5/2023) — the reason the workbook is confidential; (2) explicit zeros for three pre-
Line 363 : PitchBook-derived) is in the confidential folder.
Line 364 : Curated global venture-investment series (author-compiled; confidential)
Line 365 : Global VC_0525.xlsx (confidential folder) is the authors' curated compilation of published
Line 380 : classification .dta files with CSV twins plus one .xlsx (full variable lists in the Data
Line 392 : workbook is in the confidential folder (see above). The deal-type → category classification
Line 393 : for the non-VC analyses is hardcoded in
Line 400 : (worldwide_pairs_filtered_no_EPO_countries.dta , confidential folder, with CSV twin)
Line 406 : All raw inputs, by folder. "Twin" = a non-proprietary  .csv  copy of the same data ships
Line 503 : Confidential — confidential-data-not-for-publication/Raw/  (~24 GB; Data Editor
Line 582 : same folder), so no data in the package is available only in a proprietary format. The twins
Line 585 : the  .dta  files (which additionally carry the original variable labels).
Line 587 : confidential-data-not-for-publication/Analysis/  is empty at delivery and is
Line 612 : ☒ Random seed is set at lines 97 and 162 of
Line 614 : seed for each simulation draw is the draw index, set immediately before each
Line 616 : ☒ Random seed is set at lines 111 and 147 of  code/figures/figure_3.do  (the 500-
Line 617 : draw placebo loops behind Figure 3, Panels B and C; seed = draw index).
Line 618 : ☒ Random seed is set at line 241 of  code/generate/02_generate_suitability.py
Line 619 : (the appropriateness-score placebo component; seeded per iteration).
Line 621 : sortseed  at lines 62, 84, and 171 of
Line 681 : environment variable  REPLICATION_ROOT  /  JPE_GENERATE_ROOT  explicitly). Public
Line 682 : raw data are read from  data/raw/ ; confidential raw data from  confidential-data-
Line 683 : not-for-publication/Raw/ ; generated data are written under  confidential-data-
Line 685 : confidential). The path setup recreates  Analysis/  and the  output/  tree if absent.
Line 734 : surviving vintage; it postdates the one used for the paper's  num_citations  variable, which
Line 741 : 1. Unzip the package (and the confidential archive provided separately) so that  data/ ,
Line 742 : confidential-data-not-for-publication/ ,  code/ , and  output/  sit side by side
Line 743 : under one root.  confidential-data-not-for-publication/Analysis/  is empty by
Line 756 : macOS/Windows install locations); override with the environment variable
Line 800 : supplemented Global Innovation Measures workbook (confidential; it embeds Web of
Line 801 : Science–derived publication counts), and every other exhibit requires the confidential
Line 813 : VC_0525.xlsx in the confidential folder (see Details on each Data Source). There is no
Line 882 : (confidential)
Line 910 : Data Appendix: variable-level documentation
Line 912 : Complete variable lists, extracted directly from the shipped files. PitchBook variable
Line 914 : the  .dta  files carry the original names as Stata variable labels); PatentsView columns are
Line 920 : un_polity_china.dta  (8 variables) — country–year panel
Line 922 : Variable              Description
Line 933 : OECD_list.dta  (4 variables) — one row per OECD member:  hqcountry  (country name,
Line 935 : 1980 — the paper's non-EM definition).           country_panel.dta  (12 variables) — one row per country; bilateral measures relative to
Line 939 : Variable                 Description
Line 953 : EM_policy_constraints.dta  (5 variables) — policy × country panel of hand-coded
Line 958 : policy_constrained_sectors.dta  (3 variables) — policy → PitchBook subsegment map:
Line 962 : critical_subseg.dta  (65 variables) — one row per PitchBook subsegment ( fullname_raw ),
Line 968 : country_crosswalk.dta  (2 variables):  hqcountry  (PitchBook country name) ↔
Line 975 : Map_to_Variables_no_panel :  Series Code ,  Series Name , then one 0/1 column per
Line 977 : sheet  Sheet1 : the indicator-name ↔ series-code list.           CountryDataset.2024019.supplemented.xlsx (confidential folder) — 13 sheets :
Line 1000 : Confidential files (variable lists)
Line 1000 : Confidential files (variable lists)
Line 1002 : pbdeals.dta  (95 variables) — one row per deal. Key variables used by the pipeline:
Line 1011 : preserved as Stata variable labels inside the file.
Line 1013 : pbcompanies.dta  (94 variables) — one row per company: identifiers and names
Line 1021 : pbinvestors.dta  (94 variables) — one row per investor:  investorid ,  investorname ,
Line 1026 : pbdealinvestor.dta  (11 variables) — deal–investor links:  dealid ,  investorid ,
Line 1030 : LP.dta  (51 variables) — one row per fund (4,147 funds):  FundID ,  FundName ,  Investor ,
Line 1036 : company_level_predictions_v2.dta  (50 variables) — one row per company (402,695
Line 1041 : similarity_at_sector_x_country_x_year.dta  (25 variables) — sector×country×year:
Line 1052 : patent_countrysector_similarity_2000_2013_100k_new_china.dta  (9 variables):
Line 1055 : variables):  sector ,  country_1 ,  country_2 ,  count  (jointly-filed family count), the two
Line 1058 : Descriptive-exhibit workbooks (confidential,  Raw/other_data_resource/ ):
Line 1101 : Data, Inc. (proprietary; accessed via institutional subscription, 2023–2025).
Line 1103 : (proprietary).
Line 1108 : (proprietary; not redistributable).             •  United Nations. 2023. "UN Comtrade Database" [dataset].
