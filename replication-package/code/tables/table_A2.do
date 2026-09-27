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
log using "$LOG_DIR/tableA2.log", replace text

cd "$data_folder"

tempname M

use analysis_v2, clear
keep if year>=2000 & year<=2019
duplicates drop dealid, force
gen status=.
replace status=1 if hqcountry=="China"
replace status=2 if hqcountry=="United States"
replace status=3 if OECD_b80s==0 & hqcountry!="China" & hqcountry!="United States"
replace status=4 if OECD_b80s==1 & hqcountry!="China" & hqcountry!="United States"
count
local nd_tot = r(N)
forvalues s=1/4 {
	count if status==`s'
	local nd`s' = r(N)
}

use analysis_v2, clear
keep if year>=2000 & year<=2019
duplicates drop companyid, force
gen status=.
replace status=1 if hqcountry=="China"
replace status=2 if hqcountry=="United States"
replace status=3 if OECD_b80s==0 & hqcountry!="China" & hqcountry!="United States"
replace status=4 if OECD_b80s==1 & hqcountry!="China" & hqcountry!="United States"
count
local nc_tot = r(N)
forvalues s=1/4 {
	count if status==`s'
	local nc`s' = r(N)
}

use analysis_v2, clear
keep if year>=2000 & year<=2019
duplicates drop dealid, force
gen status=.
replace status=1 if hqcountry=="China"
replace status=2 if hqcountry=="United States"
replace status=3 if OECD_b80s==0 & hqcountry!="China" & hqcountry!="United States"
replace status=4 if OECD_b80s==1 & hqcountry!="China" & hqcountry!="United States"
quietly summarize dealsize
local ds_tot = r(mean)
forvalues s=1/4 {
	quietly summarize dealsize if status==`s'
	local ds`s' = r(mean)
}

use analysis_v2, clear
keep if year>=2000 & year<=2019
duplicates drop dealid, force
bysort companyid: gen count_deals = _N
duplicates drop companyid, force
gen status=.
replace status=1 if hqcountry=="China"
replace status=2 if hqcountry=="United States"
replace status=3 if OECD_b80s==0 & hqcountry!="China" & hqcountry!="United States"
replace status=4 if OECD_b80s==1 & hqcountry!="China" & hqcountry!="United States"
quietly summarize count_deals
local dc_tot = r(mean)
forvalues s=1/4 {
	quietly summarize count_deals if status==`s'
	local dc`s' = r(mean)
}

use analysis_v2, clear
keep if year>=2000 & year<=2019
duplicates drop dealid, force
bysort companyid: gen count_deals = _N
duplicates drop companyid, force
gen more_than_one = (count_deals > 1)
gen status=.
replace status=1 if hqcountry=="China"
replace status=2 if hqcountry=="United States"
replace status=3 if OECD_b80s==0 & hqcountry!="China" & hqcountry!="United States"
replace status=4 if OECD_b80s==1 & hqcountry!="China" & hqcountry!="United States"
quietly summarize more_than_one
local sh_tot = r(mean)*100
forvalues s=1/4 {
	quietly summarize more_than_one if status==`s'
	local sh`s' = r(mean)*100
}

use analysis_v2, clear
keep if year<=2019
sort companyid fullname dealid
duplicates drop companyid fullname, force
preserve
	bysort fullname: gen count_company = _N
	duplicates drop fullname, force
	quietly summarize count_company, detail
	local b1a_m = r(mean)
	local b1a_p = r(p50)
	local b1a_s = r(sd)
restore
preserve
	bysort companyid: gen count_fullname = _N
	duplicates drop companyid, force
	quietly summarize count_fullname, detail
	local b1b_m = r(mean)
	local b1b_p = r(p50)
	local b1b_s = r(sd)
restore
preserve
	bysort companyid: gen count_fullname = _N
	drop if count_fullname == 1
	duplicates drop companyid, force
	quietly summarize count_fullname, detail
	local b1c_m = r(mean)
	local b1c_p = r(p50)
	local b1c_s = r(sd)
restore

use analysis_v2, clear
keep if year<=2019
sort companyid fullname dealid
duplicates drop companyid fullname, force
count if china_led_dealcountavg_loose==1
local np_cl = r(N)
count if china_led_dealcountavg_loose==0
local np_us = r(N)

use analysis_v2, clear
keep if year<=2019
sort companyid fullname dealid
duplicates drop companyid fullname, force
gen EM2 = 1-OECD_b80s
replace EM2 = . if hqcountry=="United States" | hqcountry=="China"
count if china_led_dealcountavg_loose==1 & EM2==1
local np_cl_em = r(N)
count if china_led_dealcountavg_loose==0 & EM2==1
local np_us_em = r(N)
count if china_led_dealcountavg_loose==1 & EM2==0
local np_cl_ne = r(N)
count if china_led_dealcountavg_loose==0 & EM2==0
local np_us_ne = r(N)

use analysis_v2, clear
keep if year<=2019
sort companyid fullname dealid
duplicates drop companyid fullname, force
quietly summarize dealsize if china_led_dealcountavg_loose==1
local as_cl = r(mean)
quietly summarize dealsize if china_led_dealcountavg_loose==0
local as_us = r(mean)

use analysis_v2, clear
keep if year<=2019
sort companyid fullname dealid
duplicates drop companyid fullname, force
gen EM2 = 1-OECD_b80s
replace EM2 = . if hqcountry=="United States" | hqcountry=="China"
quietly summarize dealsize if china_led_dealcountavg_loose==1 & EM2==1
local as_cl_em = r(mean)
quietly summarize dealsize if china_led_dealcountavg_loose==0 & EM2==1
local as_us_em = r(mean)
quietly summarize dealsize if china_led_dealcountavg_loose==1 & EM2==0
local as_cl_ne = r(mean)
quietly summarize dealsize if china_led_dealcountavg_loose==0 & EM2==0
local as_us_ne = r(mean)

foreach k in _tot 1 2 3 4 {
	local nd`k'  = trim(string(`nd`k'',  "%15.0f"))
	local nc`k'  = trim(string(`nc`k'',  "%15.0f"))
	local ds`k'  = trim(string(`ds`k'',  "%9.2f"))
	local dc`k'  = trim(string(`dc`k'',  "%9.2f"))
	local sh`k'  = trim(string(`sh`k'',  "%9.2f"))
}
foreach k in a b c {
	local b1`k'_m = trim(string(`b1`k'_m', "%9.2f"))
	local b1`k'_p = trim(string(`b1`k'_p', "%9.2f"))
	local b1`k'_s = trim(string(`b1`k'_s', "%9.2f"))
}
foreach k in cl us cl_em us_em cl_ne us_ne {
	local np_`k' = trim(string(`np_`k'', "%15.0f"))
	local as_`k' = trim(string(`as_`k'', "%9.2f"))
}

local out "$TABLE_DIR/tableA2.csv"
file open fh using "`out'", write replace
file write fh `""Panel A: VC Deals",,,,,"' _n
file write fh `"" ,"Total","China","United States","Other EM","Other Non-EM""' _n
file write fh `""Number of VC Deals","`nd_tot'","`nd1'","`nd2'","`nd3'","`nd4'""' _n
file write fh `""Number of Companies with VC Deals","`nc_tot'","`nc1'","`nc2'","`nc3'","`nc4'""' _n
file write fh `""Mean size of VC deals (US$ millions)","`ds_tot'","`ds1'","`ds2'","`ds3'","`ds4'""' _n
file write fh `""Mean number of VC deals per company","`dc_tot'","`dc1'","`dc2'","`dc3'","`dc4'""' _n
file write fh `""Share of companies with > 1 deal (%)","`sh_tot'","`sh1'","`sh2'","`sh3'","`sh4'""' _n
file write fh "" _n
file write fh `""Panel B1: Sectors",,,"' _n
file write fh `"" ,"Mean","Median","SD""' _n
file write fh `""Number of companies per sector","`b1a_m'","`b1a_p'","`b1a_s'""' _n
file write fh `""Number of sectors predicted per company","`b1b_m'","`b1b_p'","`b1b_s'""' _n
file write fh `""Number of sectors conditional on >1 sectors","`b1c_m'","`b1c_p'","`b1c_s'""' _n
file write fh "" _n
file write fh `""Panel B2: Sectors, Divided by China and US Led",,"' _n
file write fh `"" ,"China-led Sectors","US-led Sectors""' _n
file write fh `""Number of company-sector pairs","`np_cl'","`np_us'""' _n
file write fh `""Number of company-sector pairs (other EM)","`np_cl_em'","`np_us_em'""' _n
file write fh `""Number of company-sector pairs (other non-EM)","`np_cl_ne'","`np_us_ne'""' _n
file write fh `""Average deal size (US$ millions)","`as_cl'","`as_us'""' _n
file write fh `""Average deal size (other EM, US$ millions)","`as_cl_em'","`as_us_em'""' _n
file write fh `""Average deal size (other non-EM, US$ millions)","`as_cl_ne'","`as_us_ne'""' _n
file close fh

log close
