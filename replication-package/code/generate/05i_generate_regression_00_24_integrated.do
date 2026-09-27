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
global TMP   "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT   "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global BUILD "$TMP/a11cd_build"
global data_version "v2"

confirm file "$BUILD/deal_22_24.dta"

use "$TMP/deal_$data_version", clear
append using "$BUILD/deal_22_24"

fillin hqcountry fullname year
replace dealcount_y = 0 if _fillin == 1
replace dealsize_y = 0 if _fillin == 1

replace dealcount_china = 0 if _fillin == 1
replace dealcount_us = 0 if _fillin == 1
replace dealsize_china = 0 if _fillin == 1
replace dealsize_us = 0 if _fillin == 1

replace dealcount_y_us_inv = 0 if _fillin == 1
replace dealcount_y_local_inv = 0 if _fillin == 1
replace dealcount_y_china_inv = 0 if _fillin == 1
replace dealcount_y_other_inv = 0 if _fillin == 1

replace dealcount_y_us_inv_s = 0 if _fillin == 1
replace dealcount_y_local_inv_s = 0 if _fillin == 1
replace dealcount_y_china_inv_s = 0 if _fillin == 1
replace dealcount_y_other_inv_s = 0 if _fillin == 1

replace dealsize_y_us_inv_s = 0 if _fillin == 1
replace dealsize_y_local_inv_s = 0 if _fillin == 1
replace dealsize_y_china_inv_s = 0 if _fillin == 1
replace dealsize_y_other_inv_s = 0 if _fillin == 1

keep fullname hqcountry year dealcount_* dealsize_*

gen WB_high = 0

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list"
drop if _merge ==2
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s=0 if OECD_b80s==.

merge m:1 fullname using "$TMP/china_led_subsegments_avg_strict_dealcount_$data_version"
gen china_led_dealcountavg_strict = _merge
drop _merge
replace china_led_dealcountavg_strict = 0 if china_led_dealcountavg_strict == 1
replace china_led_dealcountavg_strict = 1 if china_led_dealcountavg_strict == 3

merge m:1 fullname using "$TMP/china_led_subsegments_avg_loose_dealcount_$data_version"
gen china_led_dealcountavg_loose = _merge
drop _merge
replace china_led_dealcountavg_loose = 0 if china_led_dealcountavg_loose == 1
replace china_led_dealcountavg_loose = 1 if china_led_dealcountavg_loose == 3

rename fullname subsegment
encode hqcountry, gen(hq)
encode subsegment, gen(subseg)

gen fullname_raw = ustrregexra(subsegment,"[^A-Za-z0-9]","")
replace fullname_raw = lower(fullname_raw)

split subsegment, p("|")

merge m:1 hqcountry using "$TMP/china_suitability_score_all_corrected"
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

sum suitability_score_wdi,d

replace suitability_score_wdi = 2.921 - suitability_score_wdi
drop *SuitSc

rename china_led_dealcountavg_loose china_led_countavg_loose
rename china_led_dealcountavg_strict china_led_countavg_strict

egen mean_deal_hq_temp_00_12 = mean(dealcount_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12 = max(mean_deal_hq_temp_00_12), by(hq)
drop mean_deal_hq_temp_00_12
gen dealcount_norm_mean_00_12 = dealcount_y/mean_deal_hq_00_12

egen mean_deal_hq_temp_00_12_ds = mean(dealsize_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12_ds = max(mean_deal_hq_temp_00_12_ds), by(hq)
drop mean_deal_hq_temp_00_12_ds
gen dealsize_norm_mean_00_12 = dealsize_y/mean_deal_hq_00_12_ds

gen post2013 = 1 if year > 2013
replace post2013 = 0 if post2013 ==.
foreach j of varlist china_led_countavg_loose china_led_countavg_strict {
	gen p2013_`j' = post2013 * `j'
}

gen p2013_CL_countavg_loose_suit = p2013_china_led_countavg_loose*suitability_score_wdi
gen p2013_CL_countavg_strict_suit = p2013_china_led_countavg_strict*suitability_score_wdi

gen ldealcount_y = log(dealcount_y)
gen ldealsize_y = log(dealsize_y)
gen as_dealcount_y = asinh(dealcount_y)
gen as_dealsize_y = asinh(dealsize_y)

gen size_per_deal = dealsize_y/dealcount_y
gen lsize_per_deal = log(size_per_deal)
gen as_size_per_deal = asinh(size_per_deal)

egen temp1 = sum(dealcount_y) if year<2013, by(subseg)
egen sum_ex_china_us = max(temp1), by(subseg)
egen temp2 = sum(dealcount_china) if year<2013, by(subseg hq)
egen sum_china = max(temp2), by(subseg)
egen temp3 = sum(dealcount_us) if year<2013, by(subseg hq)
egen sum_us = max(temp3), by(subseg)
gen total_pre_deals = sum_ex_china_us + sum_china + sum_us
gen ltotal_pre_deals = log(total_pre_deals)

gen post2021 = (year>2021)
gen p2013_CL_suit_p21 = p2013_CL_countavg_loose_suit *  post2021

save "$TMP/regression_00_24_integrated.dta", replace
count
tab year
di as result "DONE regression_00_24_integrated -> $TMP/regression_00_24_integrated.dta"
