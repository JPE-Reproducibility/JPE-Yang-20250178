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
log using "$LOG_DIR/figureA6.log", replace text

use "$data_folder/analysis_v2.dta", clear
keep if hqcountry == "United States" | hqcountry == "China"
gen count = 1
gen size = dealsize
collapse (sum) count size, by(hqcountry year china_led_dealcountavg_loose)
gen countryChinaled= hqcountry + string(china_led_dealcountavg_loose)
encode countryChinaled, gen(countryChinalednum)
drop hqcountry china_led_dealcountavg_loose countryChinaled
reshape wide count size, i(year) j(countryChinalednum)
rename count1 deal_china_CL0
rename count2 deal_china_CL1
rename count3 deal_us_CL0
rename count4 deal_us_CL1
rename size1 size_china_CL0
rename size2 size_china_CL1
rename size3 size_us_CL0
rename size4 size_us_CL1

gen deal_CL1 = deal_china_CL1 + deal_us_CL1
gen deal_CL0 = deal_china_CL0 + deal_us_CL0
gen size_CL1 = size_china_CL1 + size_us_CL1
gen size_CL0 = size_china_CL0 + size_us_CL0

foreach var in deal_CL1 deal_CL0 {
	gen temp = `var' if year==2005
	egen max_temp = max(temp)
	gen rel_`var' = `var'/max_temp
	drop temp max_temp
}

gen log_deal_CL0 = log(deal_CL0)
gen log_deal_CL1 = log(deal_CL1)

line log_deal_CL0 log_deal_CL1 year if year<2020 & year>2000, legend(label(1 "US-Led Sectors")label(2 "China-Led Sectors")) xtitle(Year) ytitle(log Deals: US and China)
graph export "$FIGURE_DIR/figureA6a.pdf", replace

line rel_deal_CL0 rel_deal_CL1 year if year<2020 & year>2000, legend(label(1 "US-Led Sectors")label(2 "China-Led Sectors")) xtitle(Year) ytitle(Deal Count Relative to 2005: US and China)
graph export "$FIGURE_DIR/figureA6b.pdf", replace

log close
