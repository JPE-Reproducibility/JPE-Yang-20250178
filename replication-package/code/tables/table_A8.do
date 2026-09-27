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

capture log close
log using "$LOG_DIR/tableA8.log", replace text

use "$simulation_folder/simulated_deals_all_1_500.dta", clear
keep if OECD==0
collapse (sum) mean_simulated_deals mean_simulated_deals_GDP mean_simulated_deals_noFE mean_simulated_deals_GDP_noFE yhat_CL yhat_CL_noFE, by(simulated_country)

gen FE_sim = mean_simulated_deals - mean_simulated_deals_noFE
gen simulated_share = (mean_simulated_deals - FE_sim)/FE_sim
gen FE_sim_GDP = mean_simulated_deals_GDP - mean_simulated_deals_GDP_noFE
gen simulated_share_GDP = (mean_simulated_deals_GDP - FE_sim_GDP)/FE_sim_GDP

local cn_deals  = yhat_CL[1]
local cn_effect = yhat_CL_noFE[1]
local cn_share  = `cn_effect'/(`cn_deals' - `cn_effect')*100

tempfile sim
save `sim'

local out "$TABLE_DIR/tableA8.csv"
file open fh using "`out'", write replace
file write fh `""Panel A: Simulated Deals",,,"' _n
file write fh `""Simulated Country","Mean Simulated Deals","Mean Simulated Country-led Effect","Percentage Increase Compared with No Effect""' _n

use `sim', clear
gsort -simulated_share
forvalues i = 1/10 {
	local c  = simulated_country[`i']
	local d  : display %9.2f mean_simulated_deals[`i']
	local e  : display %9.2f mean_simulated_deals_noFE[`i']
	local s  : display %9.2f simulated_share[`i']*100
	file write fh `""`c'","`=trim("`d'")'","`=trim("`e'")'","`=trim("`s'")'""' _n
}
file write fh `""China (Actual Estimate)","`=trim(string(`cn_deals',"%9.2f"))'","`=trim(string(`cn_effect',"%9.2f"))'","`=trim(string(`cn_share',"%9.2f"))'""' _n
file write fh "" _n
file write fh `""Panel B: GDP Adjusted Simulated Deals",,,"' _n
file write fh `""Simulated Country","Mean Simulated Deals","Mean Simulated Country-led Effect","Percentage Increase Compared with No Effect""' _n
file write fh `""China (Actual Estimate)","`=trim(string(`cn_deals',"%9.2f"))'","`=trim(string(`cn_effect',"%9.2f"))'","`=trim(string(`cn_share',"%9.2f"))'""' _n

gsort -simulated_share_GDP
forvalues i = 1/10 {
	local c  = simulated_country[`i']
	local d  : display %9.2f mean_simulated_deals_GDP[`i']
	local e  : display %9.2f mean_simulated_deals_GDP_noFE[`i']
	local s  : display %9.2f simulated_share_GDP[`i']*100
	file write fh `""`c'","`=trim("`d'")'","`=trim("`e'")'","`=trim("`s'")'""' _n
}
file close fh

log close
