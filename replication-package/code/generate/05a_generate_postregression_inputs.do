clear all
set more off
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
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global regression_file "$OUT/regression_corrected_120623.dta"
cap mkdir "$TMP"

use "$TMP/wdi_gdp_pc_matched.dta", clear
keep hqcountry mean_gdp_pc
keep if hqcountry != ""
merge 1:m hqcountry using "$regression_file", keepusing(subsegment1 suitability_score_wdi)
drop if _merge == 1
drop _merge
duplicates drop hqcountry subsegment1, force
drop if suitability_score_wdi == .
keep hqcountry subsegment1 suitability_score_wdi mean_gdp_pc
gen log_mean_gdp_pc = log(mean_gdp_pc)
regress suitability_score_wdi mean_gdp_pc if suitability_score_wdi != ., r
predict suitability_levelgdp, xb
predict suitability_res_levelgdp, residual
regress suitability_score_wdi log_mean_gdp_pc if suitability_score_wdi != ., r
predict suitability_loggdp, xb
predict suitability_res_loggdp, residual
encode subsegment1, gen(subsegment1_code)
regress suitability_score_wdi c.log_mean_gdp_pc#i.subsegment1_code if suitability_score_wdi != ., r
predict suitability_loggdp_macrosec, xb
predict suitability_res_loggdpmacrosec, residual
rename suitability_* suit_*
rename suit_score_wdi suitability_score_wdi
foreach var in suitability_score_wdi suit_levelgdp suit_res_levelgdp suit_loggdp suit_res_loggdp subsegment1_code suit_loggdp_macrosec suit_res_loggdpmacrosec {
	sum `var', d
	gen `var'_z = (`var' - r(mean))/r(sd)
}
sum suitability_score_wdi, d
local suit_sd = r(sd)
sum suit_levelgdp
gen suit_gdp_SD_z = (suit_levelgdp - r(mean))/`suit_sd'
sum suit_res_levelgdp
gen suit_res_SD_z = (suit_res_levelgdp - r(mean))/`suit_sd'
save "$TMP/suitability_gdp_component_detail.dta", replace
di as result "DONE suitability_gdp_component_detail -> intermediate_and_other_data"

global ZSCORE "$TMP/Combined_Z_score_results_allyears.dta"
global DETAIL "$TMP/suitability_gdp_component_detail.dta"

capture program drop _zassemble
program define _zassemble
    gen Z_score = .
    replace Z_score = Z_scores_AgTech                  if subsegment1 == "AgTech"
    replace Z_score = Z_scores_AI_ML                   if subsegment1 == "AI ML"
    replace Z_score = Z_scores_Blockchain              if subsegment1 == "Blockchain"
    replace Z_score = Z_scores_Carbon_and_Emissions_Te if subsegment1 == "Carbon and Emissions Tech"
    replace Z_score = Z_scores_DevOps                  if subsegment1 == "DevOps"
    replace Z_score = Z_scores_EdTech                  if subsegment1 == "EdTech"
    replace Z_score = Z_scores_Enterprise_Health       if subsegment1 == "Enterprise Health"
    replace Z_score = Z_scores_Fintech                 if subsegment1 == "Fintech"
    replace Z_score = Z_scores_FoodTech                if subsegment1 == "FoodTech"
    replace Z_score = Z_scores_InfoSec                 if subsegment1 == "InfoSec"
    replace Z_score = Z_scores_Insurtech               if subsegment1 == "Insurtech"
    replace Z_score = Z_scores_IoT                     if subsegment1 == "IoT"
    replace Z_score = Z_scores_MobilityTech            if subsegment1 == "MobilityTech"
    replace Z_score = Z_scores_Retail_HealthTech       if subsegment1 == "Retail HealthTech"
    replace Z_score = Z_scores_Supply_Chain_Tech       if subsegment1 == "Supply Chain Tech"
    sort subsegment hqcountry year
    isid subsegment hqcountry year
    gen l1_dealcount_norm_mean_00_12 = dealcount_norm_mean_00_12[_n-1] if year!= 2000
    gen l2_dealcount_norm_mean_00_12 = dealcount_norm_mean_00_12[_n-2] if year!= 2000 & year != 2001
    gen l3_dealcount_norm_mean_00_12 = dealcount_norm_mean_00_12[_n-3] if year!= 2000 & year != 2001 & year != 2002
    gen l1_yhat_CL_noFEcons_norm = yhat_CL_noFEcons_norm[_n-1] if year!= 2000
    gen l2_yhat_CL_noFEcons_norm = yhat_CL_noFEcons_norm[_n-2] if year!= 2000 & year != 2001
    gen l3_yhat_CL_noFEcons_norm = yhat_CL_noFEcons_norm[_n-3] if year!= 2000 & year != 2001 & year != 2002
    gen l1_yhat_CL_nocons_norm = yhat_CL_nocons_norm[_n-1] if year!= 2000
    gen l2_yhat_CL_nocons_norm = yhat_CL_nocons_norm[_n-2] if year!= 2000 & year != 2001
    gen l3_yhat_CL_nocons_norm = yhat_CL_nocons_norm[_n-3] if year!= 2000 & year != 2001 & year != 2002
    gen post = (year > 2013 & year <= 2019)
end

use "$regression_file", clear
reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(HY=hq#year HS=hq#subseg SY=subseg#year) vce(cluster hq)
gen yhat_CL_noFEcons_norm = _b[p2013_CL_countavg_loose_suit]*p2013_CL_countavg_loose_suit
gen yhat_CL_nocons_norm   = _b[p2013_CL_countavg_loose_suit]*p2013_CL_countavg_loose_suit + HY + HS + SY
merge m:1 country_2digit year using "$ZSCORE"
drop if _merge == 2
drop _merge
_zassemble
collapse (sum) dealcount_norm_mean_00_12 l1_dealcount_norm_mean_00_12 l2_dealcount_norm_mean_00_12 l3_dealcount_norm_mean_00_12 yhat_CL_noFEcons_norm l1_yhat_CL_noFEcons_norm l2_yhat_CL_noFEcons_norm l3_yhat_CL_noFEcons_norm yhat_CL_nocons_norm l1_yhat_CL_nocons_norm l2_yhat_CL_nocons_norm l3_yhat_CL_nocons_norm (mean) Z_score suitability_score_wdi OECD_b80s, by(hqcountry subsegment1 post)
gen relevant_sector = (subsegment1=="AgTech" | subsegment1=="EdTech" | subsegment1 == "Enterprise Health" | subsegment1=="Retail HealthTech")
gen Z_score_scale = Z_score*1000
replace yhat_CL_nocons_norm = 0 if yhat_CL_nocons_norm==.
encode subsegment1, gen(scode)
encode hqcountry, gen(hqcode)
gen suit_post = suitability_score_wdi*post
save "$TMP/indicator_regression.dta", replace

foreach spec in ///
    "p2013_CL_suit_z suitability_score_wdi_z indicator_regression_zscore.dta" ///
    "p2013_CL_suit_levelgdp_z suit_levelgdp_z indicator_regression_gdppc_zscore.dta" ///
    "p2013_CL_suit_res_levelgdp_z suit_res_levelgdp_z indicator_regression_gdpresidual_zscore.dta" {
    tokenize "`spec'"
    local zint "`1'"
    local suitvar "`2'"
    local outfile "`3'"
    use "$regression_file", clear
    merge m:1 hqcountry subsegment1 using "$DETAIL"
    drop if _merge == 2
    drop _merge
    gen p2013_CL_suit_z              = p2013_china_led_countavg_loose*suitability_score_wdi_z
    gen p2013_CL_suit_levelgdp_z     = p2013_china_led_countavg_loose*suit_levelgdp_z
    gen p2013_CL_suit_res_levelgdp_z = p2013_china_led_countavg_loose*suit_res_levelgdp_z
    reghdfe dealcount_norm_mean_00_12 `zint', absorb(HY=hq#year HS=hq#subseg SY=subseg#year) vce(cluster hq)
    gen yhat_CL_noFEcons_norm = _b[`zint']*`zint'
    gen yhat_CL_nocons_norm   = _b[`zint']*`zint' + HY + HS + SY
    merge m:1 country_2digit year using "$ZSCORE"
    drop if _merge == 2
    drop _merge
    _zassemble
    collapse (sum) dealcount_norm_mean_00_12 l1_dealcount_norm_mean_00_12 l2_dealcount_norm_mean_00_12 l3_dealcount_norm_mean_00_12 yhat_CL_noFEcons_norm l1_yhat_CL_noFEcons_norm l2_yhat_CL_noFEcons_norm l3_yhat_CL_noFEcons_norm yhat_CL_nocons_norm l1_yhat_CL_nocons_norm l2_yhat_CL_nocons_norm l3_yhat_CL_nocons_norm (mean) Z_score `suitvar' OECD_b80s, by(hqcountry subsegment1 post)
    gen relevant_sector = (subsegment1=="AgTech" | subsegment1=="EdTech" | subsegment1 == "Enterprise Health" | subsegment1=="Retail HealthTech")
    gen Z_score_scale = Z_score*1000
    replace yhat_CL_nocons_norm = 0 if yhat_CL_nocons_norm==.
    encode subsegment1, gen(scode)
    encode hqcountry, gen(hqcode)
    gen suit_post = `suitvar'*post
    save "$TMP/`outfile'", replace
}
di as result "DONE indicator_regression{,_zscore,_gdppc_zscore,_gdpresidual_zscore} -> intermediate_and_other_data"

use "$regression_file", clear
gen time = (year>=2013)
collapse (sum) dealcount_y dealsize_y (firstnm) s_quartile_sample_* s_quint_sample_* s_decile_sample_* q*_suit china_led_countavg_strict china_led_countavg_loose EM* OECD* suitability_score_wdi suitability_score_wdi_us (mean) size_per_deal, by(subseg time hq)
gen post = (time==1)
foreach var in dealcount_y dealsize_y size_per_deal {
	gen l`var' = log(`var')
	gen as_`var' = asinh(`var')
}
egen mean_deal_hq_temp_00_12 = mean(dealcount_y) if post < 1, by(hq)
egen mean_deal_hq_00_12 = max(mean_deal_hq_temp_00_12), by(hq)
drop mean_deal_hq_temp_00_12
gen dealcount_norm_mean_00_12 = dealcount_y/mean_deal_hq_00_12
egen mean_deal_hq_temp_00_12_ds = mean(dealsize_y) if post < 1, by(hq)
egen mean_deal_hq_00_12_ds = max(mean_deal_hq_temp_00_12_ds), by(hq)
drop mean_deal_hq_temp_00_12_ds
gen dealsize_norm_mean_00_12 = dealsize_y/mean_deal_hq_00_12_ds
gen xxx = dealcount_y if time == 0
egen total_pre_deals = max(xxx), by(subseg hq)
gen ltotal_pre_deals = log(total_pre_deals)
foreach var in china_led_countavg_strict china_led_countavg_loose {
	gen `var'_post = `var'*post
}
gen CL_suitChina = china_led_countavg_loose*suitability_score_wdi
gen UL_suitUS = (1-china_led_countavg_loose)*suitability_score_wdi_us
gen CL_suitUS = china_led_countavg_loose*suitability_score_wdi_us
gen UL_suitChina = (1-china_led_countavg_loose)*suitability_score_wdi
foreach var in CL_suitChina UL_suitUS CL_suitUS UL_suitChina {
	gen `var'_post = `var'*post
}
save "$TMP/US_China_pre_post_binscatter_regression.dta", replace
di as result "DONE US_China_pre_post_binscatter_regression -> intermediate_and_other_data"
