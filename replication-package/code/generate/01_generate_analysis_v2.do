version 19
clear all
set more off
set maxvar 10000

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
global raw_data_folder "$RAW"
global data_folder "$TMP"
global invariant_data_folder "$TMP"
global similarity_root_folder "$CONFRAW/BERT_prediction_resource"

cap mkdir "$TMP"
cap mkdir "$OUT"
adopath + "$TMP"
adopath + "$RAW"

cd $invariant_data_folder

cd $invariant_data_folder
use "$CONFRAW/pitchbook/pbdeals", clear
keep companyid dealid dealdate dealsize dealtype dealstatus
drop if dealstatus == "Failed/Cancelled"
keep if dealtype == "Early Stage VC" | dealtype=="Later Stage VC"
gen year = ustrregexrf(dealdate,"\d\d\/\d\d\/","")
destring year, replace
drop if year ==.
keep if year < 2022 & year > 1999
drop dealdate
merge m:1 companyid using "$CONFRAW/pitchbook/pbcompanies"
keep if _merge == 3
keep if hqcountry == "China" | hqcountry == "United States"
keep companyid dealid dealsize dealstatus dealtype year companyname description hqcountry
duplicates drop dealid, force
bysort year hqcountry: gen dealcount = _N
bysort year hqcountry: egen dealsize_total = sum(dealsize)
duplicates drop year hqcountry, force
keep hqcountry year dealcount dealsize_total
rename dealcount dealno_total

encode hqcountry,gen(hq)
drop hqcountry
reshape wide dealno_total dealsize_total,i(year) j(hq)
rename *1 *_china
rename *2 *_us
save china_us_deals_vc,replace

use "$CONFRAW/pitchbook/pbdeals", clear
keep companyid dealid dealdate dealsize dealtype dealstatus
drop if dealstatus == "Failed/Cancelled"
gen year = ustrregexrf(dealdate,"\d\d\/\d\d\/","")
destring year, replace
drop if year ==.
keep if year < 2022 & year > 1999
drop dealdate
merge m:1 companyid using "$CONFRAW/pitchbook/pbcompanies"
keep if _merge == 3
keep companyid dealid dealsize dealstatus dealtype year companyname description hqcountry
duplicates drop dealid, force

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s=0 if OECD_b80s==.

replace OECD = . if hqcountry == "China" | hqcountry == "United States"
replace OECD_b80s = . if hqcountry == "China" | hqcountry == "United States"

keep if  dealtype == "Early Stage VC" | dealtype=="Later Stage VC"
save pbdeals_vc.dta, replace

use "$CONFRAW/pitchbook/pbdealinvestor",clear
drop lastupdated
merge m:1 investorid using "$CONFRAW/pitchbook/pbinvestors.dta"
keep if _merge == 3
keep dealid investorid investorname investorstatus isleadinvestor investorfundid investorfundname investorwebsite leadpartnerid leadpartnername hqcountry_inv
drop if dealid==""
drop if hqcountry_inv==""
merge m:1 dealid using pbdeals_vc
keep if _merge == 3
drop _merge
save pbdealinvestor_vc.dta,replace

cd $invariant_data_folder
use "$CONFRAW/pitchbook/pbcompanies", clear
merge 1:m companyid using "$CONFRAW/pitchbook/pbdeals"
keep if _merge == 3
keep companyid companyname totalraised businessstatus ownershipstatus companyfinancingstatus financingstatusnote primarycontactpbid primarycontact primarycontacttitle dealid dealdate dealsize postvaluation postvaluationstatus dealtype dealtype2 dealtype3 ceopbid ceo ceobiography ceoeducation
save pbcompanies_extended.dta, replace

use pbcompanies_extended, clear
gen dealyear = ustrregexrf(dealdate,"\d\d\/\d\d\/","")
destring dealyear, replace

gen failure_raw = (dealtype=="Bankruptcy: Admin/Reorg"|dealtype=="Bankruptcy: Liquidation"|dealtype=="Out of Business"|dealtype2=="Bankruptcy: Admin/Reorg"|dealtype2=="Bankruptcy: Liquidation"|dealtype2=="Out of Business"|dealtype3=="Bankruptcy: Admin/Reorg"|dealtype3=="Bankruptcy: Liquidation"|dealtype3=="Out of Business")
gen failure_year_raw = dealyear if failure_raw==1
bysort companyid: egen failure = max(failure_raw)
bysort companyid: egen failure_year = min(failure_year_raw)

gen IPO_raw = (dealtype=="IPO"|dealtype2=="IPO"|dealtype3=="IPO")
gen IPO_year_raw = dealyear if IPO_raw==1
bysort companyid: egen IPO = max(IPO_raw)
bysort companyid: egen IPO_year = min(IPO_year_raw)

gen acquired_raw = (dealtype=="Merger/Acquisition"|dealtype2=="Merger/Acquisition"|dealtype3=="Merger/Acquisition")
gen acquired_year_raw = dealyear if acquired_raw==1
bysort companyid: egen acquired = max(acquired_raw)
bysort companyid: egen acquired_year = min(acquired_year_raw)

bysort companyid: egen failure_count = count(failure_year_raw)
bysort companyid: egen IPO_count = count(IPO_year_raw)
bysort companyid: egen acquired_count = count(acquired_year_raw)

duplicates drop companyid, force
keep companyid failure failure_year IPO IPO_year acquired acquired_year
save pbcompanies_status.dta, replace

cd $data_folder
use "$CONFRAW/BERT_prediction_resource/company_level_predictions_$data_version", clear

cd $invariant_data_folder
merge 1:m companyid using pbdeals_vc
keep if _merge == 3

keep companyid fullname* marketmap* segment* subsegment* hqcountry dealid dealsize dealstatus dealtype year
reshape long fullname marketmap segment subsegment,i(dealid) j(subseg)
drop if fullname == ""

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list"
replace OECD = 0 if OECD ==.
replace OECD_b80s = 0 if OECD_b80s==.
drop joinyear _merge

keep if hqcountry !=""

gen fullname_raw = ustrregexra(fullname,"[^A-Za-z0-9]","")
replace fullname_raw = lower(fullname_raw)
drop if companyid == ""

cd $invariant_data_folder
merge m:1 companyid using pbcompanies_status
drop if _merge == 2
drop _merge

cd $data_folder
save analysis_$data_version.dta, replace

replace dealsize = 308.32 if dealid == "157167-46T"
save analysis_$data_version.dta, replace

cd $invariant_data_folder

use pbdealinvestor_vc.dta, clear
merge m:1 companyid using "$CONFRAW/pitchbook/pbcompanies"
drop if _merge == 2
drop _merge
keep year  companyid hqcountry dealid investorid hqcountry_inv  dealsize   companyname

gen china_inv_t = 0
gen us_inv_t = 0
gen local_inv_t = 0
gen other_inv_t = 0
replace china_inv_t = 1 if hqcountry_inv=="China"
replace us_inv_t = 1 if hqcountry_inv=="United States"
replace local_inv_t = 1 if hqcountry_inv == hqcountry
replace other_inv_t = 1 if hqcountry_inv != "China" & hqcountry_inv != "United States" & hqcountry_inv != hqcountry

bysort dealid: gen count_inv = _N
label var count_inv "Total number of investors"
foreach i of varlist china_inv_t us_inv_t local_inv_t other_inv_t{
	gen `i'_contrib = `i'/count_inv
}

bysort dealid: egen china_inv = max(china_inv_t)
bysort dealid: egen us_inv = max(us_inv_t)
bysort dealid: egen local_inv = max(local_inv_t)
bysort dealid: egen other_inv = max(other_inv_t)

bysort dealid: egen china_inv_s = sum(china_inv_t_contrib)
bysort dealid: egen us_inv_s = sum(us_inv_t_contrib)
bysort dealid: egen local_inv_s = sum(local_inv_t_contrib)
bysort dealid: egen other_inv_s = sum(other_inv_t_contrib)

drop *_t *_contrib investorid hqcountry_inv
duplicates drop dealid, force

gen dealsize_y_us_inv_s = dealsize*us_inv_s
gen dealsize_y_china_inv_s = dealsize*china_inv_s
gen dealsize_y_local_inv_s = dealsize*local_inv_s
gen dealsize_y_other_inv_s = dealsize*other_inv_s

save investor_origin.dta, replace

cd $invariant_data_folder
use pbdealinvestor_vc.dta, clear
drop companyname description OECD OECD_b80s
sort investorid companyid dealid year hqcountry_inv hqcountry
order investorid companyid dealid year hqcountry_inv hqcountry
keep investorid companyid dealid year hqcountry_inv investorname investorstatus isleadinvestor
save pbinvestors_company.dta, replace

cd $data_folder

use analysis_$data_version.dta, clear
keep if hqcountry == "China" | hqcountry == "United States"
gen count = 1
collapse (count) count, by(year hqcountry fullname)
sort fullname year

encode hqcountry, gen(hq)
encode fullname, gen(name)
rename count dealcount

drop hqcountry fullname
reshape wide dealcount , i(year name) j(hq)

rename dealcount1 dealcount_china
rename dealcount2 dealcount_us
decode name, gen(fullname)
drop name
replace dealcount_china = 0 if dealcount_china ==.
replace dealcount_us = 0 if dealcount_us ==.
save china_us_dealcount_$data_version.dta, replace

cd $data_folder
use analysis_$data_version.dta, clear
keep if dealsize !=.
keep if hqcountry == "China" | hqcountry == "United States"

collapse (sum) dealsize, by(year hqcountry fullname)
sort fullname year

encode hqcountry, gen(hq)
encode fullname, gen(name)

drop hqcountry fullname
reshape wide dealsize , i(year name) j(hq)

rename dealsize1 dealsize_china
rename dealsize2 dealsize_us
decode name, gen(fullname)
drop name
replace dealsize_china = 0 if dealsize_china ==.
replace dealsize_us = 0 if dealsize_us ==.
save china_us_dealsize_$data_version.dta, replace

cd $data_folder
use analysis_$data_version.dta, clear
drop if hqcountry == "China" | hqcountry == "United States"
gen count =1
collapse (count) count, by(hqcountry fullname year OECD OECD_b80s)
merge m:1 fullname year using china_us_dealcount_$data_version
keep if _merge ==3
drop _merge
save dealcount_$data_version, replace

cd $data_folder
use analysis_$data_version.dta, clear
drop if hqcountry == "China" | hqcountry == "United States"
collapse (sum) dealsize, by(hqcountry fullname year OECD OECD_b80s)
merge m:1 fullname year using china_us_dealsize_$data_version
keep if _merge ==3
drop _merge
save dealsize_$data_version, replace

cd $data_folder
use analysis_$data_version.dta, clear
drop if hqcountry == "China" | hqcountry == "United States"

cd $invariant_data_folder
merge m:1 dealid using investor_origin
drop if _merge == 2
drop if dealid ==""
drop _merge
cd $data_folder

gen count =1
collapse (sum) count dealsize china_inv us_inv local_inv other_inv china_inv_s us_inv_s local_inv_s other_inv_s dealsize_y_us_inv_s dealsize_y_china_inv_s dealsize_y_local_inv_s dealsize_y_other_inv_s, by(hqcountry fullname year OECD OECD_b80s)
merge m:1 fullname year using china_us_dealcount_$data_version
drop _merge
merge m:1 fullname year using china_us_dealsize_$data_version
drop _merge
rename count dealcount_y
rename dealsize dealsize_y
rename us_inv dealcount_y_us_inv
rename local_inv dealcount_y_local_inv
rename china_inv dealcount_y_china_inv
rename other_inv dealcount_y_other_inv

rename us_inv_s dealcount_y_us_inv_s
rename local_inv_s dealcount_y_local_inv_s
rename china_inv_s dealcount_y_china_inv_s
rename other_inv_s dealcount_y_other_inv_s

drop if hqcountry == ""
drop if fullname == ""
save deal_$data_version, replace

cd $data_folder
use dealcount_$data_version.dta, clear
keep if year <=2019 & year >= 2015
duplicates drop fullname year, force
keep fullname year dealcount_china dealcount_us

collapse (mean) dealcount_china dealcount_us, by(fullname)

gen ChinaPlusUS = dealcount_us + dealcount_china
gen share_china = dealcount_china/ChinaPlusUS
gsort -share_china fullname

preserve
keep if share_china>0.5
save china_led_subsegments_avg_strict_dealcount_$data_version, replace
restore

preserve
keep in 1/129
save china_led_subsegments_avg_loose_dealcount_$data_version, replace
restore

cd $data_folder

insheet using "$similarity_root_folder/similarity_compiled.csv", clear

drop v1 unnamed0
rename companyid1 companyid

replace fullname = lower(fullname)
replace fullname = ustrregexra(fullname,"[^A-Za-z0-9]","")
rename fullname fullname_raw

merge 1:m companyid fullname_raw using analysis_$data_version
drop _merge
order china_similarity_mean china_similarity_10 china_similarity_25 us_similarity_mean us_similarity_10 us_similarity_25 china_similarity_mean_afteronly china_similarity_10_afteronly china_similarity_25_afteronly us_similarity_mean_afteronly us_similarity_10_afteronly us_similarity_25_afteronly fullname_raw subseg, a(OECD_b80s)

merge m:1 fullname using "china_led_subsegments_avg_strict_dealcount_$data_version"
gen china_led_dealcountavg_strict = _merge
drop _merge
replace china_led_dealcountavg_strict = 0 if china_led_dealcountavg_strict == 1
replace china_led_dealcountavg_strict = 1 if china_led_dealcountavg_strict == 3

merge m:1 fullname using "china_led_subsegments_avg_loose_dealcount_$data_version"
gen china_led_dealcountavg_loose = _merge
drop _merge
replace china_led_dealcountavg_loose = 0 if china_led_dealcountavg_loose == 1
replace china_led_dealcountavg_loose = 1 if china_led_dealcountavg_loose == 3

drop share_china ChinaPlusUS  dealcount_china dealcount_us

cd $data_folder
save analysis_$data_version.dta, replace

cd $data_folder
use analysis_$data_version, clear
cd $invariant_data_folder
merge m:1 dealid using "$CONFRAW/pitchbook/pbdeals"
keep if _merge == 3
drop companyname dealno dealdate announceddate dealsizestatus premoneyvaluation postvaluationstatus percentacquired raisedtodate vcround vcroundup_down_flat totalinvestedcapital investorownership stocksplit dealtype2 dealtype3 dealclass dealsynopsis nativecurrencyofdeal totalinvestedequity addon addonsponsors addonplatform totalnewdebt debts contingentpayout employees financingstatus businessstatus sitelocation ceopbid ceo ceobiography ceoeducation typeofstock sharessought pricepershare numberofsharesacquired conversionratio seriesofstock liquidationpreferences participatingvsnonparticipating dividendrights cumulative_noncumulative antidilutionprovisions redemptionrights boardvotingrights generalvotingrights originalregistrationdate currentregistrationdate tickersymbol exchange filingrangelow filingrangehigh numberofshares marketcapendoffirsttradingday price1dayafteroffering price5daysafteroffering price30daysafteroffering investors newinvestors followoninvestors impliedev revenue revenuegrowthsincelastdebtdeal grossprofit netincome ebitda totaldebt fiscalyear debt_ebitda debt_equity dealsize_ebitda valuation_ebitda impliedev_ebitda valuation_ebit valuation_netincome dealsize_ebit dealsize_netincome impliedev_ebit dealsize_revenue valuation_revenue impliedev_revenue dealsize_cashflow valuation_cashflow impliedev_cashflow impliedev_netincome ebitdamarginpercent lastupdated _merge

order postvaluation,a(dealsize)

gen dealsize10m = (dealsize>=10 & dealsize!=.)
gen dealsize25m = (dealsize>=25 & dealsize!=.)
gen dealsize50m = (dealsize>=50 & dealsize!=.)
gen dealsize100m = (dealsize>=100 & dealsize!=.)

cd $data_folder
save analysis_$data_version,  replace

use analysis_$data_version, clear
replace dealsize = 308.32 if dealid == "157167-46T"
save analysis_$data_version,  replace
save "$OUT/analysis_v2.dta", replace
erase "$TMP/analysis_$data_version.dta"
di as result "AV2_DONE -> Analysis/analysis_v2.dta"
