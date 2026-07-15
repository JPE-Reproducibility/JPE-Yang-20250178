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
log using "$LOG_DIR/tableA7.log", replace text

cd "$data_folder"
use $regression_file, clear
merge m:1 hqcountry using "$intermediate_data_folder/gdp_pp_2015usd.dta"
cd "$data_folder"

sum gdp_pp_2015usd_mean_preperiod if gdp_pp_preperiod_above_china==0,d
gen just_below_china_50 = gdp_pp_preperiod_above_china==0 & gdp_pp_2015usd_mean_preperiod>1608.274
gen just_below_china_75 = gdp_pp_preperiod_above_china==0 & gdp_pp_2015usd_mean_preperiod>2626.119

gen p2013_CL_countavg_loose_above    = p2013_china_led_countavg_loose*gdp_pp_preperiod_above_china
gen p2013_CL_countavg_loose_gdp      = p2013_china_led_countavg_loose*log(gdp_pp_2015usd_mean_preperiod)
gen p2013_CL_countavg_loose_gdp_post = p2013_china_led_countavg_loose*log(gdp_pp_2015usd_mean_postperiod)
gen p2013_CL_countavg_loose_below50  = p2013_china_led_countavg_loose*just_below_china_50
gen p2013_CL_countavg_loose_below75  = p2013_china_led_countavg_loose*just_below_china_75

eststo clear
eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_above, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_gdp, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_gdp_post, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_below50, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_below75, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
quietly estadd local fe_sc "Yes"
quietly estadd local fe_cy "Yes"
quietly estadd local fe_sy "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA7.csv", se replace csv order(p2013_CL_countavg_loose_suit p2013_CL_countavg_loose_above p2013_CL_countavg_loose_gdp p2013_CL_countavg_loose_gdp_post p2013_CL_countavg_loose_below50 p2013_CL_countavg_loose_below75)   ///
star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f)  nobase nocons  nomtitle ///
s(fe_sc fe_cy fe_sy N ymean ysd, ///
label("Sector x Country FE" "Country x Year FE" "Sector x Year FE"  "Number of Obs"  "Mean of Dep. Var" "SD of Dep. Var") ///
fmt(0 0 0 0  3 3)) ///
coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness" p2013_CL_countavg_loose_above "China-Led Sector x Post x Appropriateness x GDP pc above China (Pre)" p2013_CL_countavg_loose_gdp "China-Led Sector x Post x Appropriateness x GDP pc (Pre)" p2013_CL_countavg_loose_gdp_post "China-Led Sector x Post x Appropriateness x GDP pc (Post)" p2013_CL_countavg_loose_below50 "China-Led Sector x Post x Appropriateness x GDP pc (Below China and above 50pct)" p2013_CL_countavg_loose_below75 "China-Led Sector x Post x Appropriateness x GDP pc (Below China and above 75pct)")

log close
