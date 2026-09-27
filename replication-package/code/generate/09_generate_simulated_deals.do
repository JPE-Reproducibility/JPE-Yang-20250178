version 19
args phase widx wtotal
if "`phase'" == "" local phase "all"
if "`widx'"  == "" local widx  1
if "`wtotal'" == "" local wtotal 1
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
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global SIM  "$TMP/simulation"
global data_version "v2"
global simulation_number = 500
cap mkdir "$TMP"
cap mkdir "$SIM"

global suit_long_cp "$TMP/suitability_score_all_countries_corrected.dta"
global china_suit   "$TMP/china_suitability_score_all_corrected.dta"
global crosswalk    "$RAW/suitability_resource/country_crosswalk.dta"

if inlist("`phase'", "all", "prep") {
use "$OUT/analysis_$data_version.dta", clear
gen count = 1
merge m:1 hqcountry using "$china_suit"
collapse (count) count (mean) AI_ML_SuitSc, by(hqcountry)

preserve
drop if AI_ML_SuitSc==.
drop if hqcountry == "United States"
levelsof hqcountry, local(country_list)
restore

use "$suit_long_cp", clear
rename Carbon_and_Emissions_Tech_SuitSc Carbon_SuitSc
rename hqcountry hqcountry_base
drop country_2digit
rename relative_to country_2digit
merge m:1 country_2digit using "$crosswalk"
drop if _merge == 2
drop _merge
drop country_2digit
rename hqcountry relative_to
rename hqcountry_base hqcountry
drop if hqcountry== ""
drop if relative_to == ""

foreach country in `country_list' {
	preserve
	keep if relative_to == "`country'"
	drop relative_to
	save "$SIM/suitability_wrt_`country'.dta", replace
	restore
}

use "$TMP/dealcount_$data_version.dta", clear
keep if year <=2019 & year >= 2015
duplicates drop fullname year, force
keep fullname year dealcount_china dealcount_us
collapse (mean) dealcount_china dealcount_us, by(fullname)

forvalues i = 1/$simulation_number {
	preserve
	set seed `i'
	sample 69, count
	gen X_led_countavg_strict_`i' = 1
	save "$SIM/X_led_countavg_strict_`i'.dta", replace
	restore
}

import excel using "$RAW/suitability_resource/WDI_full.xlsx", clear
nrow 1
rename A hqcountry
keep if C == "GDP (current US$)"
keep hqcountry _2019__YR2019_
rename _2019__YR2019_ GDP_2019_USD
replace GDP_2019_USD = "" if GDP_2019_USD == ".."

destring GDP_2019_USD, replace
gen GDP_2019_USD_B = GDP_2019_USD/1000000000
gen ratio_to_China = GDP_2019_USD_B/14279.9
gen sectors_to_lead = round(ratio_to_China*69, 1)

replace hqcountry = "The Gambia" if hqcountry == "Gambia, The"
replace hqcountry = "South Korea" if hqcountry == "Korea, Rep."
replace hqcountry = "Macedonia" if hqcountry == "North Macedonia"
replace hqcountry = "Saint Lucia" if hqcountry == "St. Lucia"
replace hqcountry = "Iran" if hqcountry == "Iran, Islamic Rep."
replace hqcountry = "Egypt" if hqcountry == "Egypt, Arab Rep."
replace hqcountry = "Venezuela" if hqcountry == "Venezuela, RB"
replace hqcountry = "Yemen" if hqcountry == "Yemen, Rep."
replace hqcountry = "Congo" if hqcountry == "Congo, Rep."
replace hqcountry = "Czech Republic" if hqcountry == "Czechia"
replace hqcountry = "Kyrgyzstan" if hqcountry == "Kyrgyz Republic"
replace hqcountry = "Russia" if hqcountry == "Russian Federation"
replace hqcountry = "Slovakia" if hqcountry == "Slovak Republic"
replace hqcountry = "Syria" if hqcountry == "Syrian Arab Republic"
replace hqcountry = "Turkey" if hqcountry == "Turkiye"
replace hqcountry = "Brunei" if hqcountry == "Brunei Darussalam"
replace hqcountry = "Vietnam" if hqcountry == "Viet Nam"
save "$SIM/country_GDP_2019.dta", replace

use "$OUT/analysis_$data_version.dta", clear
gen count = 1
merge m:1 hqcountry using "$china_suit"
collapse (count) count (mean) AI_ML_SuitSc, by(hqcountry)
preserve
drop if AI_ML_SuitSc==.
drop if hqcountry == "United States"
levelsof hqcountry, local(country_list)
restore

foreach country in `country_list' {
	use "$SIM/country_GDP_2019.dta", clear
	sum sectors_to_lead if hqcountry == "`country'"
	local number_to_sample = r(max)
	if `number_to_sample' == 0 | `number_to_sample' == . {
		continue
	}
	else {
		use "$TMP/dealcount_$data_version.dta", clear
		keep if year <=2019 & year >= 2015
		duplicates drop fullname year, force
		keep fullname year dealcount_china dealcount_us
		collapse (mean) dealcount_china dealcount_us, by(fullname)

		forvalues i = 1/$simulation_number {
			preserve
			set seed `i'
			sample `number_to_sample', count
			gen X_led_countavg_strict_`i'_GDPadj = 1
			save "$SIM/X_led_countavg_strict_`country'_GDP_adjusted_`i'.dta", replace
			restore
		}
	}
}

use "$OUT/analysis_$data_version.dta", clear
gen count = 1
merge m:1 hqcountry using "$china_suit"
collapse (count) count (mean) AI_ML_SuitSc, by(hqcountry)
preserve
drop if AI_ML_SuitSc==.
drop if hqcountry == "United States"
merge m:1 hqcountry using "$SIM/country_GDP_2019.dta"
keep if sectors_to_lead > 0 & sectors_to_lead !=. & _merge == 3
levelsof hqcountry, local(country_list)
restore

foreach country in `country_list' {
	use "$SIM/X_led_countavg_strict_`country'_GDP_adjusted_1.dta", clear
	rename  X_led_countavg_strict_1_GDPadj  GDPadj_X_led_countavg_strict_1
	forvalues i = 2/$simulation_number {
		merge m:1 fullname using "$SIM/X_led_countavg_strict_`country'_GDP_adjusted_`i'.dta"
		rename  X_led_countavg_strict_`i'_GDPadj  GDPadj_X_led_countavg_strict_`i'
		replace GDPadj_X_led_countavg_strict_`i' = 0 if GDPadj_X_led_countavg_strict_`i'==.
		drop _merge
	}
	save "$SIM/X_led_countavg_strict_`country'_GDP_adjusted_all.dta", replace
}

use "$OUT/analysis_$data_version.dta", clear
drop if hqcountry == "United States"

gen count =1
collapse (sum) count dealsize , by(hqcountry fullname year OECD_b80s)
rename count dealcount_y
rename dealsize dealsize_y

bysort fullname: egen dealcount_y_sum = total(dealcount_y)
bysort fullname: egen dealcount_y_sum_china = total(dealcount_y) if hqcountry == "China"
gen china_only = (dealcount_y_sum == dealcount_y_sum_china)
drop if china_only == 1
drop dealcount_y_sum dealcount_y_sum_china china_only

fillin hqcountry fullname year
replace dealcount_y = 0 if _fillin == 1
replace dealsize_y = 0 if _fillin == 1

keep fullname hqcountry year dealcount_y* dealsize_y*
merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list.dta"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s=0 if OECD_b80s==.

merge m:1 fullname using "$TMP/china_led_subsegments_avg_strict_dealcount_$data_version.dta"
gen china_led_dealcountavg_strict = _merge
drop if _merge == 2
drop _merge
replace china_led_dealcountavg_strict = 0 if china_led_dealcountavg_strict == 1
replace china_led_dealcountavg_strict = 1 if china_led_dealcountavg_strict == 3

rename fullname subsegment
split subsegment, p("|")

merge m:1 hqcountry using "$china_suit"
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

* re-zero at the within-macro-sector max (the print Table A8 convention)
bysort subsegment1: egen max_suit = max(suitability_score_wdi)
replace suitability_score_wdi = max_suit-suitability_score_wdi
drop *_SuitSc
order suitability_score_wdi, b(hq)

rename china_led_dealcountavg_strict china_led_countavg_strict

egen mean_deal_hq_temp_00_12 = mean(dealcount_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12 = max(mean_deal_hq_temp_00_12), by(hq)
drop mean_deal_hq_temp_00_12
gen dealcount_norm_mean_00_12 = dealcount_y/mean_deal_hq_00_12

egen mean_deal_hq_temp_00_12_ds = mean(dealsize_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12_ds = max(mean_deal_hq_temp_00_12_ds), by(hq)
drop mean_deal_hq_temp_00_12_ds
gen dealsize_norm_mean_00_12 = dealsize_y/mean_deal_hq_00_12_ds

encode hqcountry, gen(hq)
encode subsegment, gen(subseg)

rename subsegment fullname
forvalues i = 1/$simulation_number {
	merge m:1 fullname using "$SIM/X_led_countavg_strict_`i'.dta"
	replace X_led_countavg_strict_`i' = 0 if X_led_countavg_strict_`i'==.
	drop if _merge == 2
	drop _merge
}
rename fullname subsegment

keep if year<= 2019 & hqcountry !="China"

gen post2013 = 1 if year > 2013
replace post2013 = 0 if post2013 ==.
gen p2013_china_led_countavg_strict = post2013 * china_led_countavg_strict
gen p2013_CL_countavg_strict_suit = p2013_china_led_countavg_strict*suitability_score_wdi

drop if subsegment == ""
drop if hqcountry == ""
drop OECD ChinaPlusUS share_china subsegment2 subsegment3

save "$SIM/simulation_regression_baseline.dta", replace
}

if inlist("`phase'", "all", "regcache") {
use "$SIM/simulation_regression_baseline.dta", clear

merge m:1 hqcountry using "$SIM/suitability_wrt_Australia.dta"
drop if _merge == 2
drop _merge

reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit, absorb(HY=hq#year HS=hq#subseg SY=subseg#year) vce(cluster hq) resid
quietly gen yhat_CL_norm = _b[p2013_CL_countavg_strict_suit]*p2013_CL_countavg_strict_suit + HY + HS + SY + _b[_cons]
quietly gen yhat_CL = yhat_CL_norm*mean_deal_hq_00_12
quietly gen yhat_CL_noFE_norm = _b[p2013_CL_countavg_strict_suit]*p2013_CL_countavg_strict_suit
quietly gen yhat_CL_noFE = yhat_CL_noFE_norm*mean_deal_hq_00_12
quietly gen beta_dealcount = _b[p2013_CL_countavg_strict_suit]
quietly gen cons_dealcount = _b[_cons]
rename _reghdfe_resid reghdfe_resid1

reghdfe dealsize_norm_mean_00_12 p2013_CL_countavg_strict_suit, absorb(HY2=hq#year HS2=hq#subseg SY2=subseg#year) vce(cluster hq) resid
quietly gen yhat_CL_ds_norm  = _b[p2013_CL_countavg_strict_suit]*p2013_CL_countavg_strict_suit + HY2 + HS2 + SY2 + _b[_cons]
quietly gen yhat_CL_ds = yhat_CL_ds_norm*mean_deal_hq_00_12
quietly gen yhat_CL_ds_noFE_norm = _b[p2013_CL_countavg_strict_suit]*p2013_CL_countavg_strict_suit
quietly gen yhat_CL_ds_noFE = yhat_CL_ds_noFE*mean_deal_hq_00_12_ds
quietly gen beta_dealsize = _b[p2013_CL_countavg_strict_suit]
quietly gen cons_dealsize = _b[_cons]
rename _reghdfe_resid reghdfe_resid2

drop *_SuitSc

save "$SIM/simulation_regression_regcache.dta", replace
}

if inlist("`phase'", "all", "simulate") {
local unit = 0
forvalues batch_num = 1/5 {
	local start_num = (`batch_num'-1)*100 + 1
	local end_num   = `batch_num'*100
	local tag       = `batch_num'*100

	use "$SIM/simulation_regression_regcache.dta", clear

	preserve
	use "$OUT/analysis_$data_version.dta", clear
	gen count = 1
	merge m:1 hqcountry using "$china_suit"
	collapse (count) count (mean) AI_ML_SuitSc, by(hqcountry)
	drop if AI_ML_SuitSc==.
	drop if hqcountry == "United States"
	merge 1:1 hqcountry using "$SIM/country_GDP_2019.dta"
	keep if _merge == 3
	keep if sectors_to_lead > 0 & sectors_to_lead !=.
	levelsof hqcountry, local(country_list)
	restore

	foreach country in `country_list' {
		local ++unit
		if mod(`unit'-1, `wtotal') != `widx'-1 continue
		if "`phase'" == "simulate" {
			capture confirm file "$SIM/simulated_deals_`country'_`tag'.dta"
			if !_rc {
				display "worker `widx': skipping `country' batch `batch_num' (already done)"
				continue
			}
		}
		preserve
		merge m:1 hqcountry using "$SIM/suitability_wrt_`country'.dta"
		drop if _merge == 2
		drop _merge

		rename *_SuitSc *_SuitSc_X
		quietly gen suitability_score_wdi_X = .
		quietly replace suitability_score_wdi_X = AgTech_SuitSc_X if subsegment1 == "AgTech"
		quietly replace suitability_score_wdi_X = AI_ML_SuitSc_X if subsegment1 == "AI ML"
		quietly replace suitability_score_wdi_X = Blockchain_SuitSc_X if subsegment1 == "Blockchain"
		quietly replace suitability_score_wdi_X = Carbon_SuitSc_X if subsegment1 == "Carbon and Emissions Tech"
		quietly replace suitability_score_wdi_X = DevOps_SuitSc_X if subsegment1 == "DevOps"
		quietly replace suitability_score_wdi_X = EdTech_SuitSc_X if subsegment1 == "EdTech"
		quietly replace suitability_score_wdi_X = Enterprise_Health_SuitSc_X if subsegment1 == "Enterprise Health"
		quietly replace suitability_score_wdi_X = Fintech_SuitSc_X if subsegment1 == "Fintech"
		quietly replace suitability_score_wdi_X = FoodTech_SuitSc_X if subsegment1 == "FoodTech"
		quietly replace suitability_score_wdi_X = InfoSec_SuitSc_X if subsegment1 == "InfoSec"
		quietly replace suitability_score_wdi_X = Insurtech_SuitSc_X if subsegment1 == "Insurtech"
		quietly replace suitability_score_wdi_X = IoT_SuitSc_X  if subsegment1 == "IoT"
		quietly replace suitability_score_wdi_X = MobilityTech_SuitSc_X if subsegment1 == "MobilityTech"
		quietly replace suitability_score_wdi_X = Retail_HealthTech_SuitSc_X if subsegment1 == "Retail HealthTech"
		quietly replace suitability_score_wdi_X = Supply_Chain_Tech_SuitSc_X if subsegment1 == "Supply Chain Tech"

		order  suitability_score_wdi_X, b(hq)
		drop *_SuitSc_X

		* re-zero at the within-macro-sector max (the print Table A8 convention)
		bysort subsegment1: egen max_suitability_score_wdi_X = max(suitability_score_wdi_X)
		quietly replace suitability_score_wdi_X = max_suitability_score_wdi_X - suitability_score_wdi_X

		drop subsegment1
		quietly drop if subsegment == ""
		quietly gen X_led = 0
		quietly gen p2013_CL_countavg_strict_suit_X = p2013_china_led_countavg_strict*suitability_score_wdi_X

		rename subsegment fullname
		quietly merge m:1 fullname using "$SIM/X_led_countavg_strict_`country'_GDP_adjusted_all.dta"
		drop if _merge == 2
		drop _merge

		forvalues i = `start_num'/`end_num' {
			quietly replace GDPadj_X_led_countavg_strict_`i' = 0 if GDPadj_X_led_countavg_strict_`i'==.

			quietly gen p2013_X_led_countavg_strict_`i' = post2013 * X_led_countavg_strict_`i'
			quietly gen p2013_X_led_CA_strict_`i'_GDP = post2013 * GDPadj_X_led_countavg_strict_`i'
			quietly gen p2013_X_countavg_strict_suit_`i' = p2013_X_led_countavg_strict_`i'*suitability_score_wdi_X
			quietly gen p2013_X_CA_strict_suit_`i'_GDP = p2013_X_led_CA_strict_`i'_GDP*suitability_score_wdi_X

			drop p2013_X_led_countavg_strict_`i' p2013_X_led_CA_strict_`i'_GDP

			quietly gen yhat_X_`i' = beta_dealcount*p2013_X_countavg_strict_suit_`i' + HY + HS + SY + cons_dealcount
			quietly gen yhat_X_rawdeals_`i' = yhat_X_`i'*mean_deal_hq_00_12
			drop yhat_X_`i'

			quietly gen yhat_X_noFE_`i' = beta_dealcount*p2013_X_countavg_strict_suit_`i'
			quietly gen yhat_X_noFE_rawdeals_`i' = yhat_X_noFE_`i'*mean_deal_hq_00_12
			drop yhat_X_noFE_`i'

			quietly gen yhat_X_`i'_GDP = beta_dealcount*p2013_X_CA_strict_suit_`i'_GDP + HY + HS + SY +cons_dealcount
			quietly gen yhat_X_GDP_rawdeals_`i' = yhat_X_`i'_GDP*mean_deal_hq_00_12
			drop yhat_X_`i'_GDP

			quietly gen yhat_X_noFE_GDP_`i' = beta_dealcount*p2013_X_CA_strict_suit_`i'_GDP
			quietly gen yhat_X_noFE_GDP_rawdeals_`i' = yhat_X_noFE_GDP_`i'*mean_deal_hq_00_12
			drop yhat_X_noFE_GDP_`i'

			quietly gen yhat_X_ds_`i' = beta_dealsize*p2013_X_countavg_strict_suit_`i' + HY2 + HS2 + SY2 + cons_dealsize
			quietly gen yhat_X_ds_rawdeals_`i' = yhat_X_ds_`i'*mean_deal_hq_00_12_ds
			drop yhat_X_ds_`i'

			quietly gen yhat_X_noFE_ds_`i' = beta_dealsize*p2013_X_countavg_strict_suit_`i'
			quietly gen yhat_X_noFE_ds_rawdeals_`i' = yhat_X_noFE_ds_`i'*mean_deal_hq_00_12_ds
			drop yhat_X_noFE_ds_`i'

			quietly gen yhat_X_ds_`i'_GDP = beta_dealsize*p2013_X_CA_strict_suit_`i'_GDP + HY2 + HS2 + SY2 + cons_dealsize
			quietly gen yhat_X_GDP_ds_rawdeals_`i' = yhat_X_ds_`i'_GDP*mean_deal_hq_00_12_ds
			drop yhat_X_ds_`i'_GDP

			quietly gen yhat_X_noFE_GDP_ds_`i' = beta_dealsize*p2013_X_CA_strict_suit_`i'_GDP
			quietly gen yhat_X_noFE_GDP_ds_rawdeals_`i' = yhat_X_noFE_GDP_ds_`i'*mean_deal_hq_00_12_ds
			drop yhat_X_noFE_GDP_ds_`i'

			drop p2013*
			display "`i'"
		}
		rename fullname subsegment

		collapse (sum) dealcount_y yhat_CL yhat_CL_noFE yhat_CL_ds yhat_CL_ds_noFE yhat_X_rawdeals* yhat_X_GDP_rawdeals* yhat_X_ds_rawdeals* yhat_X_GDP_ds_rawdeals* yhat_X_noFE_rawdeals* yhat_X_noFE_GDP_rawdeals* yhat_X_noFE_ds_rawdeals* yhat_X_noFE_GDP_ds_*, by(year OECD_b80s)
		keep if year == 2019

		quietly egen mean_sim_deals = rowmean(yhat_X_rawdeals*)
		quietly egen mean_sim_deals_GDP = rowmean(yhat_X_GDP_rawdeals*)
		quietly egen mean_sim_deals_ds = rowmean(yhat_X_ds_rawdeals*)
		quietly egen mean_sim_deals_GDP_ds = rowmean(yhat_X_GDP_ds_rawdeals*)

		quietly egen mean_simulated_deals_noFE = rowmean(yhat_X_noFE_rawdeals*)
		quietly egen mean_simulated_deals_GDP_noFE = rowmean(yhat_X_noFE_GDP_rawdeals*)
		quietly egen mean_simulated_deals_ds_noFE = rowmean(yhat_X_noFE_ds_rawdeals*)
		quietly egen mean_simulated_deals_GDP_ds_noFE = rowmean(yhat_X_noFE_GDP_ds*)

		order mean_sim*, b(OECD_b80s)

		gen simulated_country = "`country'"
		save "$SIM/simulated_deals_`country'_`tag'.dta", replace
		display "`country' batch `batch_num' finished"
		restore
	}
}
}

if inlist("`phase'", "all", "assemble") {
use "$SIM/simulation_regression_baseline.dta", clear
preserve
use "$OUT/analysis_$data_version.dta", clear
gen count = 1
merge m:1 hqcountry using "$china_suit"
collapse (count) count (mean) AI_ML_SuitSc, by(hqcountry)
drop if AI_ML_SuitSc==.
drop if hqcountry == "United States"
merge 1:1 hqcountry using "$SIM/country_GDP_2019.dta"
keep if _merge == 3
keep if sectors_to_lead > 0 & sectors_to_lead !=.
levelsof hqcountry, local(country_list)
restore

foreach country in `country_list' {
	use "$SIM/simulated_deals_`country'_100.dta", clear
	drop mean*
	forvalues i=2/5 {
		merge 1:1 simulated_country year OECD_b80s using "$SIM/simulated_deals_`country'_`i'00.dta"
		drop _merge
		drop mean*
	}
	egen mean_simulated_deals = rowmean(yhat_X_rawdeals*)
	egen mean_simulated_deals_GDP = rowmean(yhat_X_GDP_rawdeals*)
	egen mean_simulated_deals_ds = rowmean(yhat_X_ds_rawdeals*)
	egen mean_simulated_deals_GDP_ds = rowmean(yhat_X_GDP_ds_rawdeals*)

	egen mean_simulated_deals_noFE = rowmean(yhat_X_noFE_rawdeals*)
	egen mean_simulated_deals_GDP_noFE = rowmean(yhat_X_noFE_GDP_rawdeals*)
	egen mean_simulated_deals_ds_noFE = rowmean(yhat_X_noFE_ds_rawdeals*)
	egen mean_simulated_deals_GDP_ds_noFE = rowmean(yhat_X_noFE_GDP_ds*)

	order mean_sim*, b(OECD_b80s)
	save "$SIM/simulated_deals_`country'_all.dta", replace
}

clear all
foreach country in `country_list' {
	append using "$SIM/simulated_deals_`country'_all.dta"
}

order simulated_country
save "$TMP/simulated_deals_all_1_500.dta", replace
di as result "DONE simulated_deals_all_1_500 -> intermediate_and_other_data"

cap shell rm -rf "$SIM"
if "`c(os)'" == "Windows" {
    local _del = subinstr("$SIM", "/", "\", .)
    cap shell rmdir /s /q "`_del'"
}
}
