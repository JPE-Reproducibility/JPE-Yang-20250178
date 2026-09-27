version 19
clear all
set more off

local _envroot : environment JPE_GENERATE_ROOT
if "`_envroot'" != "" {
    global ROOT "`_envroot'"
}
else if "$REPLICATION_ROOT" != "" {
    global ROOT "$REPLICATION_ROOT"
}
else {
    global ROOT ""
    local _r "."
    forvalues _i = 1/6 {
        capture confirm file "`_r'/code/auxiliary/paths.do"
        if !_rc {
            global ROOT "`_r'"
            continue, break
        }
        local _r "`_r'/.."
    }
}
if "$ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root, or export JPE_GENERATE_ROOT / set global REPLICATION_ROOT."
    exit 601
}
local _pr_pwd "`c(pwd)'"
quietly cd "$ROOT"
global ROOT "`c(pwd)'"
quietly cd "`_pr_pwd'"
global RAW "$ROOT/data/raw"
global CONFRAW "$ROOT/confidential-data-not-for-publication/Raw"
global TMP  "$ROOT/confidential-data-not-for-publication/Analysis/intermediate_and_other_data"
global OUT  "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$TMP"
global dir  "$RAW/"
global data_version "v2"
global patent_folder "$RAW"
global invariant_data_folder "$CONFRAW/pitchbook"
global analysis_data_folder "$CONFRAW/BERT_prediction_resource"
global geolocate_output_folder "$TMP"
global geolocate_data_folder "$TMP"

capture confirm file "$TMP/populated_places.dta"
if _rc {
    di as error "populated_places.dta not found in intermediate_and_other_data -- run 03a_generate_populated_places.do first."
    exit 601
}

insheet using "$TMP/patent_citation_cpc.csv", clear
tostring patent_id, replace
cd $geolocate_output_folder
save patent_citation_cpc.dta, replace

insheet using "$TMP/patent_geolocating_inventors.csv", clear
cd $geolocate_data_folder
geonear patent_id latitude longitude using populated_places, neighbors(_ID _Y _X)
rename nid _ID
merge m:1 _ID using populated_places
drop if _merge == 2
drop _merge

rename _X longitude_populated_city
rename _Y latitude_populated_city
rename NAME name_populated_city
rename NAMEASCII nameascii_populated_city
rename _ID id_populated_city

cd $geolocate_output_folder
save patent_geolocating_nearestcity_inventors.dta, replace

insheet using "$TMP/patent_geolocating_assignees.csv", clear
cd $geolocate_data_folder
geonear patent_id latitude longitude using populated_places, neighbors(_ID _Y _X)
rename nid _ID
merge m:1 _ID using populated_places
drop if _merge == 2
drop _merge

rename _X longitude_populated_city
rename _Y latitude_populated_city
rename NAME name_populated_city
rename NAMEASCII nameascii_populated_city
rename _ID id_populated_city

cd $geolocate_output_folder
save patent_geolocating_nearestcity_assignees.dta, replace

cd $geolocate_data_folder
use "$TMP/pbcompany_location_matched.dta", clear
geonear companyid latitude longitude using populated_places, neighbors(_ID _Y _X)
rename nid _ID

merge m:1 _ID using populated_places
drop if _merge == 2
drop _merge

rename _X longitude_populated_city
rename _Y latitude_populated_city
rename NAME name_populated_city
rename NAMEASCII nameascii_populated_city
rename _ID id_populated_city

cd $invariant_data_folder
merge 1:m companyid using pbdeals
keep if _merge == 3

drop if dealdate == ""
gen date = date(dealdate, "MDY")
format date %td
gen year = year(date)
sort companyid year
duplicates drop companyid, force
rename year company_first_deal_year
keep companyid location_clean hqcountry latitude longitude id_populated_city km_to_nid name_populated_city nameascii_populated_city SOV0NAME SOV_A3 ADM0NAME ADM0_A3 ADM1NAME ISO_A2 longitude_populated_city latitude_populated_city company_first_deal_year

cd $geolocate_output_folder
save company_geolocating_nearestcity.dta, replace

cd $geolocate_output_folder
use company_geolocating_nearestcity.dta, clear

cd $analysis_data_folder
merge 1:m companyid using company_level_predictions_v2.dta
keep if _merge == 3
drop _merge
drop marketmap* segment* subsegment*
reshape long fullname, i(companyid) j(subseg_count)
label value subseg_count subsegment
drop if fullname == ""
merge m:1 fullname using "$TMP/china_led_subsegments_avg_loose_dealcount_v2.dta"
drop if _merge == 2
gen china_led_dealcountavg_loose = _merge

drop _merge dealcount_china dealcount_us ChinaPlusUS share_china
replace china_led_dealcountavg_loose = 0 if china_led_dealcountavg_loose == 1
replace china_led_dealcountavg_loose = 1 if china_led_dealcountavg_loose == 3
replace china_led_dealcountavg_loose = . if fullname == ""
rename china_led_dealcountavg_loose company_subsegment_CL

preserve
keep if company_first_deal_year<=2013
keep if company_first_deal_year>=2000
gen count = 1
collapse (count) total_companies=count (mean) mean_CL=company_subsegment_CL, by(id_populated_city)
rename total_companies pre_2013_company_count
rename mean_CL pre_2013_share_CL_company_subseg
cd $geolocate_output_folder
save city_CL_company_Share.dta, replace
restore

keep companyid location_clean hqcountry id_populated_city name_populated_city company_first_deal_year fullname company_subsegment_CL ADM0NAME ADM0_A3
gen count = 1
rename company_first_deal_year year
rename ADM0NAME country_populated_city
rename ADM0_A3 country_3digit_populated_city

bysort companyid: gen company_subseg_count = _N
bysort companyid: egen comapny_CL_count = sum(company_subsegment_CL)
bysort companyid: egen company_CL_max = max(company_subsegment_CL)
bysort companyid: egen company_CL_min = min(company_subsegment_CL)

gen company_CL = (company_CL_max == 1)
gen company_all_CL =(company_CL_min == 1)
gen company_non_CL =(company_CL_max == 0)
gen company_not_all_CL = (company_CL_min == 0)

duplicates drop companyid, force
drop fullname
cd $geolocate_output_folder
drop count
save company_geolocating_nearestcity_with_CL,replace

cd $geolocate_output_folder
use "$TMP/patent_geolocating_nearestcity_inventors.dta", clear
keep if patent_type == "utility"
gen date = date(patent_date, "YMD")
format date %td
gen year = year(date)
rename ISO_A2 ISO_2digits
keep patent_id id_populated_city name_populated_city nameascii_populated_city SOV0NAME ADM0NAME SOV_A3 ADM0_A3 ISO_2digits year
gen count = 1
merge 1:1 patent_id using "$TMP/patent_citation_cpc.dta"
drop if _merge == 2
drop _merge
collapse (count) city_patents_count_inventors=count (sum) above_99_patents=above_99 above_95_patents=above_95 above_90_patents = above_90 above_75_patents=above_75 above_50_patents=above_50, by(id_populated_city name_populated_city year)
rename *patents *patents_inventors
keep if  year < 2022
drop if id_populated_city == .
save city_patent_inventors, replace

cd $geolocate_output_folder
use "$TMP/patent_geolocating_nearestcity_assignees.dta", clear
keep if patent_type == "utility"
gen date = date(patent_date, "YMD")
format date %td
gen year = year(date)
rename ISO_A2 ISO_2digits
keep patent_id id_populated_city name_populated_city nameascii_populated_city SOV0NAME ADM0NAME SOV_A3 ADM0_A3 ISO_2digits year
gen count = 1
merge 1:1 patent_id using "$TMP/patent_citation_cpc.dta"
drop if _merge == 2
drop _merge
collapse (count) city_patents_count_assignees=count (sum) above_99_patents=above_99 above_95_patents=above_95 above_90_patents = above_90 above_75_patents=above_75 above_50_patents=above_50, by(id_populated_city name_populated_city year)
rename *patents *patents_assignees
keep if  year < 2022
drop if id_populated_city == .
save city_patent_assignees, replace

cd $geolocate_output_folder
use company_geolocating_nearestcity_with_CL,clear
gen count = 1
collapse (sum) city_company_count_total = count city_company_count_CL=company_CL city_company_count_all_CL=company_all_CL city_company_count_non_CL=company_non_CL city_company_count_not_all_CL=company_not_all_CL ,  by(id_populated_city country_populated_city name_populated_city year)

keep if  year < 2022
cd $geolocate_output_folder
save cities_company_4division, replace

cd $geolocate_output_folder
use company_geolocating_nearestcity_with_CL, clear
drop year
cd $invariant_data_folder
merge 1:m companyid using pbdeals
keep if _merge == 3
keep if dealtype == "Early Stage VC" | dealtype == "Later Stage VC"
keep companyid location_clean  id_populated_city name_populated_city country_populated_city country_3digit_populated_city company_CL company_all_CL company_non_CL company_not_all_CL dealid dealdate dealsize

drop if dealdate == ""
gen date = date(dealdate, "MDY")
format date %td
gen year = year(date)
sort companyid year
drop dealdate date

gen count = 1
preserve
collapse (sum) city_dealsize=dealsize (count) city_dealcount=count, by(id_populated_city name_populated_city year country_populated_city)
cd $geolocate_output_folder
save city_dealsize_dealcount, replace
restore
preserve
keep if company_CL == 1
collapse (sum) city_dealsize_CL=dealsize (count) city_dealcount_CL=count, by(id_populated_city year name_populated_city country_populated_city)
cd $geolocate_output_folder
save city_dealsize_dealcount_CL, replace
restore

preserve
keep if company_all_CL == 1
collapse (sum) city_dealsize_all_CL=dealsize (count) city_dealcount_all_CL=count, by(id_populated_city year name_populated_city country_populated_city)
cd $geolocate_output_folder
save city_dealsize_dealcount_all_CL, replace
restore

preserve
keep if company_non_CL == 1
collapse (sum) city_dealsize_non_CL=dealsize (count) city_dealcount_non_CL=count, by(id_populated_city year name_populated_city country_populated_city)
cd $geolocate_output_folder
save city_dealsize_dealcount_non_CL, replace
restore

preserve
keep if company_not_all_CL == 1
collapse (sum) city_dealsize_not_all_CL=dealsize (count) city_dealcount_not_all_CL=count,by(id_populated_city year name_populated_city country_populated_city)
cd $geolocate_output_folder
save city_dealsize_dealcount_not_all_CL, replace
restore

use city_dealsize_dealcount, clear

merge 1:1 id_populated_city  year using city_dealsize_dealcount_CL
drop _merge
replace city_dealsize_CL = 0 if city_dealsize_CL == .
replace city_dealcount_CL = 0 if city_dealcount_CL == .

merge 1:1 id_populated_city  year using city_dealsize_dealcount_all_CL
drop _merge
replace city_dealsize_all_CL = 0 if city_dealsize_all_CL == .
replace city_dealcount_all_CL = 0 if city_dealcount_all_CL == .

merge 1:1 id_populated_city  year using city_dealsize_dealcount_non_CL
drop _merge
replace city_dealsize_non_CL = 0 if city_dealsize_non_CL == .
replace city_dealcount_non_CL = 0 if city_dealcount_non_CL == .

merge 1:1 id_populated_city  year using city_dealsize_dealcount_not_all_CL
drop _merge
replace city_dealsize_not_all_CL = 0 if city_dealsize_not_all_CL == .
replace city_dealcount_not_all_CL = 0 if city_dealcount_not_all_CL == .

merge m:1 id_populated_city year using cities_company_4division
drop _merge

foreach var of varlist city_company_count_CL city_company_count_all_CL city_company_count_non_CL city_company_count_not_all_CL{
    replace `var' = 0 if `var' == .
}

merge m:1 id_populated_city using city_CL_company_Share
gen no_pre2013_company = (_merge == 1)
replace pre_2013_company_count = 0 if no_pre2013_company == 1
replace pre_2013_share_CL_company_subseg = 0 if no_pre2013_company == 1
drop _merge country_populated_city

keep if  year < 2022

save city_company_deal_1005, replace

cd $geolocate_data_folder
use populated_places, clear
rename _X longitude_populated_city
rename _Y latitude_populated_city
rename NAME name_populated_city
rename NAMEASCII nameascii_populated_city
rename _ID id_populated_city
rename ISO_A2 ISO_2digits
drop ADM1NAME

expand 60
bysort id_populated_city: gen year = _n+1961

cd $geolocate_output_folder
merge 1:1 id_populated_city year using city_patent_inventors
drop _merge
merge 1:1 id_populated_city year using city_patent_assignees
drop _merge
merge 1:1 id_populated_city year using city_company_deal_1005
drop _merge

foreach var of varlist city_patents_count_inventors city_patents_count_assignees city_dealsize city_dealcount city_dealsize_CL city_dealcount_CL city_dealsize_all_CL city_dealcount_all_CL city_dealsize_non_CL city_dealcount_non_CL city_dealsize_not_all_CL city_dealcount_not_all_CL city_company_count_total city_company_count_CL city_company_count_all_CL city_company_count_non_CL city_company_count_not_all_CL pre_2013_company_count pre_2013_share_CL_company_subseg no_pre2013_company above_99_patents_inventors above_95_patents_inventors above_90_patents_inventors above_75_patents_inventors above_50_patents_inventors above_99_patents_assignees above_95_patents_assignees above_90_patents_assignees above_75_patents_assignees above_50_patents_assignees{
    replace `var' = 0 if `var' == .
}

bysort id_populated_city: egen city_company_count_allyears = sum(city_company_count_total)
bysort id_populated_city: egen city_patent_count_ay_inventors = sum(city_patents_count_inventors)
bysort id_populated_city: egen city_patent_count_ay_assignees = sum(city_patents_count_assignees)

drop if city_company_count_allyears==0&city_patent_count_ay_inventors==0&city_patent_count_ay_assignees==0
drop city_company_count_allyears city_patent_count_ay_inventors city_patent_count_ay_assignees

gen OECD_b80s =  (ISO_2digit == "AT" | ISO_2digit == "BE" | ISO_2digit == "CA" | ISO_2digit == "DK" | ISO_2digit == "FR" | ISO_2digit == "DE" | ISO_2digit == "GR" | ISO_2digit == "IS" | ISO_2digit == "IE" | ISO_2digit == "LU" | ISO_2digit == "NL" | ISO_2digit == "NO" | ISO_2digit == "PT" | ISO_2digit == "ES" | ISO_2digit == "SE" | ISO_2digit == "CH" | ISO_2digit == "TR" | ISO_2digit == "GB" | ISO_2digit == "US" | ISO_2digit == "IT" | ISO_2digit == "JP" | ISO_2digit == "FI" | ISO_2digit == "AU" | ISO_2digit == "NZ")

encode ISO_2digits, gen(id_country)
order year name_populated_city id_populated_city SOV0NAME id_country OECD_b80s city_patents_count_inventors city_patents_count_assignees city_dealsize city_dealcount city_dealsize_CL city_dealcount_CL city_dealsize_all_CL city_dealcount_all_CL city_dealsize_non_CL city_dealcount_non_CL city_dealsize_not_all_CL city_dealcount_not_all_CL city_company_count_total city_company_count_CL city_company_count_all_CL city_company_count_non_CL city_company_count_not_all_CL pre_2013_company_count pre_2013_share_CL_company_subseg no_pre2013_company
save analysis_city, replace

save "$OUT/analysis_city.dta", replace
di as result "DONE analysis_city -> Analysis/intermediate_and_other_data/analysis_city.dta"
