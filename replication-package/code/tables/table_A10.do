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
log using "$LOG_DIR/tableA10.log", replace text

cd "$intermediate_data_folder"
local out "$TABLE_DIR/tableA10.csv"

local sufs _angel _pe _corp
local tloose `" "Panel A: Angel Deals, Baseline China-led" "Panel C: PE Growth/Expansion Deals, Baseline China-led" "Panel E: Corporate Deals, Baseline China-led" "'
local tstrict `" "Panel B: Angel Deals, Strict  China-led" "Panel D: PE Growth/Expansion Deals, Strict  China-led" "Panel F: Corporate Deals, Strict  China-led" "'

local j = 0
foreach suf of local sufs {
	local ++j
	local tl : word `j' of `tloose'
	local ts : word `j' of `tstrict'

	use regression_alltype_by_cat.dta, clear
	rename p2013_CL_c_avg_loose_s p2013_CL_countavg_loose_suit
	eststo clear
	eststo: reghdfe dc_norm_mean_00_12`suf' p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	eststo: reghdfe dc_norm_mean_00_12`suf' p2013_CL_countavg_loose_suit [aweight = ltotal_pre_deals`suf'], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	eststo: reghdfe as_dealcount`suf' p2013_CL_countavg_loose_suit if dc_norm_mean_00_12`suf'!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	eststo: reghdfe as_dealsize`suf' p2013_CL_countavg_loose_suit if dc_norm_mean_00_12`suf'!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	eststo: reghdfe lsize_pd`suf' p2013_CL_countavg_loose_suit if dc_norm_mean_00_12`suf'!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)

	if `j' == 1 {
		esttab est* using "`out'", se replace csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_loose_suit) ///
			coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness") ///
			prehead(`","Deal Count","Deal Count","Deal Count","Deal Size","Deal Size""' `","(1)","(2)","(3)","(4)","(5)""' `","Baseline","Weighted","asinh","asinh","log($/deal)""' `""`tl'",,,,,"') ///
			posthead("") prefoot("") postfoot(`""`ts'",,,,,"')
	}
	else {
		esttab est* using "`out'", se append csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_loose_suit) ///
			coeflabel(p2013_CL_countavg_loose_suit "China-Led x Post x Appropriateness") ///
			prehead(`""`tl'",,,,,"') posthead("") prefoot("") postfoot(`""`ts'",,,,,"')
	}

	use regression_alltype_by_cat.dta, clear
	rename p2013_CL_c_avg_strict_s p2013_CL_countavg_strict_suit
	eststo clear
	eststo: reghdfe dc_norm_mean_00_12`suf' p2013_CL_countavg_strict_suit, absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe dc_norm_mean_00_12`suf' p2013_CL_countavg_strict_suit [aweight = ltotal_pre_deals`suf'], absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe as_dealcount`suf' p2013_CL_countavg_strict_suit if dc_norm_mean_00_12`suf'!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe as_dealsize`suf' p2013_CL_countavg_strict_suit if dc_norm_mean_00_12`suf'!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace
	eststo: reghdfe lsize_pd`suf' p2013_CL_countavg_strict_suit if dc_norm_mean_00_12`suf'!=., absorb(hq#year hq#subseg subseg#year year#c.suitability_score_wdi) vce(cluster hq)
	quietly estadd ysumm, mean sd replace

	if `j' < 3 {
		esttab est* using "`out'", se append csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_strict_suit) ///
			s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
			coeflabel(p2013_CL_countavg_strict_suit "China-Led (Strict) x Post x Appropriateness") ///
			prehead("") posthead("") prefoot("") postfoot("")
	}
	else {
		esttab est* using "`out'", se append csv ///
			star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons nomtitle nonumbers ///
			order(p2013_CL_countavg_strict_suit) ///
			s(N ymean ysd, label("Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") fmt(0 3 3)) ///
			coeflabel(p2013_CL_countavg_strict_suit "China-Led (Strict) x Post x Appropriateness") ///
			prehead("") posthead("") prefoot("") ///
			postfoot(`""Sector x Country FE","Yes","Yes","Yes","Yes","Yes""' `""Country x Year FE","Yes","Yes","Yes","Yes","Yes""' `""Sector x Year FE","Yes","Yes","Yes","Yes","Yes""' `""Appropriateness x Year FE","Yes","Yes","Yes","Yes","Yes""')
	}
}

log close
