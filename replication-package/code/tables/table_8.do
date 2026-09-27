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

set maxvar 30000

capture log close
log using "$LOG_DIR/table8.log", replace text

cd "$data_folder"
local regfile "regression_corrected_120623.dta"

use "$intermediate_data_folder/wdi_gdp_pc_matched.dta", clear
keep hqcountry mean_gdp_pc
keep if hqcountry != ""
merge 1:m hqcountry using "`regfile'"
drop if _merge == 1
drop _merge
duplicates drop hqcountry subsegment1, force
drop if suitability_score_wdi==.
keep hqcountry subsegment1 suitability_score_wdi mean_gdp_pc
gen log_mean_gdp_pc = log(mean_gdp_pc)

regress suitability_score_wdi mean_gdp_pc if suitability_score_wdi!=., r
predict suitability_levelgdp, xb
predict suitability_res_levelgdp, residual

regress suitability_score_wdi log_mean_gdp_pc if suitability_score_wdi!=., r
predict suitability_loggdp, xb
predict suitability_res_loggdp, residual

encode subsegment1, gen(subsegment1_code)
regress suitability_score_wdi c.log_mean_gdp_pc#i.subsegment1_code if suitability_score_wdi!=., r
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

tempfile comp
save `comp', replace

use "`regfile'", clear
merge m:1 hqcountry subsegment1 using `comp'
drop if _merge == 2
drop _merge
gen p2013_CL_suit_z              = p2013_china_led_countavg_loose*suitability_score_wdi_z
gen p2013_CL_suit_levelgdp_z     = p2013_china_led_countavg_loose*suit_levelgdp_z
gen p2013_CL_suit_res_levelgdp_z = p2013_china_led_countavg_loose*suit_res_levelgdp_z

eststo clear
eststo: reghdfe by_serial_founder_F        p2013_CL_suit_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe serial_founder_all_CL_F    p2013_CL_suit_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe serial_founder_not_all_CL_F p2013_CL_suit_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe i_by_serial_founder_F      p2013_CL_suit_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe i_serial_founder_all_CL_F  p2013_CL_suit_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd ysumm, mean sd replace
eststo: reghdfe i_serial_founder_not_all_CL_F p2013_CL_suit_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd ysumm, mean sd replace

esttab est* using "$INTERMEDIATE_DIR/table8_panelA.csv", se replace csv order(p2013_CL_suit_z) compress ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
    nomtitle nonumbers ///
    s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
    coeflabel(p2013_CL_suit_z "China-Led x Post x Appropriateness (Z-score)")

eststo clear
eststo: reghdfe by_serial_founder_F        p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe serial_founder_all_CL_F    p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe serial_founder_not_all_CL_F p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe i_by_serial_founder_F      p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe i_serial_founder_all_CL_F  p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace
eststo: reghdfe i_serial_founder_not_all_CL_F p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$INTERMEDIATE_DIR/table8_panelB.csv", se replace csv ///
    order(p2013_CL_suit_levelgdp_z p2013_CL_suit_res_levelgdp_z) compress ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
    nomtitle nonumbers ///
    s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
    coeflabel(p2013_CL_suit_levelgdp_z "China-Led x Post x Appropriateness (GDP component Z-score)" ///
              p2013_CL_suit_res_levelgdp_z "China-Led x Post x Appropriateness (Residual component Z-score)")

tempname fh
file open `fh' using "$TABLE_DIR/table8.csv", write replace text
file write `fh' `","Number of Serial Entrepreneurs","Number of Serial Entrepreneurs","Number of Serial Entrepreneurs","Serial Entrepreneur Indicator","Serial Entrepreneur Indicator","Serial Entrepreneur Indicator""' _n
file write `fh' `","(1)","(2)","(3)","(4)","(5)","(6)""' _n
file write `fh' `","All","Only CL","Any non-CL","All","Only CL","Any non-CL""' _n
file write `fh' `""Panel A: Baseline Appropriateness",,,,,,"' _n

tempname pa
file open `pa' using "$INTERMEDIATE_DIR/table8_panelA.csv", read text
file read `pa' line
while r(eof)==0 {
    file write `fh' `"`line'"' _n
    file read `pa' line
}
file close `pa'

file write `fh' `""Panel B: Vertical versus Horizontal",,,,,,"' _n

file open `pa' using "$INTERMEDIATE_DIR/table8_panelB.csv", read text
file read `pa' line
while r(eof)==0 {
    file write `fh' `"`line'"' _n
    file read `pa' line
}
file close `pa'

file write `fh' `""Sector x Country FE","Yes","Yes","Yes","Yes","Yes","Yes""' _n
file write `fh' `""Country x Year FE","Yes","Yes","Yes","Yes","Yes","Yes""' _n
file write `fh' `""Sector x Year FE","Yes","Yes","Yes","Yes","Yes","Yes""' _n
file close `fh'

erase "$INTERMEDIATE_DIR/table8_panelA.csv"
erase "$INTERMEDIATE_DIR/table8_panelB.csv"

log close
