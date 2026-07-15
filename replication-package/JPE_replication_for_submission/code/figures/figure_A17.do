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
log using "$LOG_DIR/figureA17.log", replace text

use "$geolocating_output_folder/analysis_city.dta", clear

gen city_company_count_any_CL = city_company_count_total - city_company_count_non_CL
gen city_dealcount_count_any_CL = city_dealcount - city_dealcount_non_CL
gen city_dealsize_count_any_CL = city_dealsize - city_dealsize_non_CL

foreach var in city_company_count_total city_patents_count_assignees city_patents_count_inventors city_company_count_CL city_company_count_all_CL city_company_count_non_CL city_company_count_not_all_CL city_dealsize city_dealcount city_dealcount_count_any_CL city_dealsize_count_any_CL city_dealcount_non_CL city_dealsize_non_CL city_company_count_any_CL above_99_patents_inventors above_95_patents_inventors above_90_patents_inventors above_75_patents_inventors above_50_patents_inventors above_99_patents_assignees above_95_patents_assignees above_90_patents_assignees above_75_patents_assignees above_50_patents_assignees {
	replace `var' = 0 if `var'==.
	gen ln_`var' = log(`var')
	gen as_`var' = asinh(`var')
}

gen post = (year>=2013)

egen temp = max(pre_2013_share_CL_company_subseg), by(id_populated_city)
replace pre_2013_share_CL_company_subseg = temp if pre_2013_share_CL_company_subseg==.

keep if year>=2000

egen zzzz = sum(city_patents_count_inventors) if year<2013, by(id_populated_city)
egen pre_2013_patents = max(zzzz), by(id_populated_city)
drop zzzz

egen zzzz = sum(city_patents_count_inventors) if year<2013, by(id_country)
egen mean_pre_2013_patents = max(zzzz), by(id_country)
drop zzzz
gen city_patents_count_inventors_n = city_patents_count_inventors/mean_pre_2013_patents

egen zzzz = sum(city_patents_count_assignees) if year<2013, by(id_country)
egen mean_pre_2013_patents_assignees = max(zzzz), by(id_country)
drop zzzz
gen city_patents_count_assignees_n = city_patents_count_assignees/mean_pre_2013_patents_assignees

egen zzzz = sum(city_company_count_total) if year<2013, by(id_country)
egen mean_pre_2013_companies = max(zzzz), by(id_country)
drop zzzz
egen zzzz = sum(city_dealcount) if year<2013, by(id_country)
egen mean_pre_2013_dealcount = max(zzzz), by(id_country)
drop zzzz

foreach var in city_company_count_total city_company_count_CL city_company_count_all_CL city_company_count_non_CL city_company_count_not_all_CL city_company_count_any_CL {
	gen `var'_n = `var'/mean_pre_2013_companies
}
foreach var in city_dealcount city_dealcount_CL city_dealcount_all_CL city_dealcount_non_CL city_dealcount_not_all_CL city_dealcount_count_any_CL {
	gen `var'_n = `var'/mean_pre_2013_dealcount
}

gen share_CL_post = pre_2013_share_CL_company_subseg*post

gen share_CL_post_notoecd = share_CL_post*(1-OECD_b80s)
gen share_CL_post_oecd = share_CL_post*(OECD_b80s)
gen share_CL_notoecd = pre_2013_share_CL_company_subseg*(1-OECD_b80s)
gen share_CL_oecd = pre_2013_share_CL_company_subseg*(OECD_b80s)
gen post_oecd = post*OECD_b80s
gen post_notoecd = post*(1-OECD_b80s)

tab year, gen(yr_)
forvalues i = 1/22 {
	local x = `i'+1999
	rename yr_`i' yr_`x'
}
forvalues i = 2000/2021 {
	gen share_CL_yr_`i' = pre_2013_share_CL_company_subseg*yr_`i'
	gen share_CL_oecd_yr_`i' = pre_2013_share_CL_company_subseg*yr_`i'*OECD_b80s
	gen share_CL_notoecd_yr_`i' = pre_2013_share_CL_company_subseg*yr_`i'*(1-OECD_b80s)
}

gen lpre_2013_company_count = log(pre_2013_company_count)
gen any_patent = (city_patents_count_inventors>0)

local year_interactions = " share_CL_yr_2001 share_CL_yr_2002 share_CL_yr_2003 share_CL_yr_2004 share_CL_yr_2005 share_CL_yr_2006 share_CL_yr_2007 share_CL_yr_2008 share_CL_yr_2009 share_CL_yr_2010 share_CL_yr_2011 share_CL_yr_2012 share_CL_yr_2013 share_CL_yr_2014 share_CL_yr_2015 share_CL_yr_2016 share_CL_yr_2017 share_CL_yr_2018 share_CL_yr_2019 share_CL_yr_2020 share_CL_yr_2021 "

drop if SOV0NAME=="United States" | SOV0NAME=="China"

preserve
reghdfe city_company_count_total_n `year_interactions' post_oecd if pre_2013_company_count>20 & OECD_b80s==0, absorb(year id_populated_city#id_country) vce(cluster id_country)
gen YEAR = .
replace YEAR = _n+1999
gen beta = .
gen se = .
forvalues i = 2001/2021 {
replace beta = _b[share_CL_yr_`i'] if YEAR==`i'
replace se = _se[share_CL_yr_`i'] if YEAR==`i'
}
gen ci_up = beta + 1.96*se
gen ci_down = beta - 1.96*se
drop if beta==.
tw (rcap ci_up ci_down YEAR , lcolor(emerald) ) (scatter beta YEAR, color(emerald) mlwidth(medthick)) , xtitle(Year) xtitle(China Led x Year) ytitle(Companies) legend(off) yline(0, lcolor(gray)) xlabel(2000(5)2020)
graph export "$FIGURE_DIR/figureA17a.pdf", replace
restore

preserve
reghdfe city_company_count_any_CL_n `year_interactions' post_oecd if pre_2013_company_count>20 & OECD_b80s==0, absorb(year id_populated_city#id_country) vce(cluster id_country)
gen YEAR = .
replace YEAR = _n+1999
gen beta = .
gen se = .
forvalues i = 2001/2021 {
replace beta = _b[share_CL_yr_`i'] if YEAR==`i'
replace se = _se[share_CL_yr_`i'] if YEAR==`i'
}
gen ci_up = beta + 1.96*se
gen ci_down = beta - 1.96*se
drop if beta==.
tw (rcap ci_up ci_down YEAR , lcolor(emerald) ) (scatter beta YEAR, color(emerald) mlwidth(medthick)) , xtitle(Year) xtitle(China Led x Year) ytitle(Companies (China-Led)) legend(off) yline(0, lcolor(gray)) xlabel(2000(5)2020)
graph export "$FIGURE_DIR/figureA17b.pdf", replace
restore

preserve
reghdfe city_company_count_non_CL_n `year_interactions' post_oecd if pre_2013_company_count>20 & OECD_b80s==0, absorb(year id_populated_city#id_country) vce(cluster id_country)
gen YEAR = .
replace YEAR = _n+1999
gen beta = .
gen se = .
forvalues i = 2001/2021 {
replace beta = _b[share_CL_yr_`i'] if YEAR==`i'
replace se = _se[share_CL_yr_`i'] if YEAR==`i'
}
gen ci_up = beta + 1.96*se
gen ci_down = beta - 1.96*se
drop if beta==.
tw (rcap ci_up ci_down YEAR , lcolor(emerald) ) (scatter beta YEAR, color(emerald) mlwidth(medthick)) , xtitle(Year) xtitle(China Led x Year) ytitle(Companies (Not China-Led)) legend(off) yline(0, lcolor(gray)) xlabel(2000(5)2020)
graph export "$FIGURE_DIR/figureA17c.pdf", replace
restore

preserve
reghdfe city_patents_count_assignees_n `year_interactions' post_oecd if pre_2013_company_count>20 & OECD_b80s==0 , absorb(year id_populated_city#id_country) vce(cluster id_country)
gen YEAR = .
replace YEAR = _n+1999
gen beta = .
gen se = .
forvalues i = 2001/2021 {
replace beta = _b[share_CL_yr_`i'] if YEAR==`i'
replace se = _se[share_CL_yr_`i'] if YEAR==`i'
}
gen ci_up = beta + 1.96*se
gen ci_down = beta - 1.96*se
drop if beta==.
tw (rcap ci_up ci_down YEAR , lcolor(emerald) ) (scatter beta YEAR, color(emerald) mlwidth(medthick)) , xtitle(Year) xtitle(China Led x Year) ytitle(Patents) legend(off) yline(0, lcolor(gray)) xlabel(2000(5)2020)
graph export "$FIGURE_DIR/figureA17d.pdf", replace
restore

log close
