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
log using "$LOG_DIR/figure2.log", replace text

global regression_file "regression_corrected_120623.dta"

use "$data_folder/$regression_file", clear
keep if OECD_b80s==0
collapse (sum) dealcount_y dealsize_y, by(china_led_countavg_loose year)

gen post2013 = (year >= 2013)

collapse (mean) dealcount_y dealsize_y, by(china_led_countavg_loose post2013)

label define china_led_lbl 0 "Non-China-led" 1 "China-led"
label values china_led_countavg_loose china_led_lbl

label define post2013_lbl 0 "Pre-2013" 1 "Post-2013"
label values post2013 post2013_lbl

graph bar dealsize_y, ///
     over(china_led_countavg_loose) over(post2013) ///
    asyvars bar(1, color(emerald%30)) bar(2, color(emerald%80)) ///
    ytitle("Total Investment Value (yearly mean, in millions USD)") legend(pos(6) rows(1) size(medsmall))

graph export "$FIGURE_DIR/figure2a.pdf", replace

use "$data_folder/$regression_file", clear
keep if OECD_b80s==1
collapse (sum) dealcount_y dealsize_y, by(china_led_countavg_loose year)

gen post2013 = (year >= 2013)

collapse (mean) dealcount_y dealsize_y, by(china_led_countavg_loose post2013)

label define china_led_lbl 0 "Non-China-led" 1 "China-led"
label values china_led_countavg_loose china_led_lbl

label define post2013_lbl 0 "Pre-2013" 1 "Post-2013"
label values post2013 post2013_lbl

graph bar dealsize_y, ///
     over(china_led_countavg_loose) over(post2013) ///
    asyvars bar(1, color(emerald%30)) bar(2, color(emerald%80)) ///
    ytitle("Total Investment Value (yearly mean, in millions USD)") legend(pos(6) rows(1) size(medsmall))

graph export "$FIGURE_DIR/figure2b.pdf", replace

log close
