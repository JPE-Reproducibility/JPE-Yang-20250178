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
log using "$LOG_DIR/figureA15.log", replace text

use "$intermediate_data_folder/US_China_pre_post_binscatter_regression.dta", clear

capture drop CL_suitUS_post UL_suitUS_post
gen CL_suitUS_post = CL_suitUS*post
gen UL_suitUS_post = UL_suitUS*post

egen hq_post = group(hq post)
egen subseg_post = group(subseg post)
egen hq_subseg = group(hq subseg)

reghdfe dealcount_norm_mean_00_12 UL_suitUS_post, absorb(hq#post subseg#post subseg#hq) cluster(hq)
local coef1 = string(_b[UL_suitUS_post], "%9.3f")
local se1 = string(_se[UL_suitUS_post], "%9.3f")

binscatter2 dealcount_norm_mean_00_12 UL_suitUS_post, absorb(hq_post subseg_post hq_subseg) nq(50) xtitle("Post x US-led Sectors x Sector-Specific US Appropriateness") ytitle("Number of Deals (normalized)") text(3.75 0.53 "Coefficient: `coef1'" "SE: `se1'", box j(left) size(medium) margin(small) fcolor(white)) yscale(r(1.5(0.5)4)) ylabel(1.5(0.5)4)
graph export "$FIGURE_DIR/figureA15a.pdf", replace

reghdfe dealcount_norm_mean_00_12 CL_suitUS_post, absorb(hq#post subseg#post subseg#hq) cluster(hq)
local coef2 = string(_b[CL_suitUS_post], "%9.3f")
local se2 = string(_se[CL_suitUS_post], "%9.3f")

binscatter2 dealcount_norm_mean_00_12 CL_suitUS_post, absorb(hq_post subseg_post hq_subseg) nq(50) xtitle("Post x China-led Sectors x Sector-Specific US Appropriateness") ytitle("Number of Deals (normalized)") text(3.85 0.46 "Coefficient: `coef2'" "SE: `se2'", box j(left) size(medium) margin(small) fcolor(white)) yscale(r(1.5(0.5)4)) ylabel(1.5(0.5)4)
graph export "$FIGURE_DIR/figureA15b.pdf", replace

log close
