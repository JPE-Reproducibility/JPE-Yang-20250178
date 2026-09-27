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
log using "$LOG_DIR/tableA29.log", replace text

set maxvar 30000

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
drop temp

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
foreach var in city_dealcount city_dealcount_CL city_dealcount_all_CL city_dealcount_non_CL city_dealcount_not_all_CL city_dealcount_count_any_CL  {
	gen `var'_n = `var'/mean_pre_2013_dealcount
}

gen share_CL_post = pre_2013_share_CL_company_subseg*post

gen share_CL_post_notoecd = share_CL_post*(1-OECD_b80s)
gen share_CL_post_oecd = share_CL_post*(OECD_b80s)
gen share_CL_notoecd = pre_2013_share_CL_company_subseg*(1-OECD_b80s)
gen share_CL_oecd = pre_2013_share_CL_company_subseg*(OECD_b80s)
gen post_oecd = post*OECD_b80s
gen post_notoecd = post*(1-OECD_b80s)

gen lpre_2013_company_count = log(pre_2013_company_count)
gen any_patent = (city_patents_count_inventors>0)

drop if SOV0NAME=="United States" | SOV0NAME=="China"
drop if ISO_2digits=="US" | ISO_2digits=="CN"

eststo clear

eststo: reghdfe city_company_count_total_n share_CL_post if pre_2013_company_count>20 & OECD_b80s==0 & year<2022 , absorb(id_populated_city#id_country year) cluster(id_populated_city year#id_country)
quietly estadd local fe_city "Yes"
quietly estadd local fe_year "Yes"
quietly estadd local fe_yearEM "-"
quietly estadd ysumm, mean sd replace

eststo: reghdfe city_company_count_any_CL_n share_CL_post if pre_2013_company_count>20 & OECD_b80s==0 & year<2022 , absorb(id_populated_city#id_country year) cluster(id_populated_city year#id_country)
quietly estadd local fe_city "Yes"
quietly estadd local fe_year "Yes"
quietly estadd local fe_yearEM "-"
quietly estadd ysumm, mean sd replace

eststo: reghdfe city_company_count_non_CL_n share_CL_post if pre_2013_company_count>20 & OECD_b80s==0 & year<2022 , absorb(id_populated_city#id_country year) cluster(id_populated_city year#id_country)
quietly estadd local fe_city "Yes"
quietly estadd local fe_year "Yes"
quietly estadd local fe_yearEM "-"
quietly estadd ysumm, mean sd replace

eststo: reghdfe city_company_count_total_n share_CL_post share_CL_post_notoecd if pre_2013_company_count>20 & year<2022 , absorb(id_populated_city#id_country year#OECD_b80s) cluster(id_populated_city year#id_country)
quietly estadd local fe_city "Yes"
quietly estadd local fe_year "Yes"
quietly estadd local fe_yearEM "Yes"
quietly estadd ysumm, mean sd replace

eststo: reghdfe city_patents_count_assignees_n share_CL_post if pre_2013_company_count>20 & OECD_b80s==0 & year<2023 , absorb(id_populated_city#id_country year) cluster(id_populated_city year#id_country)
quietly estadd local fe_city "Yes"
quietly estadd local fe_year "Yes"
quietly estadd local fe_yearEM "-"
quietly estadd ysumm, mean sd replace

eststo: reghdfe city_patents_count_assignees_n share_CL_post share_CL_post_notoecd if pre_2013_company_count>20 & year<2023 , absorb(id_populated_city#id_country year#OECD_b80s) cluster(id_populated_city year#id_country)
quietly estadd local fe_city "Yes"
quietly estadd local fe_year "Yes"
quietly estadd local fe_yearEM "Yes"
quietly estadd ysumm, mean sd replace

esttab est* using "$TABLE_DIR/tableA29.csv", se replace csv ///
    order(share_CL_post share_CL_post_notoecd) ///
    star(* 0.10 ** 0.05 *** 0.01) se(%10.3f) b(%10.3f) nobase nocons ///
    nonumbers ///
    mtitle("All Cos, EM" "China-Led Cos, EM" "Non-China-Led Cos, EM" "All Cos, Full+EM int" "Patents (assignees), EM" "Patents (assignees), Full+EM int") ///
    coeflabel(share_CL_post "Share China-Led x Post" ///
              share_CL_post_notoecd "Share China-Led x Post x EM") ///
    s(fe_city fe_year fe_yearEM N ymean ysd, ///
      label("City FE" "Year FE" "Year x EM FE" "Number of Obs" "Mean of Dep. Var" "SD of Dep. Var") ///
      fmt(0 0 0 0 3 3))

log close
