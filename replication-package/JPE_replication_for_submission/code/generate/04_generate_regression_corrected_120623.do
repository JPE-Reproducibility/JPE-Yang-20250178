version 19
clear all
set more off
set maxvar 30000

local _envroot : environment JPE_GENERATE_ROOT
if "`_envroot'" != "" {
    global ROOT "`_envroot'"
}
else if "$REPLICATION_ROOT" != "" {
    global ROOT "$REPLICATION_ROOT"
}
else {
    global ROOT ""
    local _r "."
    forvalues _i = 1/6 {
        capture confirm file "`_r'/code/auxiliary/paths.do"
        if !_rc {
            global ROOT "`_r'"
            continue, break
        }
        local _r "`_r'/.."
    }
}
if "$ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root, or export JPE_GENERATE_ROOT / set global REPLICATION_ROOT."
    exit 601
}
local _pr_pwd "`c(pwd)'"
quietly cd "$ROOT"
global ROOT "`c(pwd)'"
quietly cd "`_pr_pwd'"
global RAW "$ROOT/data/raw"
global CONFRAW "$ROOT/confidential-data-not-for-publication/Raw"
global TMP "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global data_version "v2"
global previous_version "v1"
global suffix "corrected.dta"
global saving_suffix "corrected_120623.dta"
global regression_file "regression_$saving_suffix"
global suit_all suitability_score_all_$suffix

global dir "$RAW/"
global data_folder "$TMP"
global suit_output_folder "$TMP"
global invariant_data_folder "$TMP"
global simulation_folder "$TMP"
global previous_data_folder "$RAW"
global policy_output_folder "$RAW/other_data_resource/hand_collected"
global patent_output_folder "$RAW/patent_resource"
global similarity_output_folder "$CONFRAW/BERT_prediction_resource"
global POL  "$TMP"
global DV   "$RAW/patent_resource"
global INV  "$TMP"
global PKGA "$TMP"
cap mkdir "$TMP"
cap mkdir "$OUT"
adopath + "$RAW"

cd $data_folder
use deal_$data_version, clear

fillin hqcountry fullname year
foreach v of varlist dealcount_y dealsize_y dealcount_y_us_inv dealcount_y_local_inv dealcount_y_china_inv dealcount_y_other_inv dealcount_y_us_inv_s dealcount_y_local_inv_s dealcount_y_china_inv_s dealcount_y_other_inv_s dealsize_y_us_inv_s dealsize_y_local_inv_s dealsize_y_china_inv_s dealsize_y_other_inv_s {
	replace `v' = 0 if _fillin == 1
}
keep fullname hqcountry year dealcount_y* dealsize_y* _fillin

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s = 0 if OECD_b80s ==.

merge m:1 fullname year using china_us_dealcount_$data_version
replace dealcount_china = 0 if _merge == 1
replace dealcount_us = 0 if _merge == 1
drop if _merge == 2
drop _merge
merge m:1 fullname year using china_us_dealsize_$data_version
replace dealsize_china = 0 if _merge == 1
replace dealsize_us = 0 if _merge == 1
drop if _merge == 2
drop _merge
drop _fillin
drop if fullname == ""

merge m:1 fullname using "china_led_subsegments_avg_strict_dealcount_$data_version"
gen china_led_dealcountavg_strict = _merge
drop _merge
replace china_led_dealcountavg_strict = 0 if china_led_dealcountavg_strict == 1
replace china_led_dealcountavg_strict = 1 if china_led_dealcountavg_strict == 3
merge m:1 fullname using "china_led_subsegments_avg_loose_dealcount_$data_version"
gen china_led_dealcountavg_loose = _merge
drop _merge
replace china_led_dealcountavg_loose = 0 if china_led_dealcountavg_loose == 1
replace china_led_dealcountavg_loose = 1 if china_led_dealcountavg_loose == 3
drop share_china ChinaPlusUS

rename fullname subsegment
encode hqcountry, gen(hq)
encode subsegment, gen(subseg)
gen fullname_raw = ustrregexra(subsegment,"[^A-Za-z0-9]","")
replace fullname_raw = lower(fullname_raw)

merge m:1 fullname_raw using "$RAW/other_data_resource/hand_collected/critical_subseg.dta"
drop _merge
merge m:1 hqcountry using "$RAW/other_data_resource/country_panel.dta"
drop if _merge == 2
drop _merge

drop if year ==.
destring CST* MIC2025* DoD*, replace
replace DoD_Human_Machine_Interfaces = "1" if DoD_Human_Machine_Interfaces == "q"
destring DoD_Human_Machine_Interfaces, replace
egen critical_subseg = rowmax(CST_* MIC2025_* DoD_*)
keep if year <= 2019

split subsegment, p("|")

cd "$suit_output_folder"
merge m:1 hqcountry using china_$suit_all
drop if _merge == 2
drop _merge

gen suitability_score_wdi = .
replace suitability_score_wdi = AgTech_SuitSc if subsegment1 == "AgTech"
replace suitability_score_wdi = AI_ML_SuitSc if subsegment1 == "AI ML"
replace suitability_score_wdi = Blockchain_SuitSc if subsegment1 == "Blockchain"
replace suitability_score_wdi = Carbon_and_Emissions_Tech_SuitSc if subsegment1 == "Carbon and Emissions Tech"
replace suitability_score_wdi = DevOps_SuitSc if subsegment1 == "DevOps"
replace suitability_score_wdi = EdTech_SuitSc if subsegment1 == "EdTech"
replace suitability_score_wdi = Enterprise_Health_SuitSc if subsegment1 == "Enterprise Health"
replace suitability_score_wdi = Fintech_SuitSc if subsegment1 == "Fintech"
replace suitability_score_wdi = FoodTech_SuitSc if subsegment1 == "FoodTech"
replace suitability_score_wdi = InfoSec_SuitSc if subsegment1 == "InfoSec"
replace suitability_score_wdi = Insurtech_SuitSc if subsegment1 == "Insurtech"
replace suitability_score_wdi = IoT_SuitSc  if subsegment1 == "IoT"
replace suitability_score_wdi = MobilityTech_SuitSc if subsegment1 == "MobilityTech"
replace suitability_score_wdi = Retail_HealthTech_SuitSc if subsegment1 == "Retail HealthTech"
replace suitability_score_wdi = Supply_Chain_Tech_SuitSc if subsegment1 == "Supply Chain Tech"

replace suitability_score_wdi = 2.921 - suitability_score_wdi

drop *SuitSc

merge m:1 hqcountry using us_$suit_all
drop if _merge == 2
drop _merge
gen suitability_score_wdi_us = .
replace suitability_score_wdi_us = AgTech_SuitSc if subsegment1 == "AgTech"
replace suitability_score_wdi_us = AI_ML_SuitSc if subsegment1 == "AI ML"
replace suitability_score_wdi_us = Blockchain_SuitSc if subsegment1 == "Blockchain"
replace suitability_score_wdi_us = Carbon_and_Emissions_Tech_SuitSc if subsegment1 == "Carbon and Emissions Tech"
replace suitability_score_wdi_us = DevOps_SuitSc if subsegment1 == "DevOps"
replace suitability_score_wdi_us = EdTech_SuitSc if subsegment1 == "EdTech"
replace suitability_score_wdi_us = Enterprise_Health_SuitSc if subsegment1 == "Enterprise Health"
replace suitability_score_wdi_us = Fintech_SuitSc if subsegment1 == "Fintech"
replace suitability_score_wdi_us = FoodTech_SuitSc if subsegment1 == "FoodTech"
replace suitability_score_wdi_us = InfoSec_SuitSc if subsegment1 == "InfoSec"
replace suitability_score_wdi_us = Insurtech_SuitSc if subsegment1 == "Insurtech"
replace suitability_score_wdi_us = IoT_SuitSc  if subsegment1 == "IoT"
replace suitability_score_wdi_us = MobilityTech_SuitSc if subsegment1 == "MobilityTech"
replace suitability_score_wdi_us = Retail_HealthTech_SuitSc if subsegment1 == "Retail HealthTech"
replace suitability_score_wdi_us = Supply_Chain_Tech_SuitSc if subsegment1 == "Supply Chain Tech"
replace suitability_score_wdi_us = 3.180 - suitability_score_wdi_us

drop *SuitSc

tab year, gen(yr_)
forvalues i = 1/20 {
	local x = `i'+1999
	rename yr_`i' yr_`x'
}

rename china_led_dealcountavg_loose china_led_countavg_loose
rename china_led_dealcountavg_strict china_led_countavg_strict

egen mean_deal_hq_temp_00_12 = mean(dealcount_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12 = max(mean_deal_hq_temp_00_12), by(hq)
drop mean_deal_hq_temp_00_12
gen dealcount_norm_mean_00_12 = dealcount_y/mean_deal_hq_00_12
gen dealcount_norm_mean_us_i_00_12 = dealcount_y_us_inv/mean_deal_hq_00_12
gen dealcount_norm_mean_loc_i_00_12 = dealcount_y_local_inv/mean_deal_hq_00_12
gen dealcount_norm_mean_cn_i_00_12 = dealcount_y_china_inv/mean_deal_hq_00_12
gen dealcount_norm_mean_oth_i_00_12 = dealcount_y_other_inv/mean_deal_hq_00_12

egen mean_deal_hq_temp_00_12_ds = mean(dealsize_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12_ds = max(mean_deal_hq_temp_00_12_ds), by(hq)
drop mean_deal_hq_temp_00_12_ds
gen dealsize_norm_mean_00_12 = dealsize_y/mean_deal_hq_00_12_ds

egen mean_deal_hq_temp_00_06 = mean(dealcount_y) if year < 2006, by(hq)
egen mean_deal_hq_00_06 = max(mean_deal_hq_temp_00_06), by(hq)
drop mean_deal_hq_temp_00_06
gen dealcount_norm_mean_00_06 = dealcount_y/mean_deal_hq_00_06

egen mean_deal_hq_temp_00_06_ds = mean(dealsize_y) if year < 2006, by(hq)
egen mean_deal_hq_00_06_ds = max(mean_deal_hq_temp_00_06_ds), by(hq)
drop mean_deal_hq_temp_00_06_ds
gen dealsize_norm_mean_00_06 = dealsize_y/mean_deal_hq_00_06_ds

egen cst = rowmax(CST_*)
egen mic = rowmax(MIC2025_*)
egen dod = rowmax(DoD_*)
egen mic_cst = rowmax(cst mic)
drop DoD_* CST_* MIC2025_*
gen post2013 = 1 if year > 2013
replace post2013 = 0 if post2013 ==.
foreach j of varlist china_led_countavg_loose china_led_countavg_strict mic cst mic_cst{
	gen p2013_`j' = post2013 * `j'
}

gen p2013_CL_countavg_loose_notoecd = p2013_china_led_countavg_loose*(1-OECD_b80s)
gen p2013_CL_countavg_loose_suit = p2013_china_led_countavg_loose*suitability_score_wdi

gen p2013_CL_countavg_strict_notoecd = p2013_china_led_countavg_strict*(1-OECD_b80s)
gen p2013_CL_countavg_strict_suit = p2013_china_led_countavg_strict*suitability_score_wdi

gen p2013_mic_loose_notoecd = p2013_mic*(1-OECD_b80s)
gen p2013_mic_loose_suit = p2013_mic*suitability_score_wdi

gen p2013_cst_loose_notoecd = p2013_cst*(1-OECD_b80s)
gen p2013_cst_loose_suit = p2013_cst*suitability_score_wdi

gen p2013_mic_cst_notoecd = p2013_mic_cst*(1-OECD_b80s)
gen p2013_mic_cst_suit = p2013_mic_cst*suitability_score_wdi

gen p2013_CL_countavg_loose_suitUS = p2013_china_led_countavg_loose*suitability_score_wdi_us
gen p2013_CL_countavg_strict_suitUS = p2013_china_led_countavg_strict*suitability_score_wdi_us
gen CL_countavg_loose_suitUS = china_led_countavg_loose*suitability_score_wdi_us
gen CL_countavg_strict_suitUS = china_led_countavg_strict*suitability_score_wdi_us

gen NCL_countavg_loose_suitUS = (1-china_led_countavg_loose)*suitability_score_wdi_us
gen NCL_countavg_strict_suitUS = (1-china_led_countavg_strict)*suitability_score_wdi_us

gen p2013_NCL_countavg_loose_suitUS = (1-p2013_china_led_countavg_loose)*suitability_score_wdi_us
gen p2013_NCL_countavg_strict_suitUS = (1-p2013_china_led_countavg_strict)*suitability_score_wdi_us

gen ldealcount_y = log(dealcount_y)
gen ldealsize_y = log(dealsize_y)
gen as_dealcount_y = asinh(dealcount_y)
gen as_dealsize_y = asinh(dealsize_y)

gen deal_indicator = (dealcount_y>0) if dealcount_y!=.
egen temp = sum(dealcount_y_local_inv_s) if year<2012, by(hq)
egen dealcount_local_pre = max(temp), by(hq)
drop temp
gen decade = (year>2010)
gen share_dealcount_china = dealcount_china / (dealcount_china + dealcount_us)
gen p2013_share_china = post2013*share_dealcount_china
gen size_per_deal = dealsize_y/dealcount_y
gen lsize_per_deal = log(size_per_deal)
gen as_size_per_deal = asinh(size_per_deal)

xtile suitability_quantiles = suitability_score_wdi, nquantiles(4)
gen q1_suit = suitability_quantiles == 1
gen q2_suit = suitability_quantiles == 2
gen q3_suit = suitability_quantiles == 3
gen q4_suit = suitability_quantiles == 4
forvalues i = 1/4 {
	gen p2013_CL_countavg_loose_s`i' = q`i'_suit*p2013_china_led_countavg_loose
}
xtile s_quartile_sample = suitability_score_wdi if dealcount_norm_mean_00_12!=., nq(4)
tab s_quartile_sample, gen(s_quartile_sample_)
forvalues i = 1/4 {
	gen p2013_CL_countavg_loose_sq`i' = s_quartile_sample_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_sq`i' = s_quartile_sample_`i'*p2013_china_led_countavg_strict

}

xtile  s_decile = suitability_score_wdi,nq(10)
xtile  s_decile_sample = suitability_score_wdi if dealcount_norm_mean_00_12!=.,nq(10)
tab s_decile, gen(s_decile_)
tab s_decile_sample, gen(s_decile_sample_)
forvalues i = 1/10 {
	gen p2013_CL_countavg_loose_d`i' = s_decile_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_d`i' = s_decile_`i'*p2013_china_led_countavg_strict
	gen p2013_CL_countavg_loose_sd`i' = s_decile_sample_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_sd`i' = s_decile_sample_`i'*p2013_china_led_countavg_strict

}
xtile  s_quint = suitability_score_wdi,nq(5)
xtile  s_quint_sample = suitability_score_wdi if dealcount_norm_mean_00_12!=.,nq(5)
tab s_quint, gen(s_quint_)
tab s_quint_sample, gen(s_quint_sample_)
forvalues i = 1/5 {
	gen p2013_CL_countavg_loose_qu`i' = s_quint_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_qu`i' = s_quint_`i'*p2013_china_led_countavg_strict
	gen p2013_CL_countavg_loose_squ`i' = s_quint_sample_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_squ`i' = s_quint_sample_`i'*p2013_china_led_countavg_strict

}

xtile  s_decile_us = suitability_score_wdi_us,nq(10)
xtile  s_decile_sample_us = suitability_score_wdi_us if dealcount_norm_mean_00_12!=.,nq(10)
tab s_decile_us, gen(s_decile_us_)
tab s_decile_sample_us, gen(s_decile_sample_us_)
forvalues i = 1/10 {
	gen p2013_CL_countavg_loose_d_us`i' = s_decile_us_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_d_us`i' = s_decile_us_`i'*p2013_china_led_countavg_strict
	gen p2013_CL_countavg_loose_sd_us`i' = s_decile_sample_us_`i'*p2013_china_led_countavg_loose
	gen p2013_CL_countavg_strict_sd_us`i' = s_decile_sample_us_`i'*p2013_china_led_countavg_strict

}

gen invest_share_china = dealcount_y_china_inv_s/(dealcount_y_china_inv_s + dealcount_y_local_inv_s + dealcount_y_us_inv_s + dealcount_y_other_inv_s)
gen invest_share_local = dealcount_y_local_inv_s/(dealcount_y_china_inv_s + dealcount_y_local_inv_s + dealcount_y_us_inv_s + dealcount_y_other_inv_s)
gen invest_share_us = dealcount_y_us_inv_s/(dealcount_y_china_inv_s + dealcount_y_local_inv_s + dealcount_y_us_inv_s + dealcount_y_other_inv_s)
gen invest_share_other = dealcount_y_other_inv_s/(dealcount_y_china_inv_s + dealcount_y_local_inv_s + dealcount_y_us_inv_s + dealcount_y_other_inv_s)

gen invest_sizeshare_china = dealsize_y_china_inv_s/(dealsize_y_china_inv_s + dealsize_y_local_inv_s + dealsize_y_us_inv_s + dealsize_y_other_inv_s)
gen invest_sizeshare_local = dealsize_y_local_inv_s/(dealsize_y_china_inv_s + dealsize_y_local_inv_s + dealsize_y_us_inv_s + dealsize_y_other_inv_s)
gen invest_sizeshare_us = dealsize_y_us_inv_s/(dealsize_y_china_inv_s + dealsize_y_local_inv_s + dealsize_y_us_inv_s + dealsize_y_other_inv_s)
gen invest_sizeshare_other = dealsize_y_other_inv_s/(dealsize_y_china_inv_s + dealsize_y_local_inv_s + dealsize_y_us_inv_s + dealsize_y_other_inv_s)

egen temp1 = sum(dealcount_y) if year<2013, by(subseg)
egen sum_ex_china_us = max(temp1), by(subseg)
egen temp2 = sum(dealcount_china) if year<2013, by(subseg hq)
egen sum_china = max(temp2), by(subseg)
egen temp3 = sum(dealcount_us) if year<2013, by(subseg hq)
egen sum_us = max(temp3), by(subseg)
gen total_pre_deals = sum_ex_china_us + sum_china + sum_us
gen ltotal_pre_deals = log(total_pre_deals)

forvalues i = 2000/2019 {
	gen china_led_ca_loose_yr_`i' = china_led_countavg_loose*yr_`i'
}

forvalues i = 2000/2019 {
	gen china_led_ca_loose_noecd_yr_`i' = china_led_countavg_loose*yr_`i'*(1-OECD_b80s)
	gen china_led_ca_loose_suit_yr_`i' = china_led_countavg_loose*yr_`i'*suitability_score_wdi
	gen us_led_ca_loose_noecd_yr_`i' = (1-china_led_countavg_loose)*yr_`i'*(1-OECD_b80s)
	gen china_led_ca_loose_oecd_yr_`i' = (china_led_countavg_loose)*yr_`i'*(OECD_b80s)
	gen china_led_ca_strict_oecd_yr_`i' = (china_led_countavg_strict)*yr_`i'*(OECD_b80s)
	gen china_led_ca_str_noecd_yr_`i' = (china_led_countavg_strict)*yr_`i'*(1-OECD_b80s)
	}
forvalues i = 2000/2019 {
gen china_led_ca_loose_s4_yr_`i' = (china_led_countavg_loose)*yr_`i'*(q4_suit)
gen china_led_ca_loose_s3_yr_`i' = (china_led_countavg_loose)*yr_`i'*(q3_suit)
gen china_led_ca_loose_s2_yr_`i' = (china_led_countavg_loose)*yr_`i'*(q2_suit)

}
gen top_q = (q2_suit==1 | q3_suit==1 | q4_suit==1)
forvalues i = 2000/2019 {
gen china_led_ca_loose_squ5_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_quint_sample_5)
gen china_led_ca_loose_squ4_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_quint_sample_4)
gen china_led_ca_loose_squ3_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_quint_sample_3)
gen china_led_ca_loose_squ2_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_quint_sample_2)
gen china_led_ca_loose_squ1_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_quint_sample_1)
gen china_led_ca_loose_sd10_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_decile_sample_10)
gen china_led_ca_loose_sd1_yr_`i' = (china_led_countavg_loose)*yr_`i'*(s_decile_sample_1)
gen china_led_ca_loose_TQ_yr_`i' = (china_led_countavg_loose)*yr_`i'*(top_q)

}

cd "$data_folder"
merge 1:1 subsegment year hqcountry using "$similarity_output_folder/similarity_at_sector_x_country_x_year.dta"
drop if _merge==2
drop _merge
gen not_first_deal = dealcount_y - first_deal
foreach var in first_deal early late not_first_deal {
	replace `var' = 0 if `var'==.
}

merge 1:1 subsegment year hqcountry using "$PKGA/company_outcomes.dta"
drop if _merge==2
drop _merge
foreach var in IPO acquired failure {
	replace `var' = 0 if `var'==.
	gen i_`var' = (`var'>0)
	egen m_`var'_t = mean(`var') if year < 2013, by(hq)
	egen m_`var' = max(m_`var'_t), by(hq)
	drop m_`var'_t
	gen `var'_norm = `var'/m_`var'
	gen ln_`var' = log(`var'+1)
}

merge 1:1 subsegment year hqcountry using "$PKGA/serial_founders_by_second_deal_year.dta"
drop if _merge==2
drop _merge
foreach var in serial_founder_CL serial_founder_all_CL serial_founder_not_all_CL serial_founder_non_CL by_serial_founder serial_founder_all_CL_C serial_founder_not_all_CL_C serial_founder_non_CL_C by_serial_founder_C serial_founder_CL_F serial_founder_all_CL_F serial_founder_not_all_CL_F serial_founder_non_CL_F by_serial_founder_F {
	replace `var' = 0 if `var'==.
	gen i_`var' = (`var'>0)
	egen m_`var'_t = mean(`var') if year < 2013, by(hq)
	egen m_`var' = max(m_`var'_t), by(hq)
	drop m_`var'_t
	gen `var'_norm = `var'/m_`var'
	gen ln_`var' = log(`var'+1)
}

merge m:1 hqcountry year using "$INV/un_polity_china_cleaned.dta"
drop if _merge==2
drop _merge

gen p2013_CL_polity =  polity_distance_to_chn*p2013_china_led_countavg_loose
gen p2013_CL_un = un_distance_to_chn*p2013_china_led_countavg_loose

gen first_deal_norm = first_deal/mean_deal_hq_00_12
gen not_first_deal_norm = not_first_deal/mean_deal_hq_00_12
gen early_norm = early/mean_deal_hq_00_12
gen late_norm = late/mean_deal_hq_00_12
gen early_not_first_norm = (early-first_deal)/mean_deal_hq_00_12

gen IPO_norm_tot = IPO/mean_deal_hq_00_12
gen acquired_norm_tot = acquired/mean_deal_hq_00_12
gen failure_norm_tot = failure/mean_deal_hq_00_12
gen ipo_acquired_norm = (acquired + IPO)/mean_deal_hq_00_12
gen other_norm_tot = (dealcount_y -IPO - acquired - failure) /mean_deal_hq_00_12

preserve
use "$TMP/shock_year.dta", clear
rename fullname subsegment
save "$TMP/shock_year_merge.dta", replace
restore

merge m:1 subsegment using "$TMP/shock_year_merge.dta"
gen post_shock = (year>2013)
replace post_shock = (year>shock_year) if china_led_countavg_loose==1
gen post_shock_CL = post_shock*china_led_countavg_loose
gen post_shock_CL_suit = post_shock_CL*suitability_score_wdi

gen post_shock_plus_1 = (year>2013)
replace post_shock_plus_1 = (year>shock_year+1) if china_led_countavg_loose==1

gen post_shock_CL_plus_1 = post_shock_plus_1*china_led_countavg_loose
gen post_shock_CL_plus_1_suit = post_shock_CL_plus_1*suitability_score_wdi

gen post_shock_CL_strict = post_shock*china_led_countavg_strict
gen post_shock_CL_strict_suit = post_shock_CL_strict*suitability_score_wdi

gen post_shock_CL_strict_plus_1 = post_shock_plus_1*china_led_countavg_strict
gen post_shock_CL_strict_plus_1_suit = post_shock_CL_strict_plus_1*suitability_score_wdi

egen country_year = group(hq year)
egen country_sector = group(hq subseg)
egen sector_year = group(subseg year)

drop _merge

cd $data_folder
save "$TMP/regression_$saving_suffix", replace

cd $data_folder
use "$TMP/regression_$saving_suffix", clear
replace country_2digit = "YY" if hqcountry == "Kosovo"
cd $invariant_data_folder
merge m:1 country_2digit year using "$INV/internet_penetration.dta"
drop if _merge == 2
drop _merge

merge m:1 country_2digit using "$INV/trade_FDI_China_share.dta"
drop if _merge == 2
drop _merge

cd $data_folder
save "$TMP/regression_$saving_suffix", replace

cd $data_folder
use "$TMP/regression_$saving_suffix", clear
merge m:1 subsegment using "$policy_output_folder/policy_constrained_sectors.dta"
drop if _merge == 2
drop _merge
replace policy_obstacle = 0 if policy_obstacle ==.
encode subsegment1, gen(marketmap_code)
save "$TMP/regression_$saving_suffix", replace

cd $data_folder
use "$TMP/regression_$saving_suffix", clear
drop if hqcountry == ""
save "$TMP/regression_$saving_suffix", replace

cd "$data_folder"
use "$TMP/regression_$saving_suffix", clear

merge m:1 hqcountry policyname using "$policy_output_folder/EM_policy_constraints.dta"
drop _merge
replace loose_same_policy_constraints = 0 if loose_same_policy_constraints==. & OECD_b80s==0
replace same_policy_constraints = 0 if same_policy_constraints==. & OECD_b80s==0

save "$TMP/regression_$saving_suffix", replace

cd $data_folder
use "$TMP/regression_$saving_suffix", clear
drop if hqcountry == ""
save "$TMP/regression_$saving_suffix", replace

cd $data_folder
use "$TMP/regression_$saving_suffix", clear

cap drop s_decile s_decile_sample s_decile_1 s_decile_2 s_decile_3 s_decile_4 s_decile_5 s_decile_6 s_decile_7 s_decile_8 s_decile_9 s_decile_10 s_decile_sample_1 s_decile_sample_2 s_decile_sample_3 s_decile_sample_4 s_decile_sample_5 s_decile_sample_6 s_decile_sample_7 s_decile_sample_8 s_decile_sample_9 s_decile_sample_10 p2013_CL_countavg_loose_d1 p2013_CL_countavg_strict_d1 p2013_CL_countavg_loose_sd1 p2013_CL_countavg_strict_sd1 p2013_CL_countavg_loose_d2 p2013_CL_countavg_strict_d2 p2013_CL_countavg_loose_sd2 p2013_CL_countavg_strict_sd2 p2013_CL_countavg_loose_d3 p2013_CL_countavg_strict_d3 p2013_CL_countavg_loose_sd3 p2013_CL_countavg_strict_sd3 p2013_CL_countavg_loose_d4 p2013_CL_countavg_strict_d4 p2013_CL_countavg_loose_sd4 p2013_CL_countavg_strict_sd4 p2013_CL_countavg_loose_d5 p2013_CL_countavg_strict_d5 p2013_CL_countavg_loose_sd5 p2013_CL_countavg_strict_sd5 p2013_CL_countavg_loose_d6 p2013_CL_countavg_strict_d6 p2013_CL_countavg_loose_sd6 p2013_CL_countavg_strict_sd6 p2013_CL_countavg_loose_d7 p2013_CL_countavg_strict_d7 p2013_CL_countavg_loose_sd7 p2013_CL_countavg_strict_sd7 p2013_CL_countavg_loose_d8 p2013_CL_countavg_strict_d8 p2013_CL_countavg_loose_sd8 p2013_CL_countavg_strict_sd8 p2013_CL_countavg_loose_d9 p2013_CL_countavg_strict_d9 p2013_CL_countavg_loose_sd9 p2013_CL_countavg_strict_sd9 p2013_CL_countavg_loose_d10 p2013_CL_countavg_strict_d10 p2013_CL_countavg_loose_sd10 p2013_CL_countavg_strict_sd10 s_quint s_quint_sample s_quint_1 s_quint_2 s_quint_3 s_quint_4 s_quint_5 s_quint_sample_1 s_quint_sample_2 s_quint_sample_3 s_quint_sample_4 s_quint_sample_5 p2013_CL_countavg_loose_qu1 p2013_CL_countavg_strict_qu1 p2013_CL_countavg_loose_squ1 p2013_CL_countavg_strict_squ1 p2013_CL_countavg_loose_qu2 p2013_CL_countavg_strict_qu2 p2013_CL_countavg_loose_squ2 p2013_CL_countavg_strict_squ2 p2013_CL_countavg_loose_qu3 p2013_CL_countavg_strict_qu3 p2013_CL_countavg_loose_squ3 p2013_CL_countavg_strict_squ3 p2013_CL_countavg_loose_qu4 p2013_CL_countavg_strict_qu4 p2013_CL_countavg_loose_squ4 p2013_CL_countavg_strict_squ4 p2013_CL_countavg_loose_qu5 p2013_CL_countavg_strict_qu5 p2013_CL_countavg_loose_squ5 p2013_CL_countavg_strict_squ5 s_decile_us s_decile_sample_us s_decile_us_1 s_decile_us_2 s_decile_us_3 s_decile_us_4 s_decile_us_5 s_decile_us_6 s_decile_us_7 s_decile_us_8 s_decile_us_9 s_decile_us_10 s_decile_sample_us_1 s_decile_sample_us_2 s_decile_sample_us_3 s_decile_sample_us_4 s_decile_sample_us_5 s_decile_sample_us_6 s_decile_sample_us_7 s_decile_sample_us_8 s_decile_sample_us_9 s_decile_sample_us_10 p2013_CL_countavg_loose_d_us1 p2013_CL_countavg_strict_d_us1 p2013_CL_countavg_loose_sd_us1 p2013_CL_countavg_strict_sd_us1 p2013_CL_countavg_loose_d_us2 p2013_CL_countavg_strict_d_us2 p2013_CL_countavg_loose_sd_us2 p2013_CL_countavg_strict_sd_us2 p2013_CL_countavg_loose_d_us3 p2013_CL_countavg_strict_d_us3 p2013_CL_countavg_loose_sd_us3 p2013_CL_countavg_strict_sd_us3 p2013_CL_countavg_loose_d_us4 p2013_CL_countavg_strict_d_us4 p2013_CL_countavg_loose_sd_us4 p2013_CL_countavg_strict_sd_us4 p2013_CL_countavg_loose_d_us5 p2013_CL_countavg_strict_d_us5 p2013_CL_countavg_loose_sd_us5 p2013_CL_countavg_strict_sd_us5 p2013_CL_countavg_loose_d_us6 p2013_CL_countavg_strict_d_us6 p2013_CL_countavg_loose_sd_us6 p2013_CL_countavg_strict_sd_us6 p2013_CL_countavg_loose_d_us7 p2013_CL_countavg_strict_d_us7 p2013_CL_countavg_loose_sd_us7 p2013_CL_countavg_strict_sd_us7 p2013_CL_countavg_loose_d_us8 p2013_CL_countavg_strict_d_us8 p2013_CL_countavg_loose_sd_us8 p2013_CL_countavg_strict_sd_us8 p2013_CL_countavg_loose_d_us9 p2013_CL_countavg_strict_d_us9 p2013_CL_countavg_loose_sd_us9 p2013_CL_countavg_strict_sd_us9 p2013_CL_countavg_loose_d_us10 p2013_CL_countavg_strict_d_us10 p2013_CL_countavg_loose_sd_us10 p2013_CL_countavg_strict_sd_us10 ChinaPlusUS share_china china_share_quintiles china_share_decimals china_share_quintiles_100 china_share_decimals_100 china_share_quartiles C_CL_countavg_suit p2013_C_CL_countavg_suit C_CL_100_countavg_suit p2013_C_100_CL_countavg_suit q1_CL q1_CL_suit p2013_q1_CL_countavg_suit q2_CL q2_CL_suit p2013_q2_CL_countavg_suit q3_CL q3_CL_suit p2013_q3_CL_countavg_suit q4_CL q4_CL_suit p2013_q4_CL_countavg_suit q5_CL q5_CL_suit p2013_q5_CL_countavg_suit q1_CL_100 q1_CL_100_suit p2013_q1_100_CL_countavg_suit q2_CL_100 q2_CL_100_suit p2013_q2_100_CL_countavg_suit q3_CL_100 q3_CL_100_suit p2013_q3_100_CL_countavg_suit q4_CL_100 q4_CL_100_suit p2013_q4_100_CL_countavg_suit q5_CL_100 q5_CL_100_suit p2013_q5_100_CL_countavg_suit d1_CL d1_CL_suit p2013_d1_CL_countavg_suit d2_CL d2_CL_suit p2013_d2_CL_countavg_suit d3_CL d3_CL_suit p2013_d3_CL_countavg_suit d4_CL d4_CL_suit p2013_d4_CL_countavg_suit d5_CL d5_CL_suit p2013_d5_CL_countavg_suit d6_CL d6_CL_suit p2013_d6_CL_countavg_suit d7_CL d7_CL_suit p2013_d7_CL_countavg_suit d8_CL d8_CL_suit p2013_d8_CL_countavg_suit d9_CL d9_CL_suit p2013_d9_CL_countavg_suit d10_CL d10_CL_suit p2013_d10_CL_countavg_suit d1_CL_100 d1_CL_100_suit p2013_d1_100_CL_countavg_suit d2_CL_100 d2_CL_100_suit p2013_d2_100_CL_countavg_suit d3_CL_100 d3_CL_100_suit p2013_d3_100_CL_countavg_suit d4_CL_100 d4_CL_100_suit p2013_d4_100_CL_countavg_suit d5_CL_100 d5_CL_100_suit p2013_d5_100_CL_countavg_suit d6_CL_100 d6_CL_100_suit p2013_d6_100_CL_countavg_suit d7_CL_100 d7_CL_100_suit p2013_d7_100_CL_countavg_suit d8_CL_100 d8_CL_100_suit p2013_d8_100_CL_countavg_suit d9_CL_100 d9_CL_100_suit p2013_d9_100_CL_countavg_suit d10_CL_100 d10_CL_100_suit p2013_d10_100_CL_countavg_suit china_led_d10_suit_yr_2000 china_led_d9_suit_yr_2000 china_led_d8_suit_yr_2000 china_led_d7_suit_yr_2000 china_led_d6_suit_yr_2000 china_led_d5_suit_yr_2000 china_led_d4_suit_yr_2000 china_led_d3_suit_yr_2000 china_led_d2_suit_yr_2000 china_led_100_d10_suit_yr_2000 china_led_100_d9_suit_yr_2000 china_led_100_d8_suit_yr_2000 china_led_100_d7_suit_yr_2000 china_led_100_d6_suit_yr_2000 china_led_100_d5_suit_yr_2000 china_led_100_d4_suit_yr_2000 china_led_100_d3_suit_yr_2000 china_led_100_d2_suit_yr_2000 china_led_q5_suit_yr_2000 china_led_q4_suit_yr_2000 china_led_q3_suit_yr_2000 china_led_q2_suit_yr_2000 china_led_100_q5_suit_yr_2000 china_led_100_q4_suit_yr_2000 china_led_100_q3_suit_yr_2000 china_led_100_q2_suit_yr_2000 china_led_d10_suit_yr_2001 china_led_d9_suit_yr_2001 china_led_d8_suit_yr_2001 china_led_d7_suit_yr_2001 china_led_d6_suit_yr_2001 china_led_d5_suit_yr_2001 china_led_d4_suit_yr_2001 china_led_d3_suit_yr_2001 china_led_d2_suit_yr_2001 china_led_100_d10_suit_yr_2001 china_led_100_d9_suit_yr_2001 china_led_100_d8_suit_yr_2001 china_led_100_d7_suit_yr_2001 china_led_100_d6_suit_yr_2001 china_led_100_d5_suit_yr_2001 china_led_100_d4_suit_yr_2001 china_led_100_d3_suit_yr_2001 china_led_100_d2_suit_yr_2001 china_led_q5_suit_yr_2001 china_led_q4_suit_yr_2001 china_led_q3_suit_yr_2001 china_led_q2_suit_yr_2001 china_led_100_q5_suit_yr_2001 china_led_100_q4_suit_yr_2001 china_led_100_q3_suit_yr_2001 china_led_100_q2_suit_yr_2001 china_led_d10_suit_yr_2002 china_led_d9_suit_yr_2002 china_led_d8_suit_yr_2002 china_led_d7_suit_yr_2002 china_led_d6_suit_yr_2002 china_led_d5_suit_yr_2002 china_led_d4_suit_yr_2002 china_led_d3_suit_yr_2002 china_led_d2_suit_yr_2002 china_led_100_d10_suit_yr_2002 china_led_100_d9_suit_yr_2002 china_led_100_d8_suit_yr_2002 china_led_100_d7_suit_yr_2002 china_led_100_d6_suit_yr_2002 china_led_100_d5_suit_yr_2002 china_led_100_d4_suit_yr_2002 china_led_100_d3_suit_yr_2002 china_led_100_d2_suit_yr_2002 china_led_q5_suit_yr_2002 china_led_q4_suit_yr_2002 china_led_q3_suit_yr_2002 china_led_q2_suit_yr_2002 china_led_100_q5_suit_yr_2002 china_led_100_q4_suit_yr_2002 china_led_100_q3_suit_yr_2002 china_led_100_q2_suit_yr_2002 china_led_d10_suit_yr_2003 china_led_d9_suit_yr_2003 china_led_d8_suit_yr_2003 china_led_d7_suit_yr_2003 china_led_d6_suit_yr_2003 china_led_d5_suit_yr_2003 china_led_d4_suit_yr_2003 china_led_d3_suit_yr_2003 china_led_d2_suit_yr_2003 china_led_100_d10_suit_yr_2003 china_led_100_d9_suit_yr_2003 china_led_100_d8_suit_yr_2003 china_led_100_d7_suit_yr_2003 china_led_100_d6_suit_yr_2003 china_led_100_d5_suit_yr_2003 china_led_100_d4_suit_yr_2003 china_led_100_d3_suit_yr_2003 china_led_100_d2_suit_yr_2003 china_led_q5_suit_yr_2003 china_led_q4_suit_yr_2003 china_led_q3_suit_yr_2003 china_led_q2_suit_yr_2003 china_led_100_q5_suit_yr_2003 china_led_100_q4_suit_yr_2003 china_led_100_q3_suit_yr_2003 china_led_100_q2_suit_yr_2003 china_led_d10_suit_yr_2004 china_led_d9_suit_yr_2004 china_led_d8_suit_yr_2004 china_led_d7_suit_yr_2004 china_led_d6_suit_yr_2004 china_led_d5_suit_yr_2004 china_led_d4_suit_yr_2004 china_led_d3_suit_yr_2004 china_led_d2_suit_yr_2004 china_led_100_d10_suit_yr_2004 china_led_100_d9_suit_yr_2004 china_led_100_d8_suit_yr_2004 china_led_100_d7_suit_yr_2004 china_led_100_d6_suit_yr_2004 china_led_100_d5_suit_yr_2004 china_led_100_d4_suit_yr_2004 china_led_100_d3_suit_yr_2004 china_led_100_d2_suit_yr_2004 china_led_q5_suit_yr_2004 china_led_q4_suit_yr_2004 china_led_q3_suit_yr_2004 china_led_q2_suit_yr_2004 china_led_100_q5_suit_yr_2004 china_led_100_q4_suit_yr_2004 china_led_100_q3_suit_yr_2004 china_led_100_q2_suit_yr_2004 china_led_d10_suit_yr_2005 china_led_d9_suit_yr_2005 china_led_d8_suit_yr_2005 china_led_d7_suit_yr_2005 china_led_d6_suit_yr_2005 china_led_d5_suit_yr_2005 china_led_d4_suit_yr_2005 china_led_d3_suit_yr_2005 china_led_d2_suit_yr_2005 china_led_100_d10_suit_yr_2005 china_led_100_d9_suit_yr_2005 china_led_100_d8_suit_yr_2005 china_led_100_d7_suit_yr_2005 china_led_100_d6_suit_yr_2005 china_led_100_d5_suit_yr_2005 china_led_100_d4_suit_yr_2005 china_led_100_d3_suit_yr_2005 china_led_100_d2_suit_yr_2005 china_led_q5_suit_yr_2005 china_led_q4_suit_yr_2005 china_led_q3_suit_yr_2005 china_led_q2_suit_yr_2005 china_led_100_q5_suit_yr_2005 china_led_100_q4_suit_yr_2005 china_led_100_q3_suit_yr_2005 china_led_100_q2_suit_yr_2005 china_led_d10_suit_yr_2006 china_led_d9_suit_yr_2006 china_led_d8_suit_yr_2006 china_led_d7_suit_yr_2006 china_led_d6_suit_yr_2006 china_led_d5_suit_yr_2006 china_led_d4_suit_yr_2006 china_led_d3_suit_yr_2006 china_led_d2_suit_yr_2006 china_led_100_d10_suit_yr_2006 china_led_100_d9_suit_yr_2006 china_led_100_d8_suit_yr_2006 china_led_100_d7_suit_yr_2006 china_led_100_d6_suit_yr_2006 china_led_100_d5_suit_yr_2006 china_led_100_d4_suit_yr_2006 china_led_100_d3_suit_yr_2006 china_led_100_d2_suit_yr_2006 china_led_q5_suit_yr_2006 china_led_q4_suit_yr_2006 china_led_q3_suit_yr_2006 china_led_q2_suit_yr_2006 china_led_100_q5_suit_yr_2006 china_led_100_q4_suit_yr_2006 china_led_100_q3_suit_yr_2006 china_led_100_q2_suit_yr_2006 china_led_d10_suit_yr_2007 china_led_d9_suit_yr_2007 china_led_d8_suit_yr_2007 china_led_d7_suit_yr_2007 china_led_d6_suit_yr_2007 china_led_d5_suit_yr_2007 china_led_d4_suit_yr_2007 china_led_d3_suit_yr_2007 china_led_d2_suit_yr_2007 china_led_100_d10_suit_yr_2007 china_led_100_d9_suit_yr_2007 china_led_100_d8_suit_yr_2007 china_led_100_d7_suit_yr_2007 china_led_100_d6_suit_yr_2007 china_led_100_d5_suit_yr_2007 china_led_100_d4_suit_yr_2007 china_led_100_d3_suit_yr_2007 china_led_100_d2_suit_yr_2007 china_led_q5_suit_yr_2007 china_led_q4_suit_yr_2007 china_led_q3_suit_yr_2007 china_led_q2_suit_yr_2007 china_led_100_q5_suit_yr_2007 china_led_100_q4_suit_yr_2007 china_led_100_q3_suit_yr_2007 china_led_100_q2_suit_yr_2007 china_led_d10_suit_yr_2008 china_led_d9_suit_yr_2008 china_led_d8_suit_yr_2008 china_led_d7_suit_yr_2008 china_led_d6_suit_yr_2008 china_led_d5_suit_yr_2008 china_led_d4_suit_yr_2008 china_led_d3_suit_yr_2008 china_led_d2_suit_yr_2008 china_led_100_d10_suit_yr_2008 china_led_100_d9_suit_yr_2008 china_led_100_d8_suit_yr_2008 china_led_100_d7_suit_yr_2008 china_led_100_d6_suit_yr_2008 china_led_100_d5_suit_yr_2008 china_led_100_d4_suit_yr_2008 china_led_100_d3_suit_yr_2008 china_led_100_d2_suit_yr_2008 china_led_q5_suit_yr_2008 china_led_q4_suit_yr_2008 china_led_q3_suit_yr_2008 china_led_q2_suit_yr_2008 china_led_100_q5_suit_yr_2008 china_led_100_q4_suit_yr_2008 china_led_100_q3_suit_yr_2008 china_led_100_q2_suit_yr_2008 china_led_d10_suit_yr_2009 china_led_d9_suit_yr_2009 china_led_d8_suit_yr_2009 china_led_d7_suit_yr_2009 china_led_d6_suit_yr_2009 china_led_d5_suit_yr_2009 china_led_d4_suit_yr_2009 china_led_d3_suit_yr_2009 china_led_d2_suit_yr_2009 china_led_100_d10_suit_yr_2009 china_led_100_d9_suit_yr_2009 china_led_100_d8_suit_yr_2009 china_led_100_d7_suit_yr_2009 china_led_100_d6_suit_yr_2009 china_led_100_d5_suit_yr_2009 china_led_100_d4_suit_yr_2009 china_led_100_d3_suit_yr_2009 china_led_100_d2_suit_yr_2009 china_led_q5_suit_yr_2009 china_led_q4_suit_yr_2009 china_led_q3_suit_yr_2009 china_led_q2_suit_yr_2009 china_led_100_q5_suit_yr_2009 china_led_100_q4_suit_yr_2009 china_led_100_q3_suit_yr_2009 china_led_100_q2_suit_yr_2009 china_led_d10_suit_yr_2010 china_led_d9_suit_yr_2010 china_led_d8_suit_yr_2010 china_led_d7_suit_yr_2010 china_led_d6_suit_yr_2010 china_led_d5_suit_yr_2010 china_led_d4_suit_yr_2010 china_led_d3_suit_yr_2010 china_led_d2_suit_yr_2010 china_led_100_d10_suit_yr_2010 china_led_100_d9_suit_yr_2010 china_led_100_d8_suit_yr_2010 china_led_100_d7_suit_yr_2010 china_led_100_d6_suit_yr_2010 china_led_100_d5_suit_yr_2010 china_led_100_d4_suit_yr_2010 china_led_100_d3_suit_yr_2010 china_led_100_d2_suit_yr_2010 china_led_q5_suit_yr_2010 china_led_q4_suit_yr_2010 china_led_q3_suit_yr_2010 china_led_q2_suit_yr_2010 china_led_100_q5_suit_yr_2010 china_led_100_q4_suit_yr_2010 china_led_100_q3_suit_yr_2010 china_led_100_q2_suit_yr_2010 china_led_d10_suit_yr_2011 china_led_d9_suit_yr_2011 china_led_d8_suit_yr_2011 china_led_d7_suit_yr_2011 china_led_d6_suit_yr_2011 china_led_d5_suit_yr_2011 china_led_d4_suit_yr_2011 china_led_d3_suit_yr_2011 china_led_d2_suit_yr_2011 china_led_100_d10_suit_yr_2011 china_led_100_d9_suit_yr_2011 china_led_100_d8_suit_yr_2011 china_led_100_d7_suit_yr_2011 china_led_100_d6_suit_yr_2011 china_led_100_d5_suit_yr_2011 china_led_100_d4_suit_yr_2011 china_led_100_d3_suit_yr_2011 china_led_100_d2_suit_yr_2011 china_led_q5_suit_yr_2011 china_led_q4_suit_yr_2011 china_led_q3_suit_yr_2011 china_led_q2_suit_yr_2011 china_led_100_q5_suit_yr_2011 china_led_100_q4_suit_yr_2011 china_led_100_q3_suit_yr_2011 china_led_100_q2_suit_yr_2011 china_led_d10_suit_yr_2012 china_led_d9_suit_yr_2012 china_led_d8_suit_yr_2012 china_led_d7_suit_yr_2012 china_led_d6_suit_yr_2012 china_led_d5_suit_yr_2012 china_led_d4_suit_yr_2012 china_led_d3_suit_yr_2012 china_led_d2_suit_yr_2012 china_led_100_d10_suit_yr_2012 china_led_100_d9_suit_yr_2012 china_led_100_d8_suit_yr_2012 china_led_100_d7_suit_yr_2012 china_led_100_d6_suit_yr_2012 china_led_100_d5_suit_yr_2012 china_led_100_d4_suit_yr_2012 china_led_100_d3_suit_yr_2012 china_led_100_d2_suit_yr_2012 china_led_q5_suit_yr_2012 china_led_q4_suit_yr_2012 china_led_q3_suit_yr_2012 china_led_q2_suit_yr_2012 china_led_100_q5_suit_yr_2012 china_led_100_q4_suit_yr_2012 china_led_100_q3_suit_yr_2012 china_led_100_q2_suit_yr_2012 china_led_d10_suit_yr_2013 china_led_d9_suit_yr_2013 china_led_d8_suit_yr_2013 china_led_d7_suit_yr_2013 china_led_d6_suit_yr_2013 china_led_d5_suit_yr_2013 china_led_d4_suit_yr_2013 china_led_d3_suit_yr_2013 china_led_d2_suit_yr_2013 china_led_100_d10_suit_yr_2013 china_led_100_d9_suit_yr_2013 china_led_100_d8_suit_yr_2013 china_led_100_d7_suit_yr_2013 china_led_100_d6_suit_yr_2013 china_led_100_d5_suit_yr_2013 china_led_100_d4_suit_yr_2013 china_led_100_d3_suit_yr_2013 china_led_100_d2_suit_yr_2013 china_led_q5_suit_yr_2013 china_led_q4_suit_yr_2013 china_led_q3_suit_yr_2013 china_led_q2_suit_yr_2013 china_led_100_q5_suit_yr_2013 china_led_100_q4_suit_yr_2013 china_led_100_q3_suit_yr_2013 china_led_100_q2_suit_yr_2013 china_led_d10_suit_yr_2014 china_led_d9_suit_yr_2014 china_led_d8_suit_yr_2014 china_led_d7_suit_yr_2014 china_led_d6_suit_yr_2014 china_led_d5_suit_yr_2014 china_led_d4_suit_yr_2014 china_led_d3_suit_yr_2014 china_led_d2_suit_yr_2014 china_led_100_d10_suit_yr_2014 china_led_100_d9_suit_yr_2014 china_led_100_d8_suit_yr_2014 china_led_100_d7_suit_yr_2014 china_led_100_d6_suit_yr_2014 china_led_100_d5_suit_yr_2014 china_led_100_d4_suit_yr_2014 china_led_100_d3_suit_yr_2014 china_led_100_d2_suit_yr_2014 china_led_q5_suit_yr_2014 china_led_q4_suit_yr_2014 china_led_q3_suit_yr_2014 china_led_q2_suit_yr_2014 china_led_100_q5_suit_yr_2014 china_led_100_q4_suit_yr_2014 china_led_100_q3_suit_yr_2014 china_led_100_q2_suit_yr_2014 china_led_d10_suit_yr_2015 china_led_d9_suit_yr_2015 china_led_d8_suit_yr_2015 china_led_d7_suit_yr_2015 china_led_d6_suit_yr_2015 china_led_d5_suit_yr_2015 china_led_d4_suit_yr_2015 china_led_d3_suit_yr_2015 china_led_d2_suit_yr_2015 china_led_100_d10_suit_yr_2015 china_led_100_d9_suit_yr_2015 china_led_100_d8_suit_yr_2015 china_led_100_d7_suit_yr_2015 china_led_100_d6_suit_yr_2015 china_led_100_d5_suit_yr_2015 china_led_100_d4_suit_yr_2015 china_led_100_d3_suit_yr_2015 china_led_100_d2_suit_yr_2015 china_led_q5_suit_yr_2015 china_led_q4_suit_yr_2015 china_led_q3_suit_yr_2015 china_led_q2_suit_yr_2015 china_led_100_q5_suit_yr_2015 china_led_100_q4_suit_yr_2015 china_led_100_q3_suit_yr_2015 china_led_100_q2_suit_yr_2015 china_led_d10_suit_yr_2016 china_led_d9_suit_yr_2016 china_led_d8_suit_yr_2016 china_led_d7_suit_yr_2016 china_led_d6_suit_yr_2016 china_led_d5_suit_yr_2016 china_led_d4_suit_yr_2016 china_led_d3_suit_yr_2016 china_led_d2_suit_yr_2016 china_led_100_d10_suit_yr_2016 china_led_100_d9_suit_yr_2016 china_led_100_d8_suit_yr_2016 china_led_100_d7_suit_yr_2016 china_led_100_d6_suit_yr_2016 china_led_100_d5_suit_yr_2016 china_led_100_d4_suit_yr_2016 china_led_100_d3_suit_yr_2016 china_led_100_d2_suit_yr_2016 china_led_q5_suit_yr_2016 china_led_q4_suit_yr_2016 china_led_q3_suit_yr_2016 china_led_q2_suit_yr_2016 china_led_100_q5_suit_yr_2016 china_led_100_q4_suit_yr_2016 china_led_100_q3_suit_yr_2016 china_led_100_q2_suit_yr_2016 china_led_d10_suit_yr_2017 china_led_d9_suit_yr_2017 china_led_d8_suit_yr_2017 china_led_d7_suit_yr_2017 china_led_d6_suit_yr_2017 china_led_d5_suit_yr_2017 china_led_d4_suit_yr_2017 china_led_d3_suit_yr_2017 china_led_d2_suit_yr_2017 china_led_100_d10_suit_yr_2017 china_led_100_d9_suit_yr_2017 china_led_100_d8_suit_yr_2017 china_led_100_d7_suit_yr_2017 china_led_100_d6_suit_yr_2017 china_led_100_d5_suit_yr_2017 china_led_100_d4_suit_yr_2017 china_led_100_d3_suit_yr_2017 china_led_100_d2_suit_yr_2017 china_led_q5_suit_yr_2017 china_led_q4_suit_yr_2017 china_led_q3_suit_yr_2017 china_led_q2_suit_yr_2017 china_led_100_q5_suit_yr_2017 china_led_100_q4_suit_yr_2017 china_led_100_q3_suit_yr_2017 china_led_100_q2_suit_yr_2017 china_led_d10_suit_yr_2018 china_led_d9_suit_yr_2018 china_led_d8_suit_yr_2018 china_led_d7_suit_yr_2018 china_led_d6_suit_yr_2018 china_led_d5_suit_yr_2018 china_led_d4_suit_yr_2018 china_led_d3_suit_yr_2018 china_led_d2_suit_yr_2018 china_led_100_d10_suit_yr_2018 china_led_100_d9_suit_yr_2018 china_led_100_d8_suit_yr_2018 china_led_100_d7_suit_yr_2018 china_led_100_d6_suit_yr_2018 china_led_100_d5_suit_yr_2018 china_led_100_d4_suit_yr_2018 china_led_100_d3_suit_yr_2018 china_led_100_d2_suit_yr_2018 china_led_q5_suit_yr_2018 china_led_q4_suit_yr_2018 china_led_q3_suit_yr_2018 china_led_q2_suit_yr_2018 china_led_100_q5_suit_yr_2018 china_led_100_q4_suit_yr_2018 china_led_100_q3_suit_yr_2018 china_led_100_q2_suit_yr_2018 china_led_d10_suit_yr_2019 china_led_d9_suit_yr_2019 china_led_d8_suit_yr_2019 china_led_d7_suit_yr_2019 china_led_d6_suit_yr_2019 china_led_d5_suit_yr_2019 china_led_d4_suit_yr_2019 china_led_d3_suit_yr_2019 china_led_d2_suit_yr_2019 china_led_100_d10_suit_yr_2019 china_led_100_d9_suit_yr_2019 china_led_100_d8_suit_yr_2019 china_led_100_d7_suit_yr_2019 china_led_100_d6_suit_yr_2019 china_led_100_d5_suit_yr_2019 china_led_100_d4_suit_yr_2019 china_led_100_d3_suit_yr_2019 china_led_100_d2_suit_yr_2019 china_led_q5_suit_yr_2019 china_led_q4_suit_yr_2019 china_led_q3_suit_yr_2019 china_led_q2_suit_yr_2019 china_led_100_q5_suit_yr_2019 china_led_100_q4_suit_yr_2019 china_led_100_q3_suit_yr_2019 china_led_100_q2_suit_yr_2019 invest_share_china invest_share_local invest_share_us invest_share_other invest_sizeshare_china invest_sizeshare_local invest_sizeshare_us invest_sizeshare_other temp1 sum_ex_china_us temp2 sum_china temp3 sum_us total_pre_deals ltotal_pre_deals china_led_ca_loose_yr_2000 china_led_ca_loose_yr_2001 china_led_ca_loose_yr_2002 china_led_ca_loose_yr_2003 china_led_ca_loose_yr_2004 china_led_ca_loose_yr_2005 china_led_ca_loose_yr_2006 china_led_ca_loose_yr_2007 china_led_ca_loose_yr_2008 china_led_ca_loose_yr_2009 china_led_ca_loose_yr_2010 china_led_ca_loose_yr_2011 china_led_ca_loose_yr_2012 china_led_ca_loose_yr_2013 china_led_ca_loose_yr_2014 china_led_ca_loose_yr_2015 china_led_ca_loose_yr_2016 china_led_ca_loose_yr_2017 china_led_ca_loose_yr_2018 china_led_ca_loose_yr_2019 china_led_ca_loose_noecd_yr_2000 china_led_ca_loose_suit_yr_2000 us_led_ca_loose_noecd_yr_2000 china_led_ca_loose_oecd_yr_2000 china_led_ca_strict_oecd_yr_2000 china_led_ca_str_noecd_yr_2000 china_led_ca_loose_noecd_yr_2001 china_led_ca_loose_suit_yr_2001 us_led_ca_loose_noecd_yr_2001 china_led_ca_loose_oecd_yr_2001 china_led_ca_strict_oecd_yr_2001 china_led_ca_str_noecd_yr_2001 china_led_ca_loose_noecd_yr_2002 china_led_ca_loose_suit_yr_2002 us_led_ca_loose_noecd_yr_2002 china_led_ca_loose_oecd_yr_2002 china_led_ca_strict_oecd_yr_2002 china_led_ca_str_noecd_yr_2002 china_led_ca_loose_noecd_yr_2003 china_led_ca_loose_suit_yr_2003 us_led_ca_loose_noecd_yr_2003 china_led_ca_loose_oecd_yr_2003 china_led_ca_strict_oecd_yr_2003 china_led_ca_str_noecd_yr_2003 china_led_ca_loose_noecd_yr_2004 china_led_ca_loose_suit_yr_2004 us_led_ca_loose_noecd_yr_2004 china_led_ca_loose_oecd_yr_2004 china_led_ca_strict_oecd_yr_2004 china_led_ca_str_noecd_yr_2004 china_led_ca_loose_noecd_yr_2005 china_led_ca_loose_suit_yr_2005 us_led_ca_loose_noecd_yr_2005 china_led_ca_loose_oecd_yr_2005 china_led_ca_strict_oecd_yr_2005 china_led_ca_str_noecd_yr_2005 china_led_ca_loose_noecd_yr_2006 china_led_ca_loose_suit_yr_2006 us_led_ca_loose_noecd_yr_2006 china_led_ca_loose_oecd_yr_2006 china_led_ca_strict_oecd_yr_2006 china_led_ca_str_noecd_yr_2006 china_led_ca_loose_noecd_yr_2007 china_led_ca_loose_suit_yr_2007 us_led_ca_loose_noecd_yr_2007 china_led_ca_loose_oecd_yr_2007 china_led_ca_strict_oecd_yr_2007 china_led_ca_str_noecd_yr_2007 china_led_ca_loose_noecd_yr_2008 china_led_ca_loose_suit_yr_2008 us_led_ca_loose_noecd_yr_2008 china_led_ca_loose_oecd_yr_2008 china_led_ca_strict_oecd_yr_2008 china_led_ca_str_noecd_yr_2008 china_led_ca_loose_noecd_yr_2009 china_led_ca_loose_suit_yr_2009 us_led_ca_loose_noecd_yr_2009 china_led_ca_loose_oecd_yr_2009 china_led_ca_strict_oecd_yr_2009 china_led_ca_str_noecd_yr_2009 china_led_ca_loose_noecd_yr_2010 china_led_ca_loose_suit_yr_2010 us_led_ca_loose_noecd_yr_2010 china_led_ca_loose_oecd_yr_2010 china_led_ca_strict_oecd_yr_2010 china_led_ca_str_noecd_yr_2010 china_led_ca_loose_noecd_yr_2011 china_led_ca_loose_suit_yr_2011 us_led_ca_loose_noecd_yr_2011 china_led_ca_loose_oecd_yr_2011 china_led_ca_strict_oecd_yr_2011 china_led_ca_str_noecd_yr_2011 china_led_ca_loose_noecd_yr_2012 china_led_ca_loose_suit_yr_2012 us_led_ca_loose_noecd_yr_2012 china_led_ca_loose_oecd_yr_2012 china_led_ca_strict_oecd_yr_2012 china_led_ca_str_noecd_yr_2012 china_led_ca_loose_noecd_yr_2013 china_led_ca_loose_suit_yr_2013 us_led_ca_loose_noecd_yr_2013 china_led_ca_loose_oecd_yr_2013 china_led_ca_strict_oecd_yr_2013 china_led_ca_str_noecd_yr_2013 china_led_ca_loose_noecd_yr_2014 china_led_ca_loose_suit_yr_2014 us_led_ca_loose_noecd_yr_2014 china_led_ca_loose_oecd_yr_2014 china_led_ca_strict_oecd_yr_2014 china_led_ca_str_noecd_yr_2014 china_led_ca_loose_noecd_yr_2015 china_led_ca_loose_suit_yr_2015 us_led_ca_loose_noecd_yr_2015 china_led_ca_loose_oecd_yr_2015 china_led_ca_strict_oecd_yr_2015 china_led_ca_str_noecd_yr_2015 china_led_ca_loose_noecd_yr_2016 china_led_ca_loose_suit_yr_2016 us_led_ca_loose_noecd_yr_2016 china_led_ca_loose_oecd_yr_2016 china_led_ca_strict_oecd_yr_2016 china_led_ca_str_noecd_yr_2016 china_led_ca_loose_noecd_yr_2017 china_led_ca_loose_suit_yr_2017 us_led_ca_loose_noecd_yr_2017 china_led_ca_loose_oecd_yr_2017 china_led_ca_strict_oecd_yr_2017 china_led_ca_str_noecd_yr_2017 china_led_ca_loose_noecd_yr_2018 china_led_ca_loose_suit_yr_2018 us_led_ca_loose_noecd_yr_2018 china_led_ca_loose_oecd_yr_2018 china_led_ca_strict_oecd_yr_2018 china_led_ca_str_noecd_yr_2018 china_led_ca_loose_noecd_yr_2019 china_led_ca_loose_suit_yr_2019 us_led_ca_loose_noecd_yr_2019 china_led_ca_loose_oecd_yr_2019 china_led_ca_strict_oecd_yr_2019 china_led_ca_str_noecd_yr_2019 china_led_ca_loose_s4_yr_2000 china_led_ca_loose_s3_yr_2000 china_led_ca_loose_s2_yr_2000 china_led_ca_loose_s4_yr_2001 china_led_ca_loose_s3_yr_2001 china_led_ca_loose_s2_yr_2001 china_led_ca_loose_s4_yr_2002 china_led_ca_loose_s3_yr_2002 china_led_ca_loose_s2_yr_2002 china_led_ca_loose_s4_yr_2003 china_led_ca_loose_s3_yr_2003 china_led_ca_loose_s2_yr_2003 china_led_ca_loose_s4_yr_2004 china_led_ca_loose_s3_yr_2004 china_led_ca_loose_s2_yr_2004 china_led_ca_loose_s4_yr_2005 china_led_ca_loose_s3_yr_2005 china_led_ca_loose_s2_yr_2005 china_led_ca_loose_s4_yr_2006 china_led_ca_loose_s3_yr_2006 china_led_ca_loose_s2_yr_2006 china_led_ca_loose_s4_yr_2007 china_led_ca_loose_s3_yr_2007 china_led_ca_loose_s2_yr_2007 china_led_ca_loose_s4_yr_2008 china_led_ca_loose_s3_yr_2008 china_led_ca_loose_s2_yr_2008 china_led_ca_loose_s4_yr_2009 china_led_ca_loose_s3_yr_2009 china_led_ca_loose_s2_yr_2009 china_led_ca_loose_s4_yr_2010 china_led_ca_loose_s3_yr_2010 china_led_ca_loose_s2_yr_2010 china_led_ca_loose_s4_yr_2011 china_led_ca_loose_s3_yr_2011 china_led_ca_loose_s2_yr_2011 china_led_ca_loose_s4_yr_2012 china_led_ca_loose_s3_yr_2012 china_led_ca_loose_s2_yr_2012 china_led_ca_loose_s4_yr_2013 china_led_ca_loose_s3_yr_2013 china_led_ca_loose_s2_yr_2013 china_led_ca_loose_s4_yr_2014 china_led_ca_loose_s3_yr_2014 china_led_ca_loose_s2_yr_2014 china_led_ca_loose_s4_yr_2015 china_led_ca_loose_s3_yr_2015 china_led_ca_loose_s2_yr_2015 china_led_ca_loose_s4_yr_2016 china_led_ca_loose_s3_yr_2016 china_led_ca_loose_s2_yr_2016 china_led_ca_loose_s4_yr_2017 china_led_ca_loose_s3_yr_2017 china_led_ca_loose_s2_yr_2017 china_led_ca_loose_s4_yr_2018 china_led_ca_loose_s3_yr_2018 china_led_ca_loose_s2_yr_2018 china_led_ca_loose_s4_yr_2019 china_led_ca_loose_s3_yr_2019 china_led_ca_loose_s2_yr_2019 top_q china_led_ca_loose_squ5_yr_2000 china_led_ca_loose_squ4_yr_2000 china_led_ca_loose_squ3_yr_2000 china_led_ca_loose_squ2_yr_2000 china_led_ca_loose_squ1_yr_2000 china_led_ca_loose_sd10_yr_2000 china_led_ca_loose_sd1_yr_2000 china_led_ca_loose_TQ_yr_2000 china_led_ca_loose_squ5_yr_2001 china_led_ca_loose_squ4_yr_2001 china_led_ca_loose_squ3_yr_2001 china_led_ca_loose_squ2_yr_2001 china_led_ca_loose_squ1_yr_2001 china_led_ca_loose_sd10_yr_2001 china_led_ca_loose_sd1_yr_2001 china_led_ca_loose_TQ_yr_2001 china_led_ca_loose_squ5_yr_2002 china_led_ca_loose_squ4_yr_2002 china_led_ca_loose_squ3_yr_2002 china_led_ca_loose_squ2_yr_2002 china_led_ca_loose_squ1_yr_2002 china_led_ca_loose_sd10_yr_2002 china_led_ca_loose_sd1_yr_2002 china_led_ca_loose_TQ_yr_2002 china_led_ca_loose_squ5_yr_2003 china_led_ca_loose_squ4_yr_2003 china_led_ca_loose_squ3_yr_2003 china_led_ca_loose_squ2_yr_2003 china_led_ca_loose_squ1_yr_2003 china_led_ca_loose_sd10_yr_2003 china_led_ca_loose_sd1_yr_2003 china_led_ca_loose_TQ_yr_2003 china_led_ca_loose_squ5_yr_2004 china_led_ca_loose_squ4_yr_2004 china_led_ca_loose_squ3_yr_2004 china_led_ca_loose_squ2_yr_2004 china_led_ca_loose_squ1_yr_2004 china_led_ca_loose_sd10_yr_2004 china_led_ca_loose_sd1_yr_2004 china_led_ca_loose_TQ_yr_2004 china_led_ca_loose_squ5_yr_2005 china_led_ca_loose_squ4_yr_2005 china_led_ca_loose_squ3_yr_2005 china_led_ca_loose_squ2_yr_2005 china_led_ca_loose_squ1_yr_2005 china_led_ca_loose_sd10_yr_2005 china_led_ca_loose_sd1_yr_2005 china_led_ca_loose_TQ_yr_2005 china_led_ca_loose_squ5_yr_2006 china_led_ca_loose_squ4_yr_2006 china_led_ca_loose_squ3_yr_2006 china_led_ca_loose_squ2_yr_2006 china_led_ca_loose_squ1_yr_2006 china_led_ca_loose_sd10_yr_2006 china_led_ca_loose_sd1_yr_2006 china_led_ca_loose_TQ_yr_2006 china_led_ca_loose_squ5_yr_2007 china_led_ca_loose_squ4_yr_2007 china_led_ca_loose_squ3_yr_2007 china_led_ca_loose_squ2_yr_2007 china_led_ca_loose_squ1_yr_2007 china_led_ca_loose_sd10_yr_2007 china_led_ca_loose_sd1_yr_2007 china_led_ca_loose_TQ_yr_2007 china_led_ca_loose_squ5_yr_2008 china_led_ca_loose_squ4_yr_2008 china_led_ca_loose_squ3_yr_2008 china_led_ca_loose_squ2_yr_2008 china_led_ca_loose_squ1_yr_2008 china_led_ca_loose_sd10_yr_2008 china_led_ca_loose_sd1_yr_2008 china_led_ca_loose_TQ_yr_2008 china_led_ca_loose_squ5_yr_2009 china_led_ca_loose_squ4_yr_2009 china_led_ca_loose_squ3_yr_2009 china_led_ca_loose_squ2_yr_2009 china_led_ca_loose_squ1_yr_2009 china_led_ca_loose_sd10_yr_2009 china_led_ca_loose_sd1_yr_2009 china_led_ca_loose_TQ_yr_2009 china_led_ca_loose_squ5_yr_2010 china_led_ca_loose_squ4_yr_2010 china_led_ca_loose_squ3_yr_2010 china_led_ca_loose_squ2_yr_2010 china_led_ca_loose_squ1_yr_2010 china_led_ca_loose_sd10_yr_2010 china_led_ca_loose_sd1_yr_2010 china_led_ca_loose_TQ_yr_2010 china_led_ca_loose_squ5_yr_2011 china_led_ca_loose_squ4_yr_2011 china_led_ca_loose_squ3_yr_2011 china_led_ca_loose_squ2_yr_2011 china_led_ca_loose_squ1_yr_2011 china_led_ca_loose_sd10_yr_2011 china_led_ca_loose_sd1_yr_2011 china_led_ca_loose_TQ_yr_2011 china_led_ca_loose_squ5_yr_2012 china_led_ca_loose_squ4_yr_2012 china_led_ca_loose_squ3_yr_2012 china_led_ca_loose_squ2_yr_2012 china_led_ca_loose_squ1_yr_2012 china_led_ca_loose_sd10_yr_2012 china_led_ca_loose_sd1_yr_2012 china_led_ca_loose_TQ_yr_2012 china_led_ca_loose_squ5_yr_2013 china_led_ca_loose_squ4_yr_2013 china_led_ca_loose_squ3_yr_2013 china_led_ca_loose_squ2_yr_2013 china_led_ca_loose_squ1_yr_2013 china_led_ca_loose_sd10_yr_2013 china_led_ca_loose_sd1_yr_2013 china_led_ca_loose_TQ_yr_2013 china_led_ca_loose_squ5_yr_2014 china_led_ca_loose_squ4_yr_2014 china_led_ca_loose_squ3_yr_2014 china_led_ca_loose_squ2_yr_2014 china_led_ca_loose_squ1_yr_2014 china_led_ca_loose_sd10_yr_2014 china_led_ca_loose_sd1_yr_2014 china_led_ca_loose_TQ_yr_2014 china_led_ca_loose_squ5_yr_2015 china_led_ca_loose_squ4_yr_2015 china_led_ca_loose_squ3_yr_2015 china_led_ca_loose_squ2_yr_2015 china_led_ca_loose_squ1_yr_2015 china_led_ca_loose_sd10_yr_2015 china_led_ca_loose_sd1_yr_2015 china_led_ca_loose_TQ_yr_2015 china_led_ca_loose_squ5_yr_2016 china_led_ca_loose_squ4_yr_2016 china_led_ca_loose_squ3_yr_2016 china_led_ca_loose_squ2_yr_2016 china_led_ca_loose_squ1_yr_2016 china_led_ca_loose_sd10_yr_2016 china_led_ca_loose_sd1_yr_2016 china_led_ca_loose_TQ_yr_2016 china_led_ca_loose_squ5_yr_2017 china_led_ca_loose_squ4_yr_2017 china_led_ca_loose_squ3_yr_2017 china_led_ca_loose_squ2_yr_2017 china_led_ca_loose_squ1_yr_2017 china_led_ca_loose_sd10_yr_2017 china_led_ca_loose_sd1_yr_2017 china_led_ca_loose_TQ_yr_2017 china_led_ca_loose_squ5_yr_2018 china_led_ca_loose_squ4_yr_2018 china_led_ca_loose_squ3_yr_2018 china_led_ca_loose_squ2_yr_2018 china_led_ca_loose_squ1_yr_2018 china_led_ca_loose_sd10_yr_2018 china_led_ca_loose_sd1_yr_2018 china_led_ca_loose_TQ_yr_2018 china_led_ca_loose_squ5_yr_2019 china_led_ca_loose_squ4_yr_2019 china_led_ca_loose_squ3_yr_2019 china_led_ca_loose_squ2_yr_2019 china_led_ca_loose_squ1_yr_2019 china_led_ca_loose_sd10_yr_2019 china_led_ca_loose_sd1_yr_2019 china_led_ca_loose_TQ_yr_2019 fullname first_deal early late china_similarity_mean_placebo china_similarity_10_placebo china_similarity_25_placebo china_similarity_mean china_similarity_10 china_similarity_25 china_similarity_mean_afteronly china_similarity_10_afteronly china_similarity_25_afteronly us_similarity_mean_placebo us_similarity_10_placebo us_similarity_25_placebo us_similarity_mean us_similarity_10 us_similarity_25 us_similarity_mean_afteronly us_similarity_10_afteronly us_similarity_25_afteronly not_first_deal dealsize10m dealsize50m dealsize100m i_dealsize10m m_dealsize10m dealsize10m_norm ln_dealsize10m i_dealsize50m m_dealsize50m dealsize50m_norm ln_dealsize50m i_dealsize100m m_dealsize100m dealsize100m_norm ln_dealsize100m IPO failure acquired i_IPO m_IPO IPO_norm ln_IPO i_acquired m_acquired acquired_norm ln_acquired i_failure m_failure failure_norm ln_failure serial_founder_CL serial_founder_all_CL serial_founder_not_all_CL serial_founder_non_CL by_serial_founder serial_founder_CL_C serial_founder_all_CL_C serial_founder_not_all_CL_C serial_founder_non_CL_C by_serial_founder_C serial_founder_CL_F serial_founder_all_CL_F serial_founder_not_all_CL_F serial_founder_non_CL_F by_serial_founder_F i_serial_founder_CL m_serial_founder_CL serial_founder_CL_norm ln_serial_founder_CL i_serial_founder_all_CL m_serial_founder_all_CL serial_founder_all_CL_norm ln_serial_founder_all_CL i_serial_founder_not_all_CL m_serial_founder_not_all_CL serial_founder_not_all_CL_norm ln_serial_founder_not_all_CL i_serial_founder_non_CL m_serial_founder_non_CL serial_founder_non_CL_norm ln_serial_founder_non_CL i_by_serial_founder m_by_serial_founder by_serial_founder_norm ln_by_serial_founder i_serial_founder_all_CL_C m_serial_founder_all_CL_C serial_founder_all_CL_C_norm ln_serial_founder_all_CL_C i_serial_founder_not_all_CL_C m_serial_founder_not_all_CL_C serial_founder_not_all_CL_C_norm ln_serial_founder_not_all_CL_C i_serial_founder_non_CL_C m_serial_founder_non_CL_C serial_founder_non_CL_C_norm ln_serial_founder_non_CL_C i_by_serial_founder_C m_by_serial_founder_C by_serial_founder_C_norm ln_by_serial_founder_C i_serial_founder_CL_F m_serial_founder_CL_F serial_founder_CL_F_norm ln_serial_founder_CL_F i_serial_founder_all_CL_F m_serial_founder_all_CL_F serial_founder_all_CL_F_norm ln_serial_founder_all_CL_F i_serial_founder_not_all_CL_F m_serial_founder_not_all_CL_F serial_founder_not_all_CL_F_norm ln_serial_founder_not_all_CL_F i_serial_founder_non_CL_F m_serial_founder_non_CL_F serial_founder_non_CL_F_norm ln_serial_founder_non_CL_F i_by_serial_founder_F m_by_serial_founder_F by_serial_founder_F_norm ln_by_serial_founder_F serial_investor_CL serial_investor_all_CL serial_investor_not_all_CL serial_investor_non_CL by_serial_investor serial_investor_CL_C serial_investor_all_CL_C serial_investor_not_all_CL_C serial_investor_non_CL_C by_serial_investor_C serial_investor_CL_I serial_investor_all_CL_I serial_investor_not_all_CL_I serial_investor_non_CL_I by_serial_investor_I i_by_serial_investor m_by_serial_investor by_serial_investor_nm ln_by_serial_investor i_by_serial_investor_C m_by_serial_investor_C by_serial_investor_C_nm ln_by_serial_investor_C i_by_serial_investor_I m_by_serial_investor_I by_serial_investor_I_nm ln_by_serial_investor_I i_serial_investor_CL m_serial_investor_CL serial_investor_CL_nm ln_serial_investor_CL i_serial_investor_all_CL m_serial_investor_all_CL serial_investor_all_CL_nm ln_serial_investor_all_CL i_serial_investor_not_all_CL m_serial_investor_not_all_CL serial_investor_not_all_CL_nm ln_serial_investor_not_all_CL i_serial_investor_non_CL m_serial_investor_non_CL serial_investor_non_CL_nm ln_serial_investor_non_CL i_serial_investor_CL_C m_serial_investor_CL_C serial_investor_CL_C_nm ln_serial_investor_CL_C i_serial_investor_all_CL_C m_serial_investor_all_CL_C serial_investor_all_CL_C_nm ln_serial_investor_all_CL_C i_serial_investor_not_all_CL_C m_serial_investor_not_all_CL_C serial_investor_not_all_CL_C_nm ln_serial_investor_not_all_CL_C i_serial_investor_non_CL_C m_serial_investor_non_CL_C serial_investor_non_CL_C_nm ln_serial_investor_non_CL_C i_serial_investor_CL_I m_serial_investor_CL_I serial_investor_CL_I_nm ln_serial_investor_CL_I i_serial_investor_all_CL_I m_serial_investor_all_CL_I serial_investor_all_CL_I_nm ln_serial_investor_all_CL_I i_serial_investor_not_all_CL_I m_serial_investor_not_all_CL_I serial_investor_not_all_CL_I_nm ln_serial_investor_not_all_CL_I i_serial_investor_non_CL_I m_serial_investor_non_CL_I serial_investor_non_CL_I_nm ln_serial_investor_non_CL_I SC_serial_investor_CL SC_serial_investor_all_CL SC_serial_investor_not_all_CL SC_serial_investor_non_CL SC_b_yserial_investor SC_serial_investor_CL_C SC_serial_investor_all_CL_C SC_serial_investor_not_all_CL_C SC_serial_investor_non_CL_C SC_b_yserial_investor_C SC_serial_investor_CL_I SC_serial_investor_all_CL_I SC_serial_investor_not_all_CL_I SC_serial_investor_non_CL_I SC_b_yserial_investor_I iSC_serial_investor_CL lSC_serial_investor_CL iSC_serial_investor_all_CL lSC_serial_investor_all_CL iSC_serial_investor_not_all_CL lSC_serial_investor_not_all_CL iSC_serial_investor_non_CL lSC_serial_investor_non_CL iSC_serial_investor_CL_C lSC_serial_investor_CL_C iSC_serial_investor_all_CL_C lSC_serial_investor_all_CL_C iSC_serial_investor_not_all_CL_C lSC_serial_investor_not_all_CL_C iSC_serial_investor_non_CL_C lSC_serial_investor_non_CL_C iSC_b_yserial_investor lSC_b_yserial_investor iSC_b_yserial_investor_C lSC_b_yserial_investor_C iSC_b_yserial_investor_I lSC_b_yserial_investor_I iSC_serial_investor_all_CL_I lSC_serial_investor_all_CL_I iSC_serial_investor_not_all_CL_I lSC_serial_investor_not_all_CL_I iSC_serial_investor_non_CL_I lSC_serial_investor_non_CL_I LI_serial_investor_CL LI_serial_investor_all_CL LI_serial_investor_not_all_CL LI_serial_investor_non_CL LI_by_serial_investor LI_serial_investor_CL_C LI_serial_investor_all_CL_C LI_serial_investor_not_all_CL_C LI_serial_investor_non_CL_C LI_by_serial_investor_C LI_serial_investor_CL_I LI_serial_investor_all_CL_I LI_serial_investor_not_all_CL_I LI_serial_investor_non_CL_I LI_by_serial_investor_I iLI_serial_investor_CL lLI_serial_investor_CL iLI_serial_investor_all_CL lLI_serial_investor_all_CL iLI_serial_investor_not_all_CL lLI_serial_investor_not_all_CL iLI_serial_investor_non_CL lLI_serial_investor_non_CL iLI_by_serial_investor lLI_by_serial_investor iLI_serial_investor_CL_C lLI_serial_investor_CL_C iLI_serial_investor_all_CL_C lLI_serial_investor_all_CL_C iLI_serial_investor_not_all_CL_C lLI_serial_investor_not_all_CL_C iLI_serial_investor_non_CL_C lLI_serial_investor_non_CL_C iLI_by_serial_investor_C lLI_by_serial_investor_C iLI_serial_investor_CL_I lLI_serial_investor_CL_I iLI_serial_investor_all_CL_I lLI_serial_investor_all_CL_I iLI_serial_investor_not_all_CL_I lLI_serial_investor_not_all_CL_I iLI_serial_investor_non_CL_I lLI_serial_investor_non_CL_I iLI_by_serial_investor_I lLI_by_serial_investor_I unicorn_2005 unicorn_2006 unicorn_2007 unicorn_2008 unicorn_2009 unicorn_2010 unicorn_2011 unicorn_2012 unicorn_2013 unicorn_2014 unicorn_2015 unicorn_2016 unicorn_2017 unicorn_2018 unicorn_2019 unicorn_2020 unicorn_2021 unicorn_2022 unicorn_pre_2013 unicorn_pre_2013_sum unicorn_pre_2015 unicorn_pre_2015_sum unicorn_pre_2016 unicorn_pre_2016_sum p2013_unicorn_pre_2013 p2013_unicorn_pre_2013_noecd p2013_unicorn_pre_2013_suit p2013_unicorn_pre_2013_sum p2013_unicorn_pre_2013_sum_noecd p2013_unicorn_pre_2013_sum_suit p2013_unicorn_pre_2015 p2013_unicorn_pre_2015_noecd p2013_unicorn_pre_2015_suit p2013_unicorn_pre_2015_sum p2013_unicorn_pre_2015_sum_noecd p2013_unicorn_pre_2015_sum_suit p2013_unicorn_pre_2016 p2013_unicorn_pre_2016_noecd p2013_unicorn_pre_2016_suit p2013_unicorn_pre_2016_sum p2013_unicorn_pre_2016_sum_noecd p2013_unicorn_pre_2016_sum_suit china_dealsize10m china_dealsize50m china_dealsize100m china_dealsize10m_b2005 i_china_dealsize10m_b2005 p_china_dealsize10m_b2005_n p_china_dealsize10m_b2005_su p_i_china_dealsize10m_b2005_n p_i_china_dealsize10m_b2005_su china_dealsize50m_b2005 i_china_dealsize50m_b2005 p_china_dealsize50m_b2005_n p_china_dealsize50m_b2005_su p_i_china_dealsize50m_b2005_n p_i_china_dealsize50m_b2005_su china_dealsize100m_b2005 i_china_dealsize100m_b2005 p_china_dealsize100m_b2005_n p_china_dealsize100m_b2005_su p_i_china_dealsize100m_b2005_n p_i_china_dealsize100m_b2005_su china_dealsize10m_b2006 i_china_dealsize10m_b2006 p_china_dealsize10m_b2006_n p_china_dealsize10m_b2006_su p_i_china_dealsize10m_b2006_n p_i_china_dealsize10m_b2006_su china_dealsize50m_b2006 i_china_dealsize50m_b2006 p_china_dealsize50m_b2006_n p_china_dealsize50m_b2006_su p_i_china_dealsize50m_b2006_n p_i_china_dealsize50m_b2006_su china_dealsize100m_b2006 i_china_dealsize100m_b2006 p_china_dealsize100m_b2006_n p_china_dealsize100m_b2006_su p_i_china_dealsize100m_b2006_n p_i_china_dealsize100m_b2006_su china_dealsize10m_b2007 i_china_dealsize10m_b2007 p_china_dealsize10m_b2007_n p_china_dealsize10m_b2007_su p_i_china_dealsize10m_b2007_n p_i_china_dealsize10m_b2007_su china_dealsize50m_b2007 i_china_dealsize50m_b2007 p_china_dealsize50m_b2007_n p_china_dealsize50m_b2007_su p_i_china_dealsize50m_b2007_n p_i_china_dealsize50m_b2007_su china_dealsize100m_b2007 i_china_dealsize100m_b2007 p_china_dealsize100m_b2007_n p_china_dealsize100m_b2007_su p_i_china_dealsize100m_b2007_n p_i_china_dealsize100m_b2007_su china_dealsize10m_b2008 i_china_dealsize10m_b2008 p_china_dealsize10m_b2008_n p_china_dealsize10m_b2008_su p_i_china_dealsize10m_b2008_n p_i_china_dealsize10m_b2008_su china_dealsize50m_b2008 i_china_dealsize50m_b2008 p_china_dealsize50m_b2008_n p_china_dealsize50m_b2008_su p_i_china_dealsize50m_b2008_n p_i_china_dealsize50m_b2008_su china_dealsize100m_b2008 i_china_dealsize100m_b2008 p_china_dealsize100m_b2008_n p_china_dealsize100m_b2008_su p_i_china_dealsize100m_b2008_n p_i_china_dealsize100m_b2008_su china_dealsize10m_b2009 i_china_dealsize10m_b2009 p_china_dealsize10m_b2009_n p_china_dealsize10m_b2009_su p_i_china_dealsize10m_b2009_n p_i_china_dealsize10m_b2009_su china_dealsize50m_b2009 i_china_dealsize50m_b2009 p_china_dealsize50m_b2009_n p_china_dealsize50m_b2009_su p_i_china_dealsize50m_b2009_n p_i_china_dealsize50m_b2009_su china_dealsize100m_b2009 i_china_dealsize100m_b2009 p_china_dealsize100m_b2009_n p_china_dealsize100m_b2009_su p_i_china_dealsize100m_b2009_n p_i_china_dealsize100m_b2009_su china_dealsize10m_b2010 i_china_dealsize10m_b2010 p_china_dealsize10m_b2010_n p_china_dealsize10m_b2010_su p_i_china_dealsize10m_b2010_n p_i_china_dealsize10m_b2010_su china_dealsize50m_b2010 i_china_dealsize50m_b2010 p_china_dealsize50m_b2010_n p_china_dealsize50m_b2010_su p_i_china_dealsize50m_b2010_n p_i_china_dealsize50m_b2010_su china_dealsize100m_b2010 i_china_dealsize100m_b2010 p_china_dealsize100m_b2010_n p_china_dealsize100m_b2010_su p_i_china_dealsize100m_b2010_n p_i_china_dealsize100m_b2010_su china_dealsize10m_b2011 i_china_dealsize10m_b2011 p_china_dealsize10m_b2011_n p_china_dealsize10m_b2011_su p_i_china_dealsize10m_b2011_n p_i_china_dealsize10m_b2011_su china_dealsize50m_b2011 i_china_dealsize50m_b2011 p_china_dealsize50m_b2011_n p_china_dealsize50m_b2011_su p_i_china_dealsize50m_b2011_n p_i_china_dealsize50m_b2011_su china_dealsize100m_b2011 i_china_dealsize100m_b2011 p_china_dealsize100m_b2011_n p_china_dealsize100m_b2011_su p_i_china_dealsize100m_b2011_n p_i_china_dealsize100m_b2011_su china_dealsize10m_b2012 i_china_dealsize10m_b2012 p_china_dealsize10m_b2012_n p_china_dealsize10m_b2012_su p_i_china_dealsize10m_b2012_n p_i_china_dealsize10m_b2012_su china_dealsize50m_b2012 i_china_dealsize50m_b2012 p_china_dealsize50m_b2012_n p_china_dealsize50m_b2012_su p_i_china_dealsize50m_b2012_n p_i_china_dealsize50m_b2012_su china_dealsize100m_b2012 i_china_dealsize100m_b2012 p_china_dealsize100m_b2012_n p_china_dealsize100m_b2012_su p_i_china_dealsize100m_b2012_n p_i_china_dealsize100m_b2012_su china_dealsize10m_b2013 i_china_dealsize10m_b2013 p_china_dealsize10m_b2013_n p_china_dealsize10m_b2013_su p_i_china_dealsize10m_b2013_n p_i_china_dealsize10m_b2013_su china_dealsize50m_b2013 i_china_dealsize50m_b2013 p_china_dealsize50m_b2013_n p_china_dealsize50m_b2013_su p_i_china_dealsize50m_b2013_n p_i_china_dealsize50m_b2013_su china_dealsize100m_b2013 i_china_dealsize100m_b2013 p_china_dealsize100m_b2013_n p_china_dealsize100m_b2013_su p_i_china_dealsize100m_b2013_n p_i_china_dealsize100m_b2013_su china_dealsize10m_b2014 i_china_dealsize10m_b2014 p_china_dealsize10m_b2014_n p_china_dealsize10m_b2014_su p_i_china_dealsize10m_b2014_n p_i_china_dealsize10m_b2014_su china_dealsize50m_b2014 i_china_dealsize50m_b2014 p_china_dealsize50m_b2014_n p_china_dealsize50m_b2014_su p_i_china_dealsize50m_b2014_n p_i_china_dealsize50m_b2014_su china_dealsize100m_b2014 i_china_dealsize100m_b2014 p_china_dealsize100m_b2014_n p_china_dealsize100m_b2014_su p_i_china_dealsize100m_b2014_n p_i_china_dealsize100m_b2014_su china_dealsize10m_b2015 i_china_dealsize10m_b2015 p_china_dealsize10m_b2015_n p_china_dealsize10m_b2015_su p_i_china_dealsize10m_b2015_n p_i_china_dealsize10m_b2015_su china_dealsize50m_b2015 i_china_dealsize50m_b2015 p_china_dealsize50m_b2015_n p_china_dealsize50m_b2015_su p_i_china_dealsize50m_b2015_n p_i_china_dealsize50m_b2015_su china_dealsize100m_b2015 i_china_dealsize100m_b2015 p_china_dealsize100m_b2015_n p_china_dealsize100m_b2015_su p_i_china_dealsize100m_b2015_n p_i_china_dealsize100m_b2015_su

global POL  "$TMP"
global DV   "$RAW/patent_resource"
global INV  "$TMP"
global PKGA "$TMP"

use "$TMP/regression_$saving_suffix", clear
di as txt "supplement start: vars=" c(k) " obs=" c(N)

merge m:1 subsegment using "$PKGA/EM_subseg_growth_rate.dta", keep(master match) nogen
merge m:1 subsegment using "$PKGA/EM_subseg_growth_rate_no_China.dta", keep(master match) nogen
di as result "supplement FINAL: vars=" c(k) " obs=" c(N) " (expected 1931 / 857380)"

save "$OUT/regression_corrected_120623.dta", replace
capture erase "$TMP/regression_corrected_120623.dta"
di as result "DONE regression -> Analysis/regression_corrected_120623.dta"
