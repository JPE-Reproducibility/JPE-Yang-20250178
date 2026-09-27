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
log using "$LOG_DIR/figureA12.log", replace text

use "$data_folder/analysis_v2.dta", clear
keep if year<=2019
keep if hqcountry == "China"
gen count_deal_china = 1
collapse (sum) count_deal_china, by(fullname year)
sort fullname year
encode fullname, gen(fcode)
xtset fcode year
tsfill, full
drop fullname
decode fcode, gen(fullname)

by fcode: gen growth_2y = count_deal_china / count_deal_china[_n-2] - 1
replace growth_2y = 100 if count_deal_china[_n-2] == 0 & count_deal_china > 0

gen shock_year = 0
gen shock_year_plus_2 = 0
bysort fcode: egen total_deals = total(count_deal_china)

replace growth_2y = 0 if count_deal_china[_n-2]<=5 & count_deal_china<=10
replace growth_2y = 0 if total_deals>300 & count_deal_china[_n-2]<=20 & count_deal_china<=40

bysort fcode: egen max_growth_2y = max(growth_2y)
replace shock_year_plus_2 = 1 if growth_2y == max_growth_2y & total_deals>20 & growth_2y >= 1
bysort fcode: replace shock_year = 1 if shock_year_plus_2[_n+2]==1

replace fullname = ustrregexra(fullname,"\|", "--")
split fullname, p("--")
gen fullname0 = fullname1 + "--" + fullname3

local panel_codes 10 34 97 153 181 232
foreach code of local panel_codes {
    gen temp_year = year if shock_year == 1 & fcode == `code'
    replace temp_year = 2021 if temp_year == .
    sum temp_year, meanonly
    local shock_year_line = r(min)
    drop temp_year
    levelsof fullname0 if fcode == `code', local(graph_title)
    tw (line count_deal_china year if fcode == `code', yaxis(1)) ///
       , xline(`shock_year_line', lcolor(gs8) lpattern(dash)) xlabel(2000(1)2020, angle(45) labsize(small)) ytitle("Number of Deals") title(`graph_title') scale(1)
    graph save "$INTERMEDIATE_DIR/shock_year_`code'.gph", replace
}

graph combine "$INTERMEDIATE_DIR/shock_year_10.gph" "$INTERMEDIATE_DIR/shock_year_34.gph" "$INTERMEDIATE_DIR/shock_year_97.gph" "$INTERMEDIATE_DIR/shock_year_153.gph" "$INTERMEDIATE_DIR/shock_year_181.gph" "$INTERMEDIATE_DIR/shock_year_232.gph", ///
    rows(3) cols(2) ysize(12) xsize(12) iscale(0.4) commonscheme

graph export "$FIGURE_DIR/figureA12.pdf", replace

foreach code of local panel_codes {
    capture erase "$INTERMEDIATE_DIR/shock_year_`code'.gph"
}

log close
