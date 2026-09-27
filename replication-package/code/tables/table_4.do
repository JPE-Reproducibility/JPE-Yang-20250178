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
log using "$LOG_DIR/table4.log", replace text

capture program drop _fmtcell
program define _fmtcell, rclass
    args b se p
    local stars ""
    if `p' < 0.01      local stars "***"
    else if `p' < 0.05 local stars "**"
    else if `p' < 0.10 local stars "*"
    local bf  : display %10.3f `b'
    local sef : display %10.3f `se'
    local bf  = trim("`bf'")
    local sef = trim("`sef'")
    return local b "`bf'`stars'"
    return local se "(`sef')"
end

use "$data_folder/regression_corrected_120623.dta", clear
keep subsegment subsegment1 china_led_countavg_loose policy_obstacle
bysort subsegment: keep if _n==1

reg china_led_countavg_loose policy_obstacle, robust
test policy_obstacle
_fmtcell `=_b[policy_obstacle]' `=_se[policy_obstacle]' `=r(p)'
local b1 "`r(b)'"
local se1 "`r(se)'"
local N1 = e(N)
quietly summarize china_led_countavg_loose
local m1 : display %10.3f r(mean)
local sd1 : display %10.3f r(sd)

reghdfe china_led_countavg_loose policy_obstacle, absorb(subsegment1) vce(robust)
test policy_obstacle
_fmtcell `=_b[policy_obstacle]' `=_se[policy_obstacle]' `=r(p)'
local b2 "`r(b)'"
local se2 "`r(se)'"
local N2 = e(N)
quietly summarize china_led_countavg_loose
local m2 : display %10.3f r(mean)
local sd2 : display %10.3f r(sd)

use "$data_folder/regression_corrected_120623.dta", clear
gen p2013_not_constrained_suit = post2013*(1-policy_obstacle)*suitability_score_wdi
gen p2013_constrained_suit     = post2013*policy_obstacle*suitability_score_wdi

reghdfe dealcount_norm_mean_00_12 p2013_constrained_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
test p2013_constrained_suit
_fmtcell `=_b[p2013_constrained_suit]' `=_se[p2013_constrained_suit]' `=r(p)'
local b3 "`r(b)'"
local se3 "`r(se)'"
local N3 = e(N)
quietly summarize dealcount_norm_mean_00_12 if e(sample)
local m3 : display %10.3f r(mean)
local sd3 : display %10.3f r(sd)

reghdfe dealcount_norm_mean_00_12 p2013_constrained_suit, absorb(hq#year hq#subseg subseg#year hq#year#marketmap_code) vce(cluster hq)
test p2013_constrained_suit
_fmtcell `=_b[p2013_constrained_suit]' `=_se[p2013_constrained_suit]' `=r(p)'
local b4 "`r(b)'"
local se4 "`r(se)'"
local N4 = e(N)
quietly summarize dealcount_norm_mean_00_12 if e(sample)
local m4 : display %10.3f r(mean)
local sd4 : display %10.3f r(sd)

ivreghdfe dealcount_norm_mean_00_12 (p2013_CL_countavg_loose_suit = p2013_not_constrained_suit), absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
test p2013_CL_countavg_loose_suit
_fmtcell `=_b[p2013_CL_countavg_loose_suit]' `=_se[p2013_CL_countavg_loose_suit]' `=r(p)'
local b5 "`r(b)'"
local se5 "`r(se)'"
local N5 = e(N)
quietly summarize dealcount_norm_mean_00_12 if e(sample)
local m5 : display %10.3f r(mean)
local sd5 : display %10.3f r(sd)

ivreghdfe dealcount_norm_mean_00_12 (p2013_CL_countavg_loose_suit = p2013_not_constrained_suit), absorb(hq#year hq#subseg subseg#year hq#year#marketmap_code) vce(cluster hq)
test p2013_CL_countavg_loose_suit
_fmtcell `=_b[p2013_CL_countavg_loose_suit]' `=_se[p2013_CL_countavg_loose_suit]' `=r(p)'
local b6 "`r(b)'"
local se6 "`r(se)'"
local N6 = e(N)
quietly summarize dealcount_norm_mean_00_12 if e(sample)
local m6 : display %10.3f r(mean)
local sd6 : display %10.3f r(sd)

foreach k in 1 2 3 4 5 6 {
    local m`k' = trim("`m`k''")
    local sd`k' = trim("`sd`k''")
}

tempname fh
file open `fh' using "$TABLE_DIR/table4.csv", write replace text

file write `fh' `","China-Led? (0/1)","China-Led? (0/1)","Number of Deals (Normalized)","Number of Deals (Normalized)","Number of Deals (Normalized)","Number of Deals (Normalized)""' _n
file write `fh' `","(1)","(2)","(3)","(4)","(5)","(6)""' _n

file write `fh' `""Policy-Constrained","`b1'","`b2'",,,,"' _n
file write `fh' `""","`se1'","`se2'",,,,"' _n
file write `fh' `""Policy-Constrained x Post x Appropriateness",,,"`b3'","`b4'",,"' _n
file write `fh' `""",,,"`se3'","`se4'",,"' _n
file write `fh' `""China-Led-hat x Post x Appropriateness","","","","","`b5'","`b6'""' _n
file write `fh' `""","","","","","`se5'","`se6'""' _n

file write `fh' `""Macro-Sector FE","No","Yes","-","-","-","-""' _n
file write `fh' `""Sector x Country FE","-","-","Yes","Yes","Yes","Yes""' _n
file write `fh' `""Country x Year FE","-","-","Yes","Yes","Yes","Yes""' _n
file write `fh' `""Sector x Year FE","-","-","Yes","Yes","Yes","Yes""' _n
file write `fh' `""Macro-Sector x Year x Country FE","-","-","No","Yes","No","Yes""' _n
file write `fh' `""Model","1st Stage","1st Stage","RF","RF","IV","IV""' _n
file write `fh' `""Number of Obs","`N1'","`N2'","`N3'","`N4'","`N5'","`N6'""' _n
file write `fh' `""Mean of Dep. Var","`m1'","`m2'","`m3'","`m4'","`m5'","`m6'""' _n
file write `fh' `""SD of Dep. Var","`sd1'","`sd2'","`sd3'","`sd4'","`sd5'","`sd6'""' _n
file close `fh'

log close
