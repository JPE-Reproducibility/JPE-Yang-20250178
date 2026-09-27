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
log using "$LOG_DIR/figureA2.log", replace text

use dealid hqcountry year OECD_b80s using "$data_folder/analysis_v2.dta", clear

keep if year >= 2000 & year <= 2021
duplicates drop dealid, force

gen status = .
replace status = 1 if hqcountry == "China"
replace status = 2 if hqcountry == "United States"
replace status = 3 if OECD_b80s == 0 & hqcountry != "China" & hqcountry != "United States"
replace status = 4 if OECD_b80s == 1 & hqcountry != "China" & hqcountry != "United States"

gen count = 1
collapse (count) count, by(status year)
reshape wide count, i(year) j(status)
rename count1 China
rename count2 US
rename count3 DevelopingExChina
rename count4 DevelopedExUS

order year US DevelopedExUS China DevelopingExChina
sort year
export delimited using "$INTERMEDIATE_DIR/figureA2_dealcount_year.csv", replace

twoway ///
    (line US year,                lcolor("47 110 186")  lwidth(medthick)) ///
    (line DevelopedExUS year,     lcolor("218 120 66")  lwidth(medthick)) ///
    (line China year,             lcolor("234 51 35")   lwidth(medthick)) ///
    (line DevelopingExChina year, lcolor("245 194 66")  lwidth(medthick)) ///
    , ///
    ytitle("# of Deals", size(small)) ///
    ylabel(0(2000)12000, angle(0) labsize(small) ///
           grid glcolor(gs13) glwidth(vthin)) ///
    yscale(noline range(0 12000)) ///
    xtitle("") ///
    xlabel(2000(1)2021, angle(45) labsize(vsmall)) ///
    legend(order(1 "US" 2 "Developed ex US" 3 "China" 4 "Developing ex China") ///
           rows(1) size(small) position(6) region(lcolor(none))) ///
    graphregion(color(white)) ///
    plotregion(color(white) lcolor(none) margin(zero)) ///
    xsize(8) ysize(4.8)

graph export "$FIGURE_DIR/figureA2.pdf", replace

log close
