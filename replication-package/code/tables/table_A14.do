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
global saving_suffix "corrected_120623.dta"
global regression_file "regression_$saving_suffix"

capture log close
log using "$LOG_DIR/tableA14.log", replace text

cd "$data_folder"
use $regression_file, clear
merge m:1 hqcountry using "$suit_output_folder/china_suitability_score_all_gpt_assigned.dta"
drop if _merge == 2
drop _merge

gen suitability_score_gpt = .
replace suitability_score_gpt = AgTech_SuitSc if subsegment1 == "AgTech"
replace suitability_score_gpt = AI_ML_SuitSc if subsegment1 == "AI ML"
replace suitability_score_gpt = Blockchain_SuitSc if subsegment1 == "Blockchain"
replace suitability_score_gpt = Carbon_and_Emissions_Tech_SuitSc if subsegment1 == "Carbon and Emissions Tech"
replace suitability_score_gpt = DevOps_SuitSc if subsegment1 == "DevOps"
replace suitability_score_gpt = EdTech_SuitSc if subsegment1 == "EdTech"
replace suitability_score_gpt = Enterprise_Health_SuitSc if subsegment1 == "Enterprise Health"
replace suitability_score_gpt = Fintech_SuitSc if subsegment1 == "Fintech"
replace suitability_score_gpt = FoodTech_SuitSc if subsegment1 == "FoodTech"
replace suitability_score_gpt = InfoSec_SuitSc if subsegment1 == "InfoSec"
replace suitability_score_gpt = Insurtech_SuitSc if subsegment1 == "Insurtech"
replace suitability_score_gpt = IoT_SuitSc  if subsegment1 == "IoT"
replace suitability_score_gpt = MobilityTech_SuitSc if subsegment1 == "MobilityTech"
replace suitability_score_gpt = Retail_HealthTech_SuitSc if subsegment1 == "Retail HealthTech"
replace suitability_score_gpt = Supply_Chain_Tech_SuitSc if subsegment1 == "Supply Chain Tech"
replace suitability_score_gpt = 4.141 - suitability_score_gpt
drop *SuitSc

gen p2013_CL_countavg_loose_suit_gpt = p2013_china_led_countavg_loose*suitability_score_gpt
gen p2013_CL_ctavg_strict_suit_gpt   = p2013_china_led_countavg_strict*suitability_score_gpt

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum dealcount_norm_mean_00_12 if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit_gpt, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum dealcount_norm_mean_00_12 if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit_gpt [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum dealcount_norm_mean_00_12 if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe as_dealcount_y p2013_CL_countavg_loose_suit_gpt if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum as_dealcount_y if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe as_dealsize_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum as_dealsize_y if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe as_dealsize_y p2013_CL_countavg_loose_suit_gpt if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum as_dealsize_y if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe lsize_per_deal p2013_CL_countavg_loose_suit_gpt if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
sum lsize_per_deal if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_loose_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_loose_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

esttab est* using "$INTERMEDIATE_DIR/tableA14_panelA.csv", se replace csv  order(p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_suit_gpt)  star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers nonotes coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness" p2013_CL_countavg_loose_suit_gpt "China-Led x Post x Appropriateness (GPT)") noobs

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_strict_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum dealcount_norm_mean_00_12 if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_strict_suit if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_strict_suit] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_ctavg_strict_suit_gpt, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum dealcount_norm_mean_00_12 if e(sample)
local ysd = r(sd)
sum p2013_CL_ctavg_strict_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_ctavg_strict_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_ctavg_strict_suit_gpt [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum dealcount_norm_mean_00_12 if e(sample)
local ysd = r(sd)
sum p2013_CL_ctavg_strict_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_ctavg_strict_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe as_dealcount_y p2013_CL_ctavg_strict_suit_gpt if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum as_dealcount_y if e(sample)
local ysd = r(sd)
sum p2013_CL_ctavg_strict_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_ctavg_strict_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe as_dealsize_y p2013_CL_countavg_strict_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum as_dealsize_y if e(sample)
local ysd = r(sd)
sum p2013_CL_countavg_strict_suit if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_countavg_strict_suit] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe as_dealsize_y p2013_CL_ctavg_strict_suit_gpt if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum as_dealsize_y if e(sample)
local ysd = r(sd)
sum p2013_CL_ctavg_strict_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_ctavg_strict_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

eststo: reghdfe lsize_per_deal p2013_CL_ctavg_strict_suit_gpt if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd local fe_ys "Yes"
quietly estadd ysumm, mean sd replace
sum lsize_per_deal if e(sample)
local ysd = r(sd)
sum p2013_CL_ctavg_strict_suit_gpt if e(sample)
local xsd = r(sd)
local xmean = r(mean)
quietly estadd scalar xmean = `xmean'
quietly estadd scalar xsd = `xsd'
local stdbeta = .
if `ysd' < . & `ysd' > 0 & `xsd' < . local stdbeta = _b[p2013_CL_ctavg_strict_suit_gpt] * `xsd' / `ysd'
quietly estadd scalar stdbeta = `stdbeta'

esttab est* using "$INTERMEDIATE_DIR/tableA14_panelB.csv", se replace csv  order(p2013_CL_countavg_strict_suit p2013_CL_ctavg_strict_suit_gpt )   ///
	star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f)  nobase nocons nomtitle nonumbers ///
	s( fe_sc fe_cy fe_sy fe_ys N ymean ysd, ///
	label("Sector x Country Fixed Effects" "Country x Year Fixed Effects" "Sector x Year Fixed Effects" "Appropriateness x Year Fixed Effects" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var" ) ///
	fmt( 0 0 0 0 0 3 3)) ///
	coeflabel(p2013_CL_countavg_strict_suit "China-Led x Post x Appropriateness" p2013_CL_ctavg_strict_suit_gpt "China-Led x Post x Appropriateness (GPT)")

tempname fh
file open `fh' using "$TABLE_DIR/tableA14.csv", write replace text
file write `fh' `","Deal Count","Deal Count","Deal Count","Deal Count","Deal Size","Deal Size","Deal Size""' _n
file write `fh' `","(1)","(2)","(3)","(4)","(5)","(6)","(7)""' _n
file write `fh' `","Baseline","Baseline","Weighted","asinh","asinh","asinh","log($/deal)""' _n
file write `fh' `""Panel A: Baseline China-led measure",,,,,,,"' _n

tempname pa
file open `pa' using "$INTERMEDIATE_DIR/tableA14_panelA.csv", read text
file read `pa' line
while r(eof)==0 {
    file write `fh' `"`line'"' _n
    file read `pa' line
}
file close `pa'

file write `fh' `""Panel B: Strict China-led measure",,,,,,,"' _n

file open `pa' using "$INTERMEDIATE_DIR/tableA14_panelB.csv", read text
file read `pa' line
while r(eof)==0 {
    file write `fh' `"`line'"' _n
    file read `pa' line
}
file close `pa'
file close `fh'

erase "$INTERMEDIATE_DIR/tableA14_panelA.csv"
erase "$INTERMEDIATE_DIR/tableA14_panelB.csv"

log close
