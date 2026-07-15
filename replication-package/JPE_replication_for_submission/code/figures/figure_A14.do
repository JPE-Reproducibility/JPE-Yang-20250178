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
log using "$LOG_DIR/figureA14.log", replace text

use "$intermediate_data_folder/US_China_pre_post_binscatter_regression.dta", clear

reghdfe dealcount_norm_mean_00_12 UL_suitUS CL_suitUS if time==0, absorb(hq subseg) cluster(hq)
local coef1 = string(_b[UL_suitUS], "%9.3f")
local se1 = string(_se[UL_suitUS], "%9.3f")
local coef2 = string(_b[CL_suitUS], "%9.3f")
local se2 = string(_se[CL_suitUS], "%9.3f")

binscatter2 dealcount_norm_mean_00_12 UL_suitUS if time==0, absorb(hq subseg) controls(CL_suitUS) nq(50) yscale(r(0.3(0.3)1.8)) ylabel(0.3(0.3)1.8) xtitle("US-led Sectors x US Appropriateness") ytitle("Number of Deals (normalized)") text(1.78 0.83 "Coefficient: `coef1'" "SE: `se1'", box j(left) size(medium) margin(small) fcolor(white))
graph export "$FIGURE_DIR/figureA14a.pdf", replace

binscatter2 dealcount_norm_mean_00_12 CL_suitUS if time==0, absorb(hq subseg) controls(UL_suitUS) nq(50) yscale(r(0.3(0.3)1.8)) ylabel(0.3(0.3)1.8) xtitle("China-led Sectors x US Appropriateness") ytitle("Number of Deals (normalized)") text(1.78 0.73 "Coefficient: `coef2'" "SE: `se2'", box j(left) size(medium) margin(small) fcolor(white))
graph export "$FIGURE_DIR/figureA14b.pdf", replace

use "$intermediate_data_folder/US_China_pre_post_binscatter_regression.dta", clear
reghdfe dealcount_norm_mean_00_12 CL_suitChina UL_suitChina if time==0, absorb(hq subseg) cluster(hq)
local coef1 = string(_b[CL_suitChina], "%9.3f")
local se1 = string(_se[CL_suitChina], "%9.3f")
local coef2 = string(_b[UL_suitChina], "%9.3f")
local se2 = string(_se[UL_suitChina], "%9.3f")

binscatter2 dealcount_norm_mean_00_12 CL_suitChina if time==0, absorb(hq subseg) controls(UL_suitChina) nq(50) yscale(r(0.3(0.3)2.4)) ylabel(0.3(0.3)2.4) xtitle("China-led Sectors x China Appropriateness") ytitle("Number of Deals (normalized)") text(2.32 0.58 "Coefficient: `coef1'" "SE: `se1'", box j(left) size(medium) margin(small) fcolor(white))
graph export "$FIGURE_DIR/figureA14c.pdf", replace

binscatter2 dealcount_norm_mean_00_12 UL_suitChina if time==0, absorb(hq subseg) controls(CL_suitChina) nq(50) yscale(r(0.3(0.3)2.4)) ylabel(0.3(0.3)2.4) xtitle("US-led Sectors x China Appropriateness") ytitle("Number of Deals (normalized)") text(2.32 0.64 "Coefficient: `coef2'" "SE: `se2'", box j(left) size(medium) margin(small) fcolor(white))
graph export "$FIGURE_DIR/figureA14d.pdf", replace

log close
