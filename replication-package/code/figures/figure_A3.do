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
log using "$LOG_DIR/figureA3.log", replace text

use "$invariant_data_folder/pbdeals.dta", clear
keep companyid companyname dealno dealid dealdate dealsize dealtype
keep if dealtype == "Early Stage VC" | dealtype == "Later Stage VC"
keep if companyid == "162908-20" | companyid == "294474-07" | companyid == "433899-46" | companyid == "158661-28" | companyid == "226107-64" | companyid == "489562-84"
replace dealsize = 0 if dealsize == .
gen date = date(dealdate,"MDY")
format date %td
drop if date == .
sort date

tw  (scatter dealsize date if companyid == "162908-20", mcolor(red) msymbol(square) sort(date) lpattern(dash) lcolor(red)) ///
(scatter dealsize date if companyid == "158661-28", mcolor(midblue) lpattern(dash) lcolor(midblue) sort(date)) ///
(scatter dealsize date if companyid == "294474-07", mcolor(purple) msymbol(triangle) lpattern(dash) sort(date) lcolor(purple)) ///
(scatter dealsize date if companyid == "433899-46", mcolor(blue) msymbol(D) sort(date) lpattern(dash) lcolor(blue)) ///
(scatter dealsize date if companyid == "226107-64", mcolor(edkblue) msymbol(Oh) sort(date) lpattern(dash) lcolor(green)) ///
(scatter dealsize date if companyid == "489562-84", mcolor(pink) msymbol(Dh) sort(date) lpattern(dash) lcolor(orange)), ///
legend(label(1 "PDD (China)") label(3 "Facily (Brazil)") label(4 "Favo (Brazil)") label(2 "Meesho (India)") label(5 "Super (Indonesia)") label(6 "Tushop (Kenya)") cols(3) size(small) position(6)) graphregion(color(white) margin(medium)) plotregion(color(white)) xlabel(#8, labsize(small) format(%tdCY)) ylabel(, labsize(small)) ytitle("Deal Size (in million USD)", size(small) margin(small)) xtitle("Year", size(small) margin(small))

graph export "$FIGURE_DIR/figureA3.pdf", replace

log close
