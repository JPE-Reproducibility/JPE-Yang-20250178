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
log using "$LOG_DIR/figureA11.log", replace text

use "$suit_output_folder/regression_china_suitability_score_1_indicator_dropped_corrected.dta", clear
reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if year<=2019, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta = _b[p2013_CL_countavg_loose_suit]
hist beta, color(emerald%70) xline(`trueBeta', lcolor(red)) xtitle("Placebo Coefficients with 1 Appropriateness Indicator Dropped Each") bin(30) xlabel(0(2)10)
graph export "$FIGURE_DIR/figureA11a.pdf", replace

use "$suit_output_folder/regression_china_suitability_score_2_indicator_dropped_corrected.dta", clear
reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if year<=2019, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta = _b[p2013_CL_countavg_loose_suit]
hist beta, color(emerald%70) xline(`trueBeta', lcolor(red)) xtitle("Placebo Coefficients with 2 Appropriateness Indicators Dropped Each") bin(30) xlabel(0(2)10)
graph export "$FIGURE_DIR/figureA11b.pdf", replace

use "$suit_output_folder/regression_china_suitability_score_3_indicator_dropped_corrected.dta", clear
reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if year<=2019, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta = _b[p2013_CL_countavg_loose_suit]
hist beta, color(emerald%70) xline(`trueBeta', lcolor(red)) xtitle("Placebo Coefficients with 3 Appropriateness Indicators Dropped Each") bin(30) xlabel(0(2)10)
graph export "$FIGURE_DIR/figureA11c.pdf", replace

use "$suit_output_folder/regression_china_suitability_score_4_indicator_dropped_corrected.dta", clear
reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit if year<=2019, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta = _b[p2013_CL_countavg_loose_suit]
hist beta, color(emerald%70) xline(`trueBeta', lcolor(red)) xtitle("Placebo Coefficients with 4 Appropriateness Indicators Dropped Each") bin(30) xlabel(0(2)10)
graph export "$FIGURE_DIR/figureA11d.pdf", replace

log close
