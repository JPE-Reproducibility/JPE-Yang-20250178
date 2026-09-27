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
cap mkdir "$TMP"
cap mkdir "$ROOT/confidential-data-not-for-publication"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global OUT  "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
global data_version "v2"
global data_folder "$TMP"
global invariant_data_folder "$CONFRAW/pitchbook"
cap mkdir "$TMP"
cap mkdir "$TMP/progress"

use "$OUT/analysis_$data_version.dta", clear
drop if hqcountry=="China" | hqcountry=="United States"
collapse (sum) IPO acquired failure, by(fullname year hqcountry)
gen subsegment = fullname
save "$TMP/company_outcomes.dta", replace

cd $invariant_data_folder
use pbcompanies, clear
keep companyid primarycontactpbid primarycontact primarycontacttitle
gen founder=primarycontact if strpos(primarycontacttitle,"Founder")
gen founderid = primarycontactpbid if strpos(primarycontacttitle,"Founder")
merge 1:m companyid using pbdeals
keep companyid primarycontactpbid primarycontact primarycontacttitle founder founderid dealid dealdate ceopbid ceo ceobiography ceoeducation
drop if dealdate == ""
gen date = date(dealdate, "MDY")
format date %td
drop if founderid=="" & ceopbid==""
set sortseed 29
sort companyid date dealid

duplicates drop companyid, force

gen founder_proxied = (founder == "" & ceopbid!=primarycontactpbid)
replace founder = ceo if (founder == "" & ceopbid!=primarycontactpbid)
replace founderid = ceopbid if founderid == "" & ceopbid!=primarycontactpbid
keep companyid founder founderid founder_proxied
keep if founder != ""

save "$TMP/pbcompanies_founder", replace

/////////////////////
cd $invariant_data_folder
use "$TMP/pbcompanies_founder", clear
merge 1:m companyid using pbdeals
keep if _merge == 3
drop _merge
keep companyid founder founderid founder_proxied companyname dealid dealdate
gen deal_date = date(dealdate, "MDY")
format deal_date %td
set sortseed 29
sort companyid deal_date dealid
duplicates drop companyid, force
rename deal_date company_first_deal_date
rename dealid company_first_deal_id
drop dealdate
sort founderid company_first_deal_date

cd $data_folder
merge 1:m companyid using "$CONFRAW/BERT_prediction_resource/company_level_predictions_$data_version.dta"
keep if _merge == 3
drop _merge
drop marketmap* segment* subsegment*

forvalues i = 1/12 {
	sort founderid company_first_deal_date companyid
	by founderid: gen first_company_subsegment`i' = fullname`i'[1]
}

bysort founderid: gen by_serial_founder = (_N>1)
keep if by_serial_founder == 1
sort founderid company_first_deal_date companyid
by founderid: gen first_company = (_n==1)
sort founderid company_first_deal_date companyid
by founderid: gen second_company = (_n==2)

gen first_company_first_deal_date0 = company_first_deal_date if first_company == 1
bysort founderid: egen first_company_first_deal_date = min(first_company_first_deal_date0)
format first_company_first_deal_date %td
drop first_company_first_deal_date0

gen second_company_first_deal_date0 = company_first_deal_date if second_company == 1
bysort founderid: egen second_company_first_deal_date = min(second_company_first_deal_date0)
format second_company_first_deal_date %td
drop second_company_first_deal_date0

/////////////////////

keep if first_company == 0
rename fullname* serial_company_subsegment*
drop first_company
cd $invariant_data_folder
merge 1:m companyid using pbdeals
keep if _merge == 3
drop _merge
keep if dealtype == "Early Stage VC" | dealtype == "Later Stage VC"
drop dealstatus dealsizestatus premoneyvaluation postvaluation postvaluationstatus percentacquired raisedtodate vcround vcroundup_down_flat totalinvestedcapital investorownership stocksplit dealtype dealtype2 dealtype3 dealclass dealsynopsis nativecurrencyofdeal totalinvestedequity addon addonsponsors addonplatform totalnewdebt debts contingentpayout employees financingstatus businessstatus sitelocation ceopbid ceo ceobiography ceoeducation typeofstock sharessought pricepershare numberofsharesacquired conversionratio seriesofstock liquidationpreferences participatingvsnonparticipating dividendrights cumulative_noncumulative antidilutionprovisions redemptionrights boardvotingrights generalvotingrights originalregistrationdate currentregistrationdate tickersymbol exchange filingrangelow filingrangehigh numberofshares marketcapendoffirsttradingday price1dayafteroffering price5daysafteroffering price30daysafteroffering investors newinvestors followoninvestors impliedev revenue revenuegrowthsincelastdebtdeal grossprofit netincome ebitda totaldebt fiscalyear debt_ebitda debt_equity dealsize_ebitda valuation_ebitda impliedev_ebitda valuation_ebit valuation_netincome dealsize_ebit dealsize_netincome impliedev_ebit dealsize_revenue valuation_revenue impliedev_revenue dealsize_cashflow valuation_cashflow impliedev_cashflow impliedev_netincome ebitdamarginpercent lastupdated

cd $data_folder
forvalues i = 1/12{
	rename serial_company_subsegment`i' fullname
	merge m:1 fullname using "china_led_subsegments_avg_loose_dealcount_$data_version"
	drop if _merge == 2
	gen china_led_dealcountavg_loose = _merge
	drop _merge dealcount_china dealcount_us ChinaPlusUS share_china
	replace china_led_dealcountavg_loose = 0 if china_led_dealcountavg_loose == 1
	replace china_led_dealcountavg_loose = 1 if china_led_dealcountavg_loose == 3
	replace china_led_dealcountavg_loose = . if fullname == ""
	rename china_led_dealcountavg_loose serial_company_subsegment`i'_CL
	rename fullname	serial_company_subsegment`i'
}

egen min_serial_CL = rowmin(serial_company_subsegment*_CL)
egen max_serial_CL = rowmax(serial_company_subsegment*_CL)
gen serial_founder_china_led = max_serial_CL
gen serial_founder_all_china_led = min_serial_CL
gen serial_founder_not_all_china_led =	1-min_serial_CL
gen serial_founder_non_china_led =	1-max_serial_CL

gen serial_company_deal_year = ustrregexs(1) if ustrregexm(dealdate, "([0-9]{4})")
destring serial_company_deal_year, replace
gen first_company_first_deal_year = year(first_company_first_deal_date)
gen second_company_first_deal_year = year(second_company_first_deal_date)
drop dealno announceddate

rename companyname serial_companyname
rename company_first_deal_id serial_company_first_deal_id
rename companyid serial_companyid
rename hqcountry serial_company_hqcountry
rename dealid serial_company_deal_id
rename dealdate serial_company_deal_date
rename dealsize serial_company_dealsize

cd $data_folder
save founder_deal_level_data_$data_version.dta, replace

cd $data_folder
set sortseed 3
use founder_deal_level_data_$data_version.dta, clear

/////////////////////

forval i=1/12 {
	preserve
		collapse (sum) serial_founder_china_led serial_founder_all_china_led serial_founder_not_all_china_led serial_founder_non_china_led by_serial_founder, by(second_company_first_deal_year first_company_subsegment`i' serial_company_hqcountry)
		rename first_company_subsegment`i' first_company_subsegment
		rename serial_founder_all_china_led serial_founder_all_CL`i'
		rename serial_founder_china_led serial_founder_CL`i'
		rename serial_founder_not_all_china_led serial_founder_not_all_CL`i'
		rename serial_founder_non_china_led serial_founder_non_CL`i'
		rename by_serial_founder by_serial_founder`i'
		drop if first_company_subsegment == ""
		save progress/serial_founder_china_led_by_second_year_first_company_subsegment`i'.dta, replace
	restore
}

/////////////////////

forval i=1/12 {
	preserve
		sort serial_companyid serial_company_deal_year
		duplicates drop serial_companyid, force

		collapse (sum) serial_founder_china_led serial_founder_all_china_led serial_founder_not_all_china_led serial_founder_non_china_led by_serial_founder, by(second_company_first_deal_year first_company_subsegment`i' serial_company_hqcountry)
		rename first_company_subsegment`i' first_company_subsegment
		rename serial_founder_all_china_led serial_founder_all_CL`i'
		rename serial_founder_china_led serial_founder_CL`i'
		rename serial_founder_not_all_china_led serial_founder_not_all_CL`i'
		rename serial_founder_non_china_led serial_founder_non_CL`i'
		rename by_serial_founder by_serial_founder`i'
		drop if first_company_subsegment == ""

		save progress/company_serial_founder_china_led_by_second_year_first_company_subsegment`i'.dta, replace
	restore
}

/////////////////////

forval i=1/12 {
	preserve
		sort founderid serial_company_deal_year serial_companyid
		duplicates drop founderid, force

		collapse (sum) serial_founder_china_led serial_founder_all_china_led serial_founder_not_all_china_led serial_founder_non_china_led by_serial_founder, by(second_company_first_deal_year first_company_subsegment`i' serial_company_hqcountry)
		rename first_company_subsegment`i' first_company_subsegment
		rename serial_founder_all_china_led serial_founder_all_CL`i'
		rename serial_founder_china_led serial_founder_CL`i'
		rename serial_founder_not_all_china_led serial_founder_not_all_CL`i'
		rename serial_founder_non_china_led serial_founder_non_CL`i'
		rename by_serial_founder by_serial_founder`i'
		drop if first_company_subsegment == ""

		save progress/founder_serial_founder_china_led_by_second_year_first_company_subsegment`i'.dta, replace
	restore
}

cd $data_folder
use progress/serial_founder_china_led_by_second_year_first_company_subsegment1.dta, clear
forvalues i=2/12 {
	merge 1:1 second_company_first_deal_year first_company_subsegment serial_company_hqcountry using progress/serial_founder_china_led_by_second_year_first_company_subsegment`i'.dta
	drop _merge
}
egen serial_founder_CL = rowtotal(serial_founder_CL*)
egen serial_founder_all_CL = rowtotal(serial_founder_all_CL*)
egen serial_founder_not_all_CL = rowtotal(serial_founder_not_all_CL*)
egen serial_founder_non_CL = rowtotal(serial_founder_non_CL*)
egen by_serial_founder = rowtotal(by_serial_founder*)
keep serial_company_hqcountry first_company_subsegment second_company_first_deal_year serial_founder_CL serial_founder_all_CL serial_founder_not_all_CL serial_founder_non_CL by_serial_founder

rename serial_company_hqcountry hqcountry
label var hqcountry "serial company's hq country"
rename second_company_first_deal_year year
label var year "second company's first deal year"
rename first_company_subsegment subsegment
label var subsegment "first company's subsegment"
save serial_founders_by_second_deal_year.dta, replace

use progress/company_serial_founder_china_led_by_second_year_first_company_subsegment1.dta, clear
forvalues i=2/12 {
	merge 1:1 second_company_first_deal_year first_company_subsegment serial_company_hqcountry using "progress/company_serial_founder_china_led_by_second_year_first_company_subsegment`i'.dta"
	drop _merge
}

egen serial_founder_CL_C = rowtotal(serial_founder_CL*)
egen serial_founder_all_CL_C = rowtotal(serial_founder_all_CL*)
egen serial_founder_not_all_CL_C = rowtotal(serial_founder_not_all_CL*)
egen serial_founder_non_CL_C = rowtotal(serial_founder_non_CL*)
egen by_serial_founder_C = rowtotal(by_serial_founder*)
keep serial_company_hqcountry first_company_subsegment second_company_first_deal_year serial_founder_CL_C serial_founder_all_CL_C serial_founder_not_all_CL_C serial_founder_non_CL_C by_serial_founder_C

rename serial_company_hqcountry hqcountry
label var hqcountry "serial company's hq country"
rename second_company_first_deal_year year
label var year "second company's deal year"
rename first_company_subsegment subsegment
label var subsegment "first company's subsegment"
label var by_serial_founder "number of companies by serial founder"

save "progress/company_serial_founders_by_second_deal_year.dta", replace

use progress/founder_serial_founder_china_led_by_second_year_first_company_subsegment1.dta, clear
forvalues i=2/12 {
	merge 1:1 second_company_first_deal_year first_company_subsegment serial_company_hqcountry using "progress/founder_serial_founder_china_led_by_second_year_first_company_subsegment`i'.dta"
	drop _merge
}

egen serial_founder_CL_F = rowtotal(serial_founder_CL*)
egen serial_founder_all_CL_F = rowtotal(serial_founder_all_CL*)
egen serial_founder_not_all_CL_F = rowtotal(serial_founder_not_all_CL*)
egen serial_founder_non_CL_F = rowtotal(serial_founder_non_CL*)
egen by_serial_founder_F = rowtotal(by_serial_founder*)
keep serial_company_hqcountry first_company_subsegment second_company_first_deal_year serial_founder_CL_F serial_founder_all_CL_F serial_founder_not_all_CL_F serial_founder_non_CL_F by_serial_founder_F

rename serial_company_hqcountry hqcountry
label var hqcountry "serial company's hq country"
rename second_company_first_deal_year year
label var year "second company's deal year"
rename first_company_subsegment subsegment
label var subsegment "first company's subsegment"
label var by_serial_founder "number of  serial founders"

save progress/founder_serial_founders_by_second_deal_year.dta, replace

use serial_founders_by_second_deal_year.dta, clear
merge 1:1 hqcountry year subsegment using "progress/company_serial_founders_by_second_deal_year.dta"
drop _merge
merge 1:1 hqcountry year subsegment using "progress/founder_serial_founders_by_second_deal_year.dta"
drop _merge

foreach var in  serial_founder_CL serial_founder_all_CL serial_founder_not_all_CL serial_founder_non_CL by_serial_founder serial_founder_CL_C serial_founder_all_CL_C serial_founder_not_all_CL_C serial_founder_non_CL_C by_serial_founder_C serial_founder_CL_F serial_founder_all_CL_F serial_founder_not_all_CL_F serial_founder_non_CL_F by_serial_founder_F{
	replace `var' = 0 if `var' == .
}
drop if hqcountry == ""
drop if year ==.
save serial_founders_by_second_deal_year.dta, replace

cap shell rm -rf "$TMP/progress"
if "`c(os)'" == "Windows" {
    local _del = subinstr("$TMP/progress", "/", "\", .)
    cap shell rmdir /s /q "`_del'"
}

use "$OUT/analysis_$data_version.dta", clear
keep if OECD_b80s==0
gen count = 1
collapse (count) count (sum) dealsize, by(fullname year)
gen post2013 = year>2013
collapse (mean) count dealsize, by(fullname post2013)
reshape wide count dealsize, i(fullname) j(post2013)
gen EM_subseg_growth_rate_count = (count1 - count0)/count0
gen EM_subseg_growth_rate_dealsize = (dealsize1 - dealsize0)/dealsize0
keep fullname EM_subseg_growth_rate_count EM_subseg_growth_rate_dealsize
rename fullname subsegment
save "$TMP/EM_subseg_growth_rate.dta", replace

use "$OUT/analysis_$data_version.dta", clear
keep if OECD_b80s==0
drop if hqcountry == "China"
gen count = 1
collapse (count) count (sum) dealsize, by(fullname year)
gen post2013 = year>2013
collapse (mean) count dealsize, by(fullname post2013)
reshape wide count dealsize, i(fullname) j(post2013)
gen EM_subseg_growth_count_noCN = (count1 - count0)/count0
gen EM_subseg_growth_dealsize_noCN = (dealsize1 - dealsize0)/dealsize0
keep fullname EM_subseg_growth_count_noCN EM_subseg_growth_dealsize_noCN
rename fullname subsegment
save "$TMP/EM_subseg_growth_rate_no_China.dta", replace

use "$OUT/analysis_$data_version.dta", clear
keep if year<=2019
keep if hqcountry == "China"
gen count_deal_china = 1
collapse (sum) count_deal_china, by(fullname year)
sort fullname year
encode fullname, gen(fcode)
xtset  fcode year
tsfill,full
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

drop growth_2y shock_year_plus_2 total_deals max_growth_2y count_deal_china fcode

bysort fullname: egen max_shock_year = max(shock_year)
gen no_shock_year_identified= (max_shock_year == 0)
replace shock_year = 1 if year==2013 & no_shock_year_identified==1

keep if shock_year == 1
drop max_shock_year shock_year
rename year shock_year
replace fullname = ustrregexra(fullname,"--", "\|")
save "$TMP/shock_year.dta", replace
di as result "DONE shock_year -> intermediate_and_other_data (257 sectors)"

use "$TMP/pbdealinvestor_vc.dta", clear
keep if hqcountry == "China"
save "$TMP/pbdealinvestor_vc_china.dta", replace

use "$CONFRAW/other_data_resource/LP.dta", clear
keep FundID Foreign
rename FundID investorfundid
merge 1:m investorfundid using "$TMP/pbdealinvestor_vc_china.dta"
drop if _merge == 1
gen matched_with_western = (_merge == 3)
gen matched_and_western = (matched_with_western == 1 & Foreign == 1)
drop _merge
replace matched_and_western = 1 if hqcountry_inv != "China" & hqcountry_inv != "Hong Kong"
bysort dealid: egen any_investor_western = max(matched_and_western)
keep dealid any_investor_western
duplicates drop
save "$TMP/deal_china_western_or_not.dta", replace

use "$TMP/pbdeals_vc.dta", clear
keep companyid dealid dealsize dealstatus dealtype year companyname description hqcountry
merge 1:1 dealid using "$TMP/deal_china_western_or_not.dta"
drop _merge
keep if hqcountry == "China" | hqcountry == "United States"
gen chinese_deals_to_drop = (any_investor_western != 1 & hqcountry == "China")
drop if chinese_deals_to_drop == 1
merge m:1 companyid using "$CONFRAW/BERT_prediction_resource/company_level_predictions_v2"
keep if _merge == 3
keep companyid fullname* hqcountry dealid dealsize dealstatus dealtype year
reshape long fullname, i(dealid) j(subseg)
drop if fullname == ""
drop if companyid == ""
gen count = 1
rename fullname subsegment
collapse (count) count (sum) dealsize, by(subsegment hqcountry year)
drop if hqcountry == ""
rename count dealcount_westernonlyforCN
rename dealsize dealsize_westernonlyforCN
fillin hqcountry subsegment year
replace dealcount_westernonlyforCN = 0 if _fillin == 1
replace dealsize_westernonlyforCN = 0 if _fillin == 1
drop _fillin
encode hqcountry, gen(hq)
encode subsegment, gen(name)
drop subsegment hqcountry
reshape wide dealcount_westernonlyforCN dealsize_westernonlyforCN, i(year name) j(hq)
rename *1 *_china
rename *2 *_us
decode name, gen(fullname)
drop name
replace dealcount_westernonlyforCN_china = 0 if dealcount_westernonlyforCN_china == .
replace dealcount_westernonlyforCN_us    = 0 if dealcount_westernonlyforCN_us    == .
replace dealsize_westernonlyforCN_china  = 0 if dealsize_westernonlyforCN_china  == .
replace dealsize_westernonlyforCN_us     = 0 if dealsize_westernonlyforCN_us     == .
save "$TMP/dealcount_size_westernonlyforCN_china_us.dta", replace

keep if year <= 2019 & year >= 2015
duplicates drop fullname year, force
keep fullname year dealcount_westernonlyforCN_china dealcount_westernonlyforCN_us
collapse (mean) dealcount_westernonlyforCN_china dealcount_westernonlyforCN_us, by(fullname)
gen ChinaPlusUS = dealcount_westernonlyforCN_us + dealcount_westernonlyforCN_china
gen share_china = dealcount_westernonlyforCN_china/ChinaPlusUS
gsort -share_china fullname
keep in 1/132
rename fullname subsegment
keep subsegment
save "$TMP/china_led_subsegments_avg_loose_dealcount_westernonlyforCN.dta", replace
di as result "DONE china_led_subsegments_avg_loose_dealcount_westernonlyforCN -> intermediate_and_other_data"
