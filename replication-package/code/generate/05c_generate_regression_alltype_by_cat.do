clear all
set more off
set maxvar 30000
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
global suit_all "suitability_score_all_corrected.dta"
global regression_file "$OUT/regression_corrected_120623.dta"
cap mkdir "$TMP"

* Deal-type -> category classification (hand-coded by the authors;
* "drop" marks deal types excluded from the non-VC sample: the baseline VC stages,
* restarts, bankruptcies, secondary transactions, grants, buybacks, etc.)
clear
input str42 dealtype str35 dealtype_cat
"Early Stage VC" "drop"
"Buyout/LBO" "2. IPO/Acquisitions"
"Accelerator/Incubator" "1. Angel investors"
"Later Stage VC" "drop"
"Seed Round" "1. Angel investors"
"Merger/Acquisition" "2. IPO/Acquisitions"
"Angel (individual)" "1. Angel investors"
"PE Growth/Expansion" "3. PE Growth"
"Out of Business" "drop"
"Grant" "drop"
"Debt - General" "4. Debt"
"Secondary Transaction - Private" "drop"
"PIPE" "2. IPO/Acquisitions"
"IPO" "2. IPO/Acquisitions"
"Debt - PPP" "drop"
"Bankruptcy: Liquidation" "drop"
"Equity Crowdfunding" "1. Angel investors"
"Corporate" "5. Corporate investments and others"
"Product Crowdfunding" "1. Angel investors"
"Bankruptcy: Admin/Reorg" "drop"
"Debt Refinancing" "4. Debt"
"Secondary Transaction - Open Market" "drop"
"Convertible Debt" "4. Debt"
"Corporate Asset Purchase" "2. IPO/Acquisitions"
"Joint Venture" "5. Corporate investments and others"
"Undetermined" "drop"
"Public Investment 2nd Offering" "2. IPO/Acquisitions"
"Platform Creation" "drop"
"Mezzanine" "4. Debt"
"Capitalization" "drop"
"Reverse Merger" "2. IPO/Acquisitions"
"Dividend Recapitalization" "2. IPO/Acquisitions"
"Investor Buyout by Management" "2. IPO/Acquisitions"
"Merger of Equals" "2. IPO/Acquisitions"
"Debt Repayment" "drop"
"Leveraged Recapitalization" "2. IPO/Acquisitions"
"Share Repurchase" "drop"
"Debt Conversion" "drop"
"Bridge" "4. Debt"
"GP Stakes" "drop"
"Spin-Off" "drop"
"Sale-Lease back facility" "4. Debt"
"Dividend" "drop"
"Restart - Early VC" "drop"
"Restart - Later VC" "drop"
"Secondary Transaction - Stock Distribution" "drop"
"Restart - Angel" "drop"
"Venture Leasing" "4. Debt"
"Restart - Corporate" "drop"
"Equity For Service" "5. Corporate investments and others"
"Bonds (Convertible)" "4. Debt"
"Corporate Licensing" "5. Corporate investments and others"
"Second Lien" "4. Debt"
end
label variable dealtype_cat "final"
merge 1:m dealtype using "$CONFRAW/pitchbook/pbdeals.dta"
keep if _merge == 3
drop _merge
drop if dealtype_cat == "drop"
table dealtype_cat

preserve
	gen count = 1
	collapse (count) count (sum) dealsize, by(dealtype_cat)
	format dealsize %20.0fc
restore

gen year = ustrregexrf(dealdate,"\d\d\/\d\d\/","")
destring year, replace
drop if year ==.
keep if year < 2020 & year > 1999
drop dealdate
merge m:1 companyid using "$CONFRAW/pitchbook/pbcompanies.dta"
keep if _merge == 3
keep companyid dealtype_cat dealid dealsize dealstatus dealtype year companyname description hqcountry
duplicates drop dealid, force

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list.dta"
drop _merge joinyear
replace OECD = 0 if OECD ==.
replace OECD_b80s=0 if OECD_b80s==.

merge m:1 companyid using "$CONFRAW/BERT_prediction_resource/company_level_predictions_$data_version.dta"
keep if _merge == 3

keep companyid fullname* hqcountry dealid dealsize dealstatus dealtype year dealtype_cat
reshape long fullname,i(dealid) j(subseg)
drop if fullname == ""

merge m:1 hqcountry using "$RAW/other_data_resource/hand_collected/OECD_list.dta"
replace OECD = 0 if OECD ==.
replace OECD_b80s = 0 if OECD_b80s==.
drop if _merge == 2
drop joinyear _merge

gen fullname_raw = ustrregexra(fullname,"[^A-Za-z0-9]","")
replace fullname_raw = lower(fullname_raw)
drop if companyid == ""

gen count = 1
rename fullname subsegment
collapse (count) count (sum) dealsize, by(subsegment hqcountry year dealtype_cat)
drop if hqcountry == ""
encode dealtype_cat, gen(dealtype_cat_code)
drop dealtype_cat
reshape wide count dealsize, i(hqcountry subsegment year) j(dealtype_cat_code)
rename count* dealcount*
rename *1 *_angel
rename *2 *_ipoacq
rename *3 *_pegrowth
rename *4 *_debt
rename *5 *_corpother

fillin hqcountry subsegment year
foreach varname in dealcount_angel dealsize_angel dealcount_ipoacq dealsize_ipoacq dealcount_pegrowth dealsize_pegrowth dealcount_debt dealsize_debt dealcount_corpother dealsize_corpother {
	replace `varname' = 0 if `varname' == .
}
drop _fillin

gen dealcount_non_vc = dealcount_angel + dealcount_ipoacq + dealcount_pegrowth + dealcount_debt + dealcount_corpother
gen dealsize_non_vc = dealsize_angel + dealsize_ipoacq + dealsize_pegrowth + dealsize_debt + dealsize_corpother

save "$TMP/dealcount_size_nonvc_allcountries_by_cat.dta", replace
di as result "DONE STAGE A dealcount_size_nonvc_allcountries_by_cat -> intermediate_and_other_data"

use "$TMP/dealcount_size_nonvc_allcountries_by_cat.dta", clear
keep if hqcountry == "China" | hqcountry == "United States"
encode hqcountry, gen(hq)
encode subsegment, gen(name)
drop subsegment hqcountry
reshape wide dealcount_angel dealsize_angel dealcount_ipoacq dealsize_ipoacq dealcount_pegrowth dealsize_pegrowth dealcount_debt dealsize_debt dealcount_corpother dealsize_corpother dealcount_non_vc dealsize_non_vc, i(year name) j(hq)
rename *1 *_china
rename *2 *_us
decode name, gen(fullname)
drop name

foreach var in dealcount_angel_china dealsize_angel_china dealcount_ipoacq_china dealsize_ipoacq_china dealcount_pegrowth_china dealsize_pegrowth_china dealcount_debt_china dealsize_debt_china dealcount_corpother_china dealsize_corpother_china dealcount_non_vc_china dealsize_non_vc_china dealcount_angel_us dealsize_angel_us dealcount_ipoacq_us dealsize_ipoacq_us dealcount_pegrowth_us dealsize_pegrowth_us dealcount_debt_us dealsize_debt_us dealcount_corpother_us dealsize_corpother_us dealcount_non_vc_us dealsize_non_vc_us {
	replace `var' = 0 if `var' == .
}

save "$TMP/dealcount_size_nonvc_by_cat_china_us.dta", replace

use "$TMP/dealcount_size_nonvc_by_cat_china_us.dta", clear
keep if year <=2019 & year >= 2015
duplicates drop fullname year, force
drop dealsize*
collapse (mean) dealcount_angel_china dealcount_ipoacq_china dealcount_pegrowth_china dealcount_debt_china dealcount_corpother_china dealcount_non_vc_china dealcount_angel_us dealcount_ipoacq_us dealcount_pegrowth_us dealcount_debt_us dealcount_corpother_us dealcount_non_vc_us, by(fullname)

gen ChinaPlusUS_angel = dealcount_angel_china + dealcount_angel_us
gen share_china_angel = dealcount_angel_china/ChinaPlusUS_angel
gen ChinaPlusUS_ipoacq = dealcount_ipoacq_china + dealcount_ipoacq_us
gen share_china_ipoacq = dealcount_ipoacq_china/ChinaPlusUS_ipoacq
gen ChinaPlusUS_pegrowth = dealcount_pegrowth_china + dealcount_pegrowth_us
gen share_china_pegrowth = dealcount_pegrowth_china/ChinaPlusUS_pegrowth
gen ChinaPlusUS_debt = dealcount_debt_china + dealcount_debt_us
gen share_china_debt = dealcount_debt_china/ChinaPlusUS_debt
gen ChinaPlusUS_corpother = dealcount_corpother_china + dealcount_corpother_us
gen share_china_corpother = dealcount_corpother_china/ChinaPlusUS_corpother
gen ChinaPlusUS_nonvc = dealcount_non_vc_china + dealcount_non_vc_us
gen share_china_nonvc = dealcount_non_vc_china/ChinaPlusUS_nonvc

gsort -share_china_angel fullname
gen chinaled_countavg_angel_loose = 0
count if share_china_angel!=.
replace chinaled_countavg_angel_loose = 1 in 1/132
count if share_china_angel>0.5 & share_china_angel!=.

gsort -share_china_ipoacq fullname
gen chinaled_countavg_ipoacq_loose = 0
count if share_china_ipoacq!=.
replace chinaled_countavg_ipoacq_loose = 1 in 1/130
count if share_china_ipoacq>0.5 & share_china_ipoacq!=.

gsort -share_china_pe fullname
gen chinaled_countavg_pe_loose = 0
count if share_china_pegrowth!=.
replace chinaled_countavg_pe_loose = 1 in 1/123
count if share_china_pegrowth>0.5 & share_china_pegrowth!=.
gen chinaled_countavg_pe_strict = 0
replace chinaled_countavg_pe_strict = 1 if share_china_pegrowth>0.5 & share_china_pegrowth!=.

gsort -share_china_debt fullname
gen chinaled_countavg_debt_loose = 0
count if share_china_debt!=.
replace chinaled_countavg_debt_loose = 1 in 1/126
count if share_china_debt>0.5 & share_china_debt!=.

gsort -share_china_corpother fullname
gen chinaled_countavg_corp_loose = 0
count if share_china_corpother!=.
replace chinaled_countavg_corp_loose = 1 in 1/117
count if share_china_corpother>0.5 & share_china_corpother!=.
gen chinaled_countavg_corp_strict = 0
replace chinaled_countavg_corp_strict = 1 if share_china_corpother>0.5 & share_china_corpother!=.

gsort -share_china_nonvc fullname
gen chinaled_countavg_nonvc_loose = 0
count if share_china_nonvc!=.
replace chinaled_countavg_nonvc_loose = 1 in 1/133
count if share_china_nonvc>0.5 & share_china_nonvc!=.
save "$TMP/china_led_subsegments_avg_dealcount_nonvc_by_cat.dta", replace
di as result "DONE STAGE B china_led_subsegments_avg_dealcount_nonvc_by_cat -> intermediate_and_other_data"

use "$TMP/dealcount_size_nonvc_allcountries_by_cat.dta", clear
drop if hqcountry == "China" | hqcountry == "United States"
keep if year<=2019
merge 1:1 subsegment year hqcountry using "$regression_file"
keep year hqcountry subsegment dealcount_angel dealsize_angel dealcount_ipoacq dealsize_ipoacq dealcount_pegrowth dealsize_pegrowth dealcount_debt dealsize_debt dealcount_corpother dealsize_corpother dealcount_non_vc dealsize_non_vc dealcount_y dealsize_y OECD_b80s china_led_countavg_strict china_led_countavg_loose

foreach var in dealcount_angel dealsize_angel dealcount_ipoacq dealsize_ipoacq dealcount_pegrowth dealsize_pegrowth dealcount_debt dealsize_debt dealcount_corpother dealsize_corpother dealcount_non_vc dealsize_non_vc{
	replace `var' = 0 if `var'==.
}

foreach var of varlist china_led_countavg_strict china_led_countavg_loose{
	bysort subsegment: egen m_`var' = max(`var')
	replace `var' = m_`var' if `var'==.
	drop m_`var'
}

bysort hqcountry: egen m_OECD_b80s = max(OECD_b80s)
replace OECD_b80s = m_OECD_b80s if OECD_b80s==.
drop m_OECD_b80s

split subsegment, p("|")
merge m:1 hqcountry using "$TMP/china_$suit_all"
drop if _merge == 2
drop _merge

gen suitability_score_wdi = .
replace suitability_score_wdi = AgTech_SuitSc if subsegment1 == "AgTech"
replace suitability_score_wdi = AI_ML_SuitSc if subsegment1 == "AI ML"
replace suitability_score_wdi = Blockchain_SuitSc if subsegment1 == "Blockchain"
replace suitability_score_wdi = Carbon_and_Emissions_Tech_SuitSc if subsegment1 == "Carbon and Emissions Tech"
replace suitability_score_wdi = DevOps_SuitSc if subsegment1 == "DevOps"
replace suitability_score_wdi = EdTech_SuitSc if subsegment1 == "EdTech"
replace suitability_score_wdi = Enterprise_Health_SuitSc if subsegment1 == "Enterprise Health"
replace suitability_score_wdi = Fintech_SuitSc if subsegment1 == "Fintech"
replace suitability_score_wdi = FoodTech_SuitSc if subsegment1 == "FoodTech"
replace suitability_score_wdi = InfoSec_SuitSc if subsegment1 == "InfoSec"
replace suitability_score_wdi = Insurtech_SuitSc if subsegment1 == "Insurtech"
replace suitability_score_wdi = IoT_SuitSc  if subsegment1 == "IoT"
replace suitability_score_wdi = MobilityTech_SuitSc if subsegment1 == "MobilityTech"
replace suitability_score_wdi = Retail_HealthTech_SuitSc if subsegment1 == "Retail HealthTech"
replace suitability_score_wdi = Supply_Chain_Tech_SuitSc if subsegment1 == "Supply Chain Tech"
replace suitability_score_wdi = 10 - suitability_score_wdi

drop *SuitSc

rename subsegment fullname

merge m:1 fullname using "$TMP/china_led_subsegments_avg_dealcount_nonvc_by_cat.dta"

drop ChinaPlusUS* share_china* _merge
drop if suitability_score_wdi == .

rename chinaled_countavg* CL_c_avg*
rename china_led_countavg* CL_c_avg*
gen post2013 = 1 if year > 2013
replace post2013 = 0 if post2013 ==.
foreach j of varlist CL_c_avg_strict CL_c_avg_loose CL_c_avg_angel_loose CL_c_avg_ipoacq_loose CL_c_avg_pe_loose CL_c_avg_pe_strict CL_c_avg_debt_loose CL_c_avg_corp_loose CL_c_avg_corp_strict CL_c_avg_nonvc_loose {
	gen p2013_`j' = post2013 * `j'
	gen p2013_`j'_s = p2013_`j'*suitability_score_wdi
}

rename dealcount_pegrowth* dealcount_pe*
rename dealsize_pegrowth* dealsize_pe*
rename dealcount_corpother* dealcount_corp*
rename dealsize_corpother* dealsize_corp*

encode fullname, gen(subseg)
encode hqcountry, gen(hq)

foreach y in "_y" "_angel" "_ipoacq" "_pe" "_debt" "_corp" "_non_vc" {
	egen mean_dc_hq_temp_00_12`y' = mean(dealcount`y') if year < 2013, by(hq)
	egen mean_dc_hq_00_12`y' = max(mean_dc_hq_temp_00_12`y'), by(hq)
	drop mean_dc_hq_temp_00_12`y'
	gen dc_norm_mean_00_12`y' = dealcount`y'/mean_dc_hq_00_12`y'

	egen mean_ds_hq_temp_00_12`y' = mean(dealsize`y') if year < 2013, by(hq)
	egen mean_ds_hq_00_12`y' = max(mean_ds_hq_temp_00_12`y'), by(hq)
	drop mean_ds_hq_temp_00_12`y'
	gen ds_norm_mean_00_12`y' = dealsize`y'/mean_ds_hq_00_12`y'
}

foreach count in "dealcount_y" "dealcount_angel" "dealcount_ipoacq" "dealcount_pe" "dealcount_debt" "dealcount_corp" "dealcount_non_vc" {
	gen l`count' = log(`count')
	gen as_`count' = asinh(`count')
}

foreach size in "dealsize_y" "dealsize_angel" "dealsize_ipoacq" "dealsize_pe" "dealsize_debt" "dealsize_corp" "dealsize_non_vc" {
	gen l`size' = log(`size')
	gen as_`size' = asinh(`size')
}

foreach y in "_angel" "_ipoacq" "_pe" "_debt" "_corp" "_non_vc" {
	gen size_pd`y' = dealsize`y'/dealcount`y'
	gen lsize_pd`y' = log(size_pd`y')
	gen as_size_pd`y' = asinh(size_pd`y')

	egen temp1 = sum(dealcount`y') if year<2013, by(subseg)
	egen sum_ex_china_us = max(dealcount`y'), by(subseg)
	egen temp2 = sum(dealcount`y'_china) if year<2013, by(subseg hq)
	egen sum_china = max(temp2), by(subseg)
	egen temp3 = sum(dealcount`y'_us) if year<2013, by(subseg hq)
	egen sum_us = max(temp3), by(subseg)
	gen total_pre_deals`y' = sum_ex_china_us + sum_china + sum_us
	gen ltotal_pre_deals`y' = log(total_pre_deals`y')
	drop temp1 temp2 temp3 sum_ex_china_us sum_china sum_us
}

rename (CL_c_avg_nonvc_loose p2013_CL_c_avg_nonvc_loose p2013_CL_c_avg_nonvc_loose_s) (CL_c_avg_non_vc_loose p2013_CL_c_avg_non_vc_loose p2013_CL_c_avg_non_vc_loose_s)

save "$TMP/regression_alltype_by_cat.dta", replace
di as result "DONE STAGE C regression_alltype_by_cat -> intermediate_and_other_data"
