## Code Quality

### Python

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_crossvalidate_mac.py, line 56)
  → df_market_map.loc[~df_market_map['fullname'].isin([SELECTED_SUBSEGMENT]), 'label'] = 0

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.py, line 45)
  → df.loc[mask_swap, ['companyid1', 'companyid2']] = df.loc[mask_swap, ['companyid2', 'companyid1']].values

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.py, line 46)
  → df.loc[mask_swap, ['fullname1', 'fullname2']] = df.loc[mask_swap, ['fullname2', 'fullname1']].values

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.py, line 47)
  → df.loc[mask_swap, ['hqcountry1', 'hqcountry2']] = df.loc[mask_swap, ['hqcountry2', 'hqcountry1']].values

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.py, line 48)
  → df.loc[mask_swap, ['yearfounded1', 'yearfounded2']] = df.loc[mask_swap, ['yearfounded2', 'yearfounded1']].values

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.py, line 49)
  → df.loc[mask_swap, ['firstfinancingdate1', 'firstfinancingdate2']] = df.loc[mask_swap, ['firstfinancingdate2', 'firstfinancingdate1']].values

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean_detail_western.py, line 127)
  → df.loc[mask_swap, ["companyid1", "companyid2"]] = df.loc[

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean_detail_western.py, line 130)
  → df.loc[mask_swap, ["fullname1", "fullname2"]] = df.loc[

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean_detail_western.py, line 133)
  → df.loc[mask_swap, ["hqcountry1", "hqcountry2"]] = df.loc[

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean_detail_western.py, line 136)
  → df.loc[mask_swap, ["yearfounded1", "yearfounded2"]] = df.loc[

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean_detail_western.py, line 139)
  → df.loc[mask_swap, ["firstfinancingdate1", "firstfinancingdate2"]] = df.loc[

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean_detail_western.py, line 142)
  → df.loc[mask_swap, ["any_deal_western1", "any_deal_western2"]] = df.loc[

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 269)
  → market_non_vc = float(sample.loc[non_vc, "Market"].sum(skipna=True))

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 270)
  → market_vc = float(sample.loc[vc, "Market"].sum(skipna=True))

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 271)
  → rd_non_vc = float(sample.loc[non_vc, "RD"].sum(skipna=True))

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 272)
  → rd_vc = float(sample.loc[vc, "RD"].sum(skipna=True))

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 376)
  → ws.cell(row=row_idx, column=col_idx, value=float(panel.loc[group, metric]))

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 435)
  → "Generated": panel.loc[group, metric],

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 436)
  → "Reference Excel chart block": reference.loc[group, metric],

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 437)
  → "Difference": panel.loc[group, metric] - reference.loc[group, metric],

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 447)
  → em_kept = em.loc[~em["NonEnt"]].copy()

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 448)
  → us_kept = us.loc[~us["NonEnt"]].copy()

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 449)
  → dm_kept = dm_ex_us.loc[~dm_ex_us["NonEnt"]].copy()

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 455)
  → em_kept.loc[~em_kept["Headquarters"].isin(CHINA_HEADQUARTERS)],

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 460)
  → em_kept.loc[em_kept["Headquarters"].isin(CHINA_HEADQUARTERS)],

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_1.py, line 504)
  → block.loc[g, metrics].values,

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A1.py, line 76)
  → country_table = country_table.loc[: total_rows[0] - 1].copy()

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A7.py, line 80)
  → used.loc[len(used)] = "United States"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A7.py, line 81)
  → used.loc[len(used)] = "China"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A9.py, line 69)
  → score = df.loc[df["hqcountry"] == country, seg]

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 25)
  → W.loc[W["Country Name"] == "Kosovo", "country_2digit"] = "YY"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 44)
  → ind = ind.loc[:, ind.isna().mean(axis=0) <= it]

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 46)
  → ind = ind.loc[:, ~tmask]

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 82)
  → g.loc[g["CountryCode"] == "NAM", "country_2digit"] = "NA"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 165)
  → long.loc[long["Series Code"].isin(NEGATIVE_INDICATORS), "value"] *= -1

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 193)
  → g.loc[g["Country Name"] == "Kosovo", "country_2digit"] = "YY"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 194)
  → g.loc[g["Country Code"] == "NAM", "country_2digit"] = "NA"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (02_generate_suitability.py, line 263)
  → cu.loc[cu.hqcountry == "Kosovo", "country_2digit"] = "YY"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03b_generate_controls.py, line 20)
  → W.loc[W["Country Name"] == "Kosovo", "country_2digit"] = "YY"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07c_generate_company_geolocation.py, line 38)
  → cw_c.loc[cw_c["country_2digit"] == k, "country_simplename"] = v

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07c_generate_company_geolocation.py, line 50)
  → pb.loc[pb.country0 == "westbank", "country0"] = "palestine"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07c_generate_company_geolocation.py, line 51)
  → pb.loc[pb.country0 == "kosovo", "country0"] = "serbia"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07c_generate_company_geolocation.py, line 52)
  → pb.loc[pb.hqstate_province == "Virgin Islands", "hqstate_province"] = "US Virgin Islands"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07c_generate_company_geolocation.py, line 68)
  → sm.loc[sm.city_ascii == "Tel Aviv-Yafo", "city_ascii"] = "Tel Aviv"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A1.py, line 69)
  → raw = raw.loc[: total_rows[0] - 1].copy()

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_v2-1.ipynb, line 55)
  → "    df_market_map.loc[df_market_map['fullname'].isin([SELECTED_SUBSEGMENT]), 'label'] = 1\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_v2-1.ipynb, line 56)
  → "    df_market_map.loc[~df_market_map['fullname'].isin([SELECTED_SUBSEGMENT]), 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.ipynb, line 86)
  → "df.loc[mask_swap, ['companyid1', 'companyid2']] = df.loc[mask_swap, ['companyid2', 'companyid1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.ipynb, line 87)
  → "df.loc[mask_swap, ['fullname1', 'fullname2']] = df.loc[mask_swap, ['fullname2', 'fullname1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.ipynb, line 88)
  → "df.loc[mask_swap, ['hqcountry1', 'hqcountry2']] = df.loc[mask_swap, ['hqcountry2', 'hqcountry1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.ipynb, line 89)
  → "df.loc[mask_swap, ['yearfounded1', 'yearfounded2']] = df.loc[mask_swap, ['yearfounded2', 'yearfounded1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.ipynb, line 90)
  → "df.loc[mask_swap, ['firstfinancingdate1', 'firstfinancingdate2']] = df.loc[mask_swap, ['firstfinancingdate2', 'firstfinancingdate1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (similarity_clean.ipynb, line 186)
  → "            pivot = pivot.loc[:, pivot.columns.str.contains('China|United States')]\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_family_exercise.ipynb, line 122)
  → "primary_indices.update(first_en_idx.loc[fallback_families].tolist())\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_family_exercise.ipynb, line 744)
  → "df_pairs.loc[_swap_mask_base, ['country_1', 'country_2']] = df_pairs.loc[_swap_mask_base, ['country_2', 'country_1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_family_exercise.ipynb, line 745)
  → "df_pairs.loc[_swap_mask_base, ['country_1_transfers_sector_world', 'country_2_transfers_sector_world']] = df_pairs.loc[_swap_mask_base, ['country_2_transfers_sector_world', 'country_1_transfers_sector_world']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_family_exercise.ipynb, line 792)
  → "worldwide_pairs_redistributed.loc[_swap_mask_redist, ['country_1', 'country_2']] = worldwide_pairs_redistributed.loc[_swap_mask_redist, ['country_2', 'country_1']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_family_exercise.ipynb, line 793)
  → "worldwide_pairs_redistributed.loc[_swap_mask_redist, ['country_1_transfers_sector_world', 'country_2_transfers_sector_world']] = worldwide_pairs_redistributed.loc[_swap_mask_redist, ['country_2_transfers_sector_world', 'country_1_transfers_sector_world']].values\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 107)
  → "        if grp.loc[i, \"disambig_country\"] == grp.loc[j, \"disambig_country\"]:\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 111)
  → "            \"patent_id1\": grp.loc[i, \"patent_id\"],\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 112)
  → "            \"patent_id2\": grp.loc[j, \"patent_id\"],\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 113)
  → "            \"country1\": grp.loc[i, \"disambig_country\"],\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 114)
  → "            \"country2\": grp.loc[j, \"disambig_country\"],\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 416)
  → "df_pairs.loc[swap_mask, [\"country1\", \"country2\"]] = df_pairs.loc[swap_mask, [\"country2\", \"country1\"]].to_numpy()\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (patent_similarity.ipynb, line 417)
  → "df_pairs.loc[swap_mask, [\"patent_id1\", \"patent_id2\"]] = df_pairs.loc[swap_mask, [\"patent_id2\", \"patent_id1\"]].to_numpy()\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_pat01.ipynb, line 88)
  → "    df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_pat01.ipynb, line 89)
  → "    df_training.loc[df_training['fullname'] == SELECTED_SUBSEGMENT, 'label'] = 1\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 52)
  → "    df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 53)
  → "    df_training.loc[df_training['fullname'] == SELECTED_SUBSEGMENT, 'label'] = 1\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 291)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 294)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 731)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 734)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 1173)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 1176)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 1615)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 1618)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 1621)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 1624)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 2057)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 2060)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 2487)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 2490)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 2916)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 2919)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 3358)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 3361)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 3788)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 3791)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 4217)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 4220)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 4659)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 4662)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 5101)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 5104)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 5544)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 5547)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 5982)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 5985)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 6423)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 6426)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 6853)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 6856)
  → "  df_training.loc[:, 'label'] = 0\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 7281)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 7284)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 7548)
  → "Try using .loc[row_indexer,col_indexer] = value instead\n",

[ADVISORY] `.query(` or `.loc[` call not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (train_predict_patent_full.ipynb, line 7551)
  → "  df_training.loc[:, 'label'] = 0\n"

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (similarity_clean_detail_western.py, line 69)
  → data.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (similarity_clean_detail_western.py, line 88)
  → merged1.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (similarity_clean_detail_western.py, line 186)
  → df_final = pd.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (figure_A10.py, line 38)
  → merged = df_reg.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (figure_A7.py, line 126)
  → world_china = world.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (figure_A7.py, line 129)
  → world_diff = world.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (table_1.py, line 109)
  → panel = panel.merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (table_1.py, line 293)
  → comparison = reference.assign(_order=range(len(reference))).merge(

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (patent_family_exercise.ipynb, line 666)
  → "        .merge(\n",

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (patent_family_exercise.ipynb, line 674)
  → "        .merge(\n",

[ADVISORY] `pd.merge()` or `.merge()` called without explicit `how=` argument — defaults to inner join, which may silently drop rows. (patent_similarity.ipynb, line 1449)
  → "df_all_sectors_with_macrosector = pd.merge(\n",

### Stata

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_2.do, line 28)
  → keep if OECD_b80s==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_2.do, line 49)
  → keep if OECD_b80s==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_3.do, line 35)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_3.do, line 64)
  → drop if beta == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_3.do, line 83)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_3.do, line 125)
  → drop if beta == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_3.do, line 170)
  → drop if beta == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A12.do, line 26)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A12.do, line 27)
  → keep if hqcountry == "China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A13.do, line 27)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A13.do, line 28)
  → drop if no_shock_year_identified==1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A17.do, line 42)
  → keep if year>=2000

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A17.do, line 97)
  → drop if SOV0NAME=="United States" | SOV0NAME=="China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A17.do, line 111)
  → drop if beta==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A17.do, line 128)
  → drop if beta==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A17.do, line 145)
  → drop if beta==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A17.do, line 162)
  → drop if beta==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A2.do, line 27)
  → keep if year >= 2000 & year <= 2021

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A3.do, line 27)
  → keep if dealtype == "Early Stage VC" | dealtype == "Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A3.do, line 28)
  → keep if companyid == "162908-20" | companyid == "294474-07" | companyid == "433899-46" | companyid == "158661-28" | companyid == "226107-64" | companyid == "489562-84"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A3.do, line 32)
  → drop if date == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (figure_A6.do, line 26)
  → keep if hqcountry == "United States" | hqcountry == "China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 58)
  → drop if dealstatus == "Failed/Cancelled"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 59)
  → keep if dealtype == "Early Stage VC" | dealtype=="Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 62)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 63)
  → keep if year < 2022 & year > 1999

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 66)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 67)
  → keep if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 85)
  → drop if dealstatus == "Failed/Cancelled"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 88)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 89)
  → keep if year < 2022 & year > 1999

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 92)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 104)
  → keep if  dealtype == "Early Stage VC" | dealtype=="Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 110)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 112)
  → drop if dealid==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 113)
  → drop if hqcountry_inv==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 115)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 122)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 158)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 162)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 169)
  → keep if hqcountry !=""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 173)
  → drop if companyid == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 177)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 190)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 240)
  → keep if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 262)
  → keep if dealsize !=.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 263)
  → keep if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 284)
  → drop if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 288)
  → keep if _merge ==3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 294)
  → drop if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 297)
  → keep if _merge ==3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 303)
  → drop if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 307)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 308)
  → drop if dealid ==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 330)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 331)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 336)
  → keep if year <=2019 & year >= 2015

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 347)
  → keep if share_china>0.5

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (01_generate_analysis_v2.do, line 392)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 46)
  → drop if hqcountry=="China" | hqcountry=="United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 58)
  → drop if dealdate == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 61)
  → drop if founderid=="" & ceopbid==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 71)
  → keep if founder != ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 79)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 94)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 104)
  → keep if by_serial_founder == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 127)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 129)
  → keep if dealtype == "Early Stage VC" | dealtype == "Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 136)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 185)
  → drop if first_company_subsegment == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 204)
  → drop if first_company_subsegment == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 224)
  → drop if first_company_subsegment == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 306)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 307)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 317)
  → keep if OECD_b80s==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 330)
  → keep if OECD_b80s==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 331)
  → drop if hqcountry == "China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 344)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 345)
  → keep if hqcountry == "China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 377)
  → keep if shock_year == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 385)
  → keep if hqcountry == "China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 392)
  → drop if _merge == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 406)
  → keep if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 408)
  → drop if chinese_deals_to_drop == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 410)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 413)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 414)
  → drop if companyid == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 418)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (03c_generate_regression_auxiliary.do, line 439)
  → keep if year <= 2019 & year >= 2015

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 83)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 88)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 91)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 114)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 117)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 122)
  → keep if year <= 2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 128)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 153)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 364)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 372)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 385)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 398)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 454)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 458)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 467)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 475)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (04_generate_regression_corrected_120623.do, line 490)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05a_generate_postregression_inputs.do, line 44)
  → keep if hqcountry != ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05a_generate_postregression_inputs.do, line 46)
  → drop if _merge == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05a_generate_postregression_inputs.do, line 49)
  → drop if suitability_score_wdi == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05a_generate_postregression_inputs.do, line 117)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05a_generate_postregression_inputs.do, line 139)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05a_generate_postregression_inputs.do, line 148)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05b_generate_suitability_gdp_component.do, line 42)
  → keep if hqcountry != ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05b_generate_suitability_gdp_component.do, line 44)
  → drop if _merge == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05b_generate_suitability_gdp_component.do, line 47)
  → drop if suitability_score_wdi == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 106)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 108)
  → drop if dealtype_cat == "drop"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 119)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 120)
  → keep if year < 2020 & year > 1999

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 123)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 133)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 137)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 142)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 147)
  → drop if companyid == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 152)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 176)
  → keep if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 193)
  → keep if year <=2019 & year >= 2015

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 254)
  → drop if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 255)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 275)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05c_generate_regression_alltype_by_cat.do, line 303)
  → drop if suitability_score_wdi == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 44)
  → keep if year <=2019 & year >= 2015

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 63)
  → drop if dealstatus == "Failed/Cancelled"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 66)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 67)
  → keep if year < 2022 & year > 1999

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 70)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 79)
  → drop if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 82)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 86)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 95)
  → drop if companyid == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 100)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 129)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 134)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05d_generate_dealcount_alltype_cluster.do, line 137)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05e_generate_pre_period_deals.do, line 43)
  → keep if year <= 2013  & year >= 2000

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05e_generate_pre_period_deals.do, line 47)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05f_generate_similarity_western.do, line 62)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 48)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 53)
  → drop if hqcountry== ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 54)
  → drop if relative_to == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 66)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 82)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 89)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 126)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 133)
  → keep if _merge ==3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 144)
  → drop if country_1==country_2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 167)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 173)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 177)
  → drop if country1=="" | country2==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 188)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 196)
  → keep if _merge ==3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05g_generate_regression_validation_countrypair.do, line 231)
  → drop if suitability_score_wdi==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 69)
  → drop if dealstatus == "Failed/Cancelled"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 72)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 74)
  → keep if  dealtype == "Early Stage VC" | dealtype=="Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 84)
  → drop if companyid == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 99)
  → drop if _merge == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 126)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 130)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 137)
  → keep if hqcountry !=""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 138)
  → drop if companyid == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 147)
  → drop if dealstatus == "Failed/Cancelled"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 150)
  → drop if year ==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 152)
  → keep if  dealtype == "Early Stage VC" | dealtype=="Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 193)
  → drop if hqcountry == "China" | hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 196)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 197)
  → drop if dealid ==""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 215)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05h_generate_deal_22_24.do, line 216)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05i_generate_regression_00_24_integrated.do, line 77)
  → drop if _merge ==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (05i_generate_regression_00_24_integrated.do, line 104)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (06c_supplement_regression_patents.do, line 47)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (06c_supplement_regression_patents.do, line 53)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (06c_supplement_regression_patents.do, line 58)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (06c_supplement_regression_patents.do, line 63)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (06c_supplement_regression_patents.do, line 68)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 63)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 80)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 98)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 109)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 111)
  → drop if dealdate == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 128)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 133)
  → drop if fullname == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 135)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 145)
  → keep if company_first_deal_year<=2013

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 146)
  → keep if company_first_deal_year>=2000

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 179)
  → keep if patent_type == "utility"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 187)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 191)
  → keep if  year < 2022

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 192)
  → drop if id_populated_city == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 197)
  → keep if patent_type == "utility"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 205)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 209)
  → keep if  year < 2022

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 210)
  → drop if id_populated_city == .

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 218)
  → keep if  year < 2022

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 227)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 228)
  → keep if dealtype == "Early Stage VC" | dealtype == "Later Stage VC"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 231)
  → drop if dealdate == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 245)
  → keep if company_CL == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 252)
  → keep if company_all_CL == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 259)
  → keep if company_non_CL == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 266)
  → keep if company_not_all_CL == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 307)
  → keep if  year < 2022

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (07d_generate_analysis_city.do, line 340)
  → drop if city_company_count_allyears==0&city_patent_count_ay_inventors==0&city_patent_count_ay_assignees==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (08b_generate_regression_figureA11_dropped.do, line 92)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 62)
  → drop if AI_ML_SuitSc==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 63)
  → drop if hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 73)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 78)
  → drop if hqcountry== ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 79)
  → drop if relative_to == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 83)
  → keep if relative_to == "`country'"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 90)
  → keep if year <=2019 & year >= 2015

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 107)
  → keep if C == "GDP (current US$)"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 141)
  → drop if AI_ML_SuitSc==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 142)
  → drop if hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 155)
  → keep if year <=2019 & year >= 2015

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 176)
  → drop if AI_ML_SuitSc==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 177)
  → drop if hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 179)
  → keep if sectors_to_lead > 0 & sectors_to_lead !=. & _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 196)
  → drop if hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 206)
  → drop if china_only == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 221)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 230)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 275)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 280)
  → keep if year<= 2019 & hqcountry !="China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 287)
  → drop if subsegment == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 288)
  → drop if hqcountry == ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 298)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 338)
  → drop if AI_ML_SuitSc==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 339)
  → drop if hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 341)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 342)
  → keep if sectors_to_lead > 0 & sectors_to_lead !=.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 358)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 393)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 444)
  → keep if year == 2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 473)
  → drop if AI_ML_SuitSc==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 474)
  → drop if hqcountry == "United States"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 476)
  → keep if _merge == 3

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (09_generate_simulated_deals.do, line 477)
  → keep if sectors_to_lead > 0 & sectors_to_lead !=.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_7.do, line 31)
  → keep if hqcountry != ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_7.do, line 33)
  → drop if _merge == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_7.do, line 36)
  → drop if suitability_score_wdi==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_7.do, line 72)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_8.do, line 31)
  → keep if hqcountry != ""

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_8.do, line 33)
  → drop if _merge == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_8.do, line 36)
  → drop if suitability_score_wdi==.

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_8.do, line 72)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A11.do, line 56)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A12.do, line 54)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A12.do, line 142)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A14.do, line 31)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 29)
  → keep if year>=2000 & year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 44)
  → keep if year>=2000 & year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 59)
  → keep if year>=2000 & year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 74)
  → keep if year>=2000 & year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 91)
  → keep if year>=2000 & year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 109)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 130)
  → drop if count_fullname == 1

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 139)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 148)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 163)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A2.do, line 172)
  → keep if year<=2019

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A23.do, line 29)
  → drop if _merge==2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A26.do, line 28)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A29.do, line 44)
  → keep if year>=2000

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A29.do, line 86)
  → drop if SOV0NAME=="United States" | SOV0NAME=="China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A29.do, line 87)
  → drop if ISO_2digits=="US" | ISO_2digits=="CN"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A30.do, line 44)
  → keep if year>=2000

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A30.do, line 85)
  → drop if SOV0NAME=="United States" | SOV0NAME=="China"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A30.do, line 86)
  → drop if ISO_2digits=="US" | ISO_2digits=="CN"

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A6.do, line 33)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A6.do, line 44)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A6.do, line 49)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A6.do, line 54)
  → drop if _merge == 2

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A8.do, line 25)
  → keep if OECD==0

[ADVISORY] Sample drop (`drop if` / `keep if`) not preceded by a comment within 2 lines — consider adding a comment explaining the criterion. (table_A9.do, line 32)
  → drop if _merge == 2

