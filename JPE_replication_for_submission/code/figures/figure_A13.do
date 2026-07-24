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
log using "$LOG_DIR/figureA13.log", replace text

use "$intermediate_data_folder/shock_year.dta", clear
merge 1:1 fullname using "$intermediate_data_folder/china_led_subsegments_avg_loose_dealcount_v2.dta"
keep if _merge == 3
drop if no_shock_year_identified==1

hist shock_year, color(emerald%70) frac xlabel(2007(1)2018, labsize(medium)) ytitle("Fraction of Sectors") xtitle("Surge Year") discrete

graph export "$FIGURE_DIR/figureA13.pdf", replace

log close
