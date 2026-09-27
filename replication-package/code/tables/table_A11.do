clear all

if "$REPLICATION_ROOT" == "" {
    local _r "."
    forvalues _i = 1/6 {
        capture confirm file "`_r'/code/auxiliary/paths.do"
        if !_rc {
            global REPLICATION_ROOT "`_r'"
            continue, break
        }
        local _r "`_r'/.."
    }
}
if "$REPLICATION_ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root (or any folder inside it), or set the global REPLICATION_ROOT first."
    exit 601
}
include "$REPLICATION_ROOT/code/auxiliary/paths.do"

global suffix "corrected"
global data_version "v2"
global suit_all suitability_score_all_$suffix

capture log close
log using "$LOG_DIR/tableA11.log", replace text

local out "$TABLE_DIR/tableA11.csv"

cd "$intermediate_data_folder"
use dealcount_size_alltype.dta, clear

merge 1:1 subsegment year hqcountry using regression_2000_2021
replace dealcount_alltype=0 if dealcount_alltype==.
replace dealsize_alltype=0 if dealsize_alltype==.
drop _merge

keep dealcount_alltype dealsize_alltype subsegment hqcountry year dealcount_y dealsize_y OECD_b80s dealcount_china dealcount_us dealsize_china dealsize_us china_led_dealcountavg_strict china_led_dealcountavg_loose suitability_score2 hq subseg

foreach var of varlist china_led_dealcountavg_strict china_led_dealcountavg_loose{
	bysort subsegment: egen m_`var' = max(`var')
	replace `var' = m_`var' if `var'==.
	drop m_`var'
}

bysort hqcountry: egen m_OECD_b80s = max(OECD_b80s)
replace OECD_b80s = m_OECD_b80s if OECD_b80s==.
drop m_OECD_b80s

drop  suitability_score2

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
replace suitability_score_wdi = 10 - suitability_score_wdi

drop *SuitSc
rename subsegment fullname

cd "$intermediate_data_folder"
merge m:1 fullname using china_led_subsegments_avg_loose_dealcount_to_world_$data_version
gen CL_countavg_loose_CtoW = 1 if _merge == 3
replace CL_countavg_loose_CtoW = 0 if _merge == 1
drop _merge
rename  fullname subsegment
drop share_china_to_world

rename china_led_dealcountavg_loose china_led_countavg_loose
rename china_led_dealcountavg_strict china_led_countavg_strict

egen mean_deal_hq_temp_00_12 = mean(dealcount_y) if year < 2013, by(hq)
egen mean_deal_hq_00_12 = max(mean_deal_hq_temp_00_12), by(hq)
drop mean_deal_hq_temp_00_12
gen dealcount_norm_mean_00_12 = dealcount_y/mean_deal_hq_00_12

gen post2013 = 1 if year > 2013
replace post2013 = 0 if post2013 ==.
foreach j of varlist china_led_countavg_loose china_led_countavg_strict CL_countavg_loose_CtoW {
	gen p2013_`j' = post2013 * `j'
}
gen p2013_CL_countavg_loose_suit = p2013_china_led_countavg_loose*suitability_score_wdi
gen p2013_CL_countavg_strict_suit = p2013_china_led_countavg_strict*suitability_score_wdi

gen as_dealcount_y = asinh(dealcount_y)
gen as_dealsize_y = asinh(dealsize_y)
gen size_per_deal = dealsize_y/dealcount_y
gen lsize_per_deal = log(size_per_deal)

egen temp1 = sum(dealcount_y) if year<2013, by(subseg)
egen sum_ex_china_us = max(temp1), by(subseg)
egen temp2 = sum(dealcount_china) if year<2013, by(subseg hq)
egen sum_china = max(temp2), by(subseg)
egen temp3 = sum(dealcount_us) if year<2013, by(subseg hq)
egen sum_us = max(temp3), by(subseg)
gen total_pre_deals = sum_ex_china_us + sum_china + sum_us
gen ltotal_pre_deals = log(total_pre_deals)

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe as_dealcount_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe as_dealsize_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe lsize_per_deal p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)

esttab est* using "`out'", se replace csv ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
	order(p2013_CL_countavg_loose_suit) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness") ///
	prehead(`","Deal Count","Deal Count","Deal Count","Deal Size","Deal Size""' `","(1)","(2)","(3)","(4)","(5)""' `","Baseline","Weighted","asinh","asinh","log($/deal)""' `""Panel A: Baseline China-led measure, 2000-2021",,,,,"') ///
	posthead("") prefoot("") postfoot(`""Panel B: Strict China-led measure, 2000-2021",,,,,"')

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe as_dealcount_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe as_dealsize_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe lsize_per_deal p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace

esttab est* using "`out'", se append csv ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
	order(p2013_CL_countavg_strict_suit) ///
	s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
	coeflabel(p2013_CL_countavg_strict_suit "China-Led Sector (Strict) x Post x Appropriateness") ///
	prehead("") posthead("") prefoot("") postfoot(`""Panel C: Baseline China-led measure, 2000-2024",,,,,"')

cd "$intermediate_data_folder"
use regression_00_24_integrated.dta, clear

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe as_dealcount_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe as_dealsize_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
eststo: reghdfe lsize_per_deal p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)

esttab est* using "`out'", se append csv ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
	order(p2013_CL_countavg_loose_suit) ///
	coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness") ///
	prehead("") posthead("") prefoot("") postfoot(`""Panel D: Strict China-led measure, 2000-2024",,,,,"')

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe as_dealcount_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe as_dealsize_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe lsize_per_deal p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd ysumm, mean sd replace

esttab est* using "`out'", se append csv ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
	order(p2013_CL_countavg_strict_suit) ///
	s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
	coeflabel(p2013_CL_countavg_strict_suit "China-Led Sector (Strict) x Post x Appropriateness") ///
	prehead("") posthead("") prefoot("") ///
	postfoot(`""Sector x Country FE","Yes","Yes","Yes","Yes","Yes""' `""Country x Year FE","Yes","Yes","Yes","Yes","Yes""' `""Sector x Year FE","Yes","Yes","Yes","Yes","Yes""' `""Appropriateness x Year FE","Yes","Yes","Yes","Yes","Yes""')

log close
