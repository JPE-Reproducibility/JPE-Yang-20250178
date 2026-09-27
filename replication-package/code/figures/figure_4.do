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

set scheme eop
capture log close
log using "$LOG_DIR/figure4.log", replace text

global regression_file "regression_corrected_120623.dta"
use "$data_folder/$regression_file", clear

capture drop time
gen time = (year>=2013)
collapse (sum) dealcount_y dealsize_y (firstnm) s_quartile_sample_* s_quint_sample_* s_decile_sample_* q*_suit china_led_countavg_strict china_led_countavg_loose EM* OECD* suitability_score_wdi suitability_score_wdi_us, by(subseg time hq)

gen post = (time==1)

foreach var in dealcount_y dealsize_y {
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

forvalues i = 1/10 {
	gen CL_suit_decile_`i' = china_led_countavg_loose*s_decile_sample_`i'
}

reghdfe dealcount_norm_mean_00_12  CL_suit_decile_2 CL_suit_decile_3 CL_suit_decile_4 CL_suit_decile_5 CL_suit_decile_6 CL_suit_decile_7 CL_suit_decile_8 CL_suit_decile_9 CL_suit_decile_10 if time==0, absorb(subseg hq) cluster(hq)

gen Decile = _n if _n<11
gen beta = .
gen se = .
forvalues i = 2/10 {
replace beta = _b[CL_suit_decile_`i'] if Decile==`i'
replace se = _se[CL_suit_decile_`i'] if Decile==`i'
}
gen ci_up = beta + 1.96*se
gen ci_down = beta - 1.96*se

replace Decile = . if _n==1
tw (rcap ci_up ci_down Decile,  lcolor(emerald)  ) (bar beta Decile, color(emerald%50)  mlwidth(medthick)) ,xtitle(Quintile) xtitle(Appropriateness Decile) ytitle(Total Number of Deals (pre-2013)) legend(off) xlabel(2(1)10) xscale(r(2(1)5)) ylabel(-2(2)8) yscale(r(0(2)8))
graph export "$FIGURE_DIR/figure4a.pdf", replace

drop Decile beta se ci_up ci_down

reghdfe dealcount_norm_mean_00_12  CL_suit_decile_2 CL_suit_decile_3 CL_suit_decile_4 CL_suit_decile_5 CL_suit_decile_6 CL_suit_decile_7 CL_suit_decile_8 CL_suit_decile_9 CL_suit_decile_10 if time==1, absorb(subseg hq) cluster(hq)

gen Decile = _n if _n<11
gen beta = .
gen se = .
forvalues i = 2/10 {
replace beta = _b[CL_suit_decile_`i'] if Decile==`i'
replace se = _se[CL_suit_decile_`i'] if Decile==`i'
}
gen ci_up = beta + 1.96*se
gen ci_down = beta - 1.96*se

replace Decile = . if _n==1
tw (rcap ci_up ci_down Decile,  lcolor(emerald)  ) (bar beta Decile, color(emerald%50)  mlwidth(medthick)) ,xtitle(Quintile) xtitle(Appropriateness Decile) ytitle(Total Number of Deals (post-2013)) legend(off) xlabel(2(1)10) ylabel(-2(2)8)
graph export "$FIGURE_DIR/figure4b.pdf", replace
drop Decile beta se ci_up ci_down

log close
