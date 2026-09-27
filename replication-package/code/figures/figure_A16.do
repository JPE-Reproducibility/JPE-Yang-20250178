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

global saving_suffix "corrected_120623.dta"
global regression_file "regression_$saving_suffix"

capture set scheme eop
if _rc != 0 {
	set scheme s2color
}
capture log close
log using "$LOG_DIR/figureA16.log", replace text

import excel using "$tradable_sector/table6_A16_Tradable or not 2nd.xlsx", firstrow clear
keep subsegment tradable
merge 1:m subsegment using "$data_folder/$regression_file"
duplicates drop subsegment year, force
keep year subsegment tradable dealcount_china dealcount_us dealsize_china dealsize_us

collapse (sum) dealcount_china dealcount_us dealsize_china dealsize_us, by(year tradable)
reshape wide dealcount_china dealcount_us dealsize_china dealsize_us, i(year) j(tradable) string

gen dealcount_chinaNO = dealcount_chinaN + dealcount_chinaO
gen dealsize_chinaNO = dealsize_chinaN + dealsize_chinaO

twoway 	 (line dealcount_chinaY year, lpattern(dash)) ///
	  (line dealcount_chinaNO year, lcolor(emerald)), ///
	  legend(order(1 "Tradable Sectors" 2 "Non-tradable and Other Sectors") ///
	  pos(11) ring(0) cols(1)) ///
	  xtitle("Year") ytitle("Deal Count in China")
graph export "$FIGURE_DIR/figureA16a.pdf", replace

twoway 	 (line dealsize_chinaY year, lpattern(dash)) ///
	  (line dealsize_chinaNO year, lcolor(emerald)), ///
	  legend(order(1 "Tradable Sectors" 2 "Non-tradable and Other Sectors") ///
	  pos(11) ring(0) cols(1)) ///
	  xtitle("Year") ytitle("Deal Size in China")
graph export "$FIGURE_DIR/figureA16b.pdf", replace

import excel using "$tradable_sector/table6_A16_Tradable or not 2nd.xlsx", firstrow clear
keep subsegment tradable
merge 1:m subsegment using "$data_folder/$regression_file"
keep year subsegment tradable dealcount_y dealsize_y

collapse (sum) dealcount_y dealsize_y, by(year tradable)
reshape wide dealcount_y dealsize_y, i(year) j(tradable) string
gen dealcount_yNO = dealcount_yN + dealcount_yO
gen dealsize_yNO = dealsize_yN + dealsize_yO

twoway 	 (line dealcount_yY year, lpattern(dash)) ///
	  (line dealcount_yNO year, lcolor(emerald)), ///
	  legend(order(1 "Tradable Sectors" 2 "Non-tradable and Other Sectors") ///
	  pos(11) ring(0) cols(1)) ///
	  xtitle("Year") ytitle("Deal Count Worldwide (excl. CN and US)")
graph export "$FIGURE_DIR/figureA16c.pdf", replace

twoway 	 (line dealsize_yY year, lpattern(dash)) ///
	  (line dealsize_yNO year, lcolor(emerald)), ///
	  legend(order(1 "Tradable Sectors" 2 "Non-tradable and Other Sectors") ///
	  pos(11) ring(0) cols(1)) ///
	  xtitle("Year") ytitle("Deal Size Worldwide (excl. CN and US)")
graph export "$FIGURE_DIR/figureA16d.pdf", replace

log close
