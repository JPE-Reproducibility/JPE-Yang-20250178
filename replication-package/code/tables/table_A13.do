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
log using "$LOG_DIR/tableA13.log", replace text

cd "$intermediate_data_folder"

local files  regression_from_existing_no_trade2 regression_from_scratch_allassigned regression_corrected_drop20country regression_corrected_drop30country regression_corrected_drop15indicator regression_corrected_drop25indicator

local out "$TABLE_DIR/tableA13.csv"

local k = 0
foreach f of local files {
	local ++k
	if `k' == 1 local title "Panel A: Partial-Freedom Indicator Assignment"
	if `k' == 2 local title "Panel B: No-Freedom Indicator Assignment"
	if `k' == 3 local title "Panel C: Dropping Countries with >20pct Missing"
	if `k' == 4 local title "Panel D: Dropping Countries with >30pct Missing"
	if `k' == 5 local title "Panel E: Dropping Indicators with >15pct Missing"
	if `k' == 6 local title "Panel F: Dropping Indicators with >25pct Missing"

	use `f', clear
	eststo clear
	eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit [aweight = ltotal_pre_deals], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe as_dealcount_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe as_dealsize_y p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe lsize_per_deal p2013_CL_countavg_loose_suit if dealcount_norm_mean_00_12!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace

	if `k' == 1 {
		esttab est* using "`out'", se replace csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_loose_suit) ///
			s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
			coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness") ///
			prehead(`","Deal Count","Deal Count","Deal Count","Deal Size","Deal Size""' `","(1)","(2)","(3)","(4)","(5)""' `","Baseline","Weighted","asinh","asinh","log($/deal)""' `""`title'",,,,,"') ///
			posthead("") prefoot("") postfoot("")
	}
	else if `k' < 6 {
		esttab est* using "`out'", se append csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_loose_suit) ///
			s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
			coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness") ///
			prehead(`""`title'",,,,,"') posthead("") prefoot("") postfoot("")
	}
	else {
		esttab est* using "`out'", se append csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_loose_suit) ///
			s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
			coeflabel(p2013_CL_countavg_loose_suit "China-Led Sector x Post x Appropriateness") ///
			prehead(`""`title'",,,,,"') posthead("") prefoot("") ///
			postfoot(`""Sector x Country FE","Yes","Yes","Yes","Yes","Yes""' `""Country x Year FE","Yes","Yes","Yes","Yes","Yes""' `""Sector x Year FE","Yes","Yes","Yes","Yes","Yes""' `""Appropriateness x Year FE","Yes","Yes","Yes","Yes","Yes""')
	}
}

log close
