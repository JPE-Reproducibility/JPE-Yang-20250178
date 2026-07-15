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
log using "$LOG_DIR/figure3.log", replace text

global suffix "corrected"
global regression_file "regression_corrected_120623.dta"
global suit_all suitability_score_all_$suffix

use "$data_folder/$regression_file", clear

rename subsegment1 marketmap

merge m:1 hqcountry marketmap using "$intermediate_data_folder/suitability_all_country_marketmap_corrected"
drop s_s_2_China
drop if _merge == 2
drop _merge

local country_names "Afghanista Albania Algeria Angola Argentina Armenia Australia Austria Azerbaijan Bahrain Bangladesh Barbados Belarus Belgium Belize Benin Bhutan Bolivia BosniaandH Botswana Brazil Brunei Bulgaria BurkinaFas Burundi Cambodia Cameroon Canada CapeVerde CentralAfr Chad Chile Colombia Comoros Congo CostaRica Croatia Cuba Cyprus CzechRepub Denmark Djibouti DominicanR EastTimor Ecuador Egypt ElSalvador Estonia Ethiopia Fiji Finland France Gabon Georgia Germany Ghana Greece Guatemala Guinea Guyana Honduras Hungary Iceland India Indonesia Iran Iraq Ireland Israel Italy IvoryCoast Jamaica Japan Jordan Kazakhstan Kenya Kuwait Kyrgyzstan Laos Latvia Lebanon Lesotho Liberia Lithuania Luxembourg Macedonia Madagascar Malawi Malaysia Maldives Mali Malta Mauritania Mauritius Mexico Moldova Mongolia Montenegro Morocco Mozambique Myanmar Namibia Nepal Netherland NewZealand Nicaragua Niger Nigeria Norway Oman Pakistan Palestine Panama PapuaNewGu Paraguay Peru Philippine Poland Portugal Qatar Romania Russia Rwanda SaintLucia SaudiArabi Senegal Serbia SierraLeon Singapore Slovakia Slovenia SouthAfric SouthKorea Spain SriLanka Sudan Swaziland Sweden Switzerlan Syria Tajikistan Tanzania Thailand TheGambia Togo Tonga Trinidadan Tunisia Turkey Uganda Ukraine UnitedArab UnitedKing UnitedStat Uruguay Uzbekistan Vanuatu Venezuela Vietnam Yemen Zambia Zimbabwe"

local i = 1
foreach country in `country_names' {
    gen s_s_2_`i' = s_s_2_`country'
    local i = `i' + 1
}

reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta: di _b[p2013_CL_countavg_loose_suit]

gen beta = .

forvalues i = 1/162 {

egen maxvar = max(s_s_2_`i')
replace s_s_2_`i' = maxvar - s_s_2_`i'
gen placebo_country_`i' = p2013_china_led_countavg_loose*s_s_2_`i'

reghdfe dealcount_norm_mean_00_12 placebo_country_`i' p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)

replace beta = _b[placebo_country_`i'] if _n==`i'
drop placebo_country_`i'  maxvar

}

drop if beta == .
gen above_beta = .
replace above_beta = 1 if beta >= `trueBeta'
egen pValue = total(above_beta)
replace pValue = pValue / 500
sum pValue
local pValue: di `r(mean)'

hist beta, color(emerald%70) xline(`trueBeta', lcolor(red))  xtitle("Placebo Coefficients with Random Country Appropriateness (ex. China)") xlabel(-6(2)12) bin(20)
graph export "$FIGURE_DIR/figure3a.pdf", replace

capture confirm file "$suit_output_folder/china_suitability_score_all_corrected.dta"
if _rc != 0 {
    display as error "SKIPPED Figure 3b: $suit_output_folder/china_suitability_score_all_corrected.dta not found"
}
else {
use "$data_folder/$regression_file", clear

merge m:1 hqcountry using "$suit_output_folder/china_$suit_all"
drop if _merge == 2
drop _merge

isid subsegment hqcountry year
sort subsegment hqcountry year

gen s2_1 = AgTech_SuitSc
gen s2_2 = AI_ML_SuitSc
gen s2_3 = Blockchain_SuitSc
gen s2_4 = Carbon_and_Emissions_Tech_SuitSc
gen s2_5 = DevOps_SuitSc
gen s2_6 = EdTech_SuitSc
gen s2_7 = Enterprise_Health_SuitSc
gen s2_8 = Fintech_SuitSc
gen s2_9 = FoodTech_SuitSc
gen s2_10 = InfoSec_SuitSc
gen s2_11 = Insurtech_SuitSc
gen s2_12 = IoT_SuitSc
gen s2_13 = MobilityTech_SuitSc
gen s2_14 = Retail_HealthTech_SuitSc
gen s2_15 = Supply_Chain_Tech_SuitSc

reghdfe dealcount_norm_mean_00_12 p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta: di _b[p2013_CL_countavg_loose_suit]

gen beta = .
forvalues i = 1/500 {

	set seed `i'
	gen score = .
	gen which = runiformint(1,15)
	forvalues j = 1/15 {
		replace score = s2_`j' if which==`j'
	}
	egen maxscore = max(score)
	replace score = maxscore - score
	gen suit_placebo = p2013_china_led_countavg_loose*score
	reghdfe dealcount_norm_mean_00_12 suit_placebo p2013_CL_countavg_loose_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
	replace beta = _b[suit_placebo] if _n==`i'
	drop suit_placebo  which score maxscore
}

drop if beta == .
gen above_beta = .
replace above_beta = 1 if beta >= `trueBeta'
egen pValue = total(above_beta)
replace pValue = pValue / 500
sum pValue
local pValue: di `r(mean)'

hist beta, color(emerald%70) xlabel(0(2)9) xline(`trueBeta', lcolor(red))  xtitle("Placebo Coefficients with Random Sector Appropriateness")
graph export "$FIGURE_DIR/figure3b.pdf", replace
}

use "$data_folder/$regression_file", clear

isid subsegment hqcountry year
sort subsegment hqcountry year

reghdfe dealcount_norm_mean_00_12 post_shock_CL_plus_1_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)
local trueBeta: di _b[post_shock_CL_plus_1_suit]
gen beta = .
forvalues i  = 1/500 {
	gen shock_year_p = 2013
	set seed `i'
	gen index = runiform(0,1) if e(sample)==1 & china_led_countavg_loose==1
	bysort subseg (hqcountry year): replace index = index[1]
	replace shock_year_p = 2008 if index<0.007
	replace shock_year_p = 2009 if index>=0.007 & index<0.031  & index!=.
	replace shock_year_p = 2011 if index>=0.031 & index<0.038  & index!=.
	replace shock_year_p = 2012 if index>=0.038 & index<0.0775  & index!=.
	replace shock_year_p = 2013 if index>=0.0775 & index<0.7442  & index!=.
	replace shock_year_p = 2014 if index>=0.7442 & index<0.9147  & index!=.
	replace shock_year_p = 2015 if index>=0.9147 & index<0.9457  & index!=.
	replace shock_year_p = 2016 if index>=0.9457 & index!=.

	gen post_shock_p = (year>shock_year_p)

	gen post_shock_p_CL_suit = post_shock_p*china_led_countavg_loose*suitability_score_wdi

	reghdfe dealcount_norm_mean_00_12 post_shock_p_CL_suit post_shock_CL_plus_1_suit, absorb(hq#year hq#subseg subseg#year) vce(cluster hq)

	replace beta = _b[post_shock_p_CL_suit] if _n==`i'

	drop shock_year_p post_shock_p post_shock_p_CL_suit index
}

drop if beta == .
gen above_beta = .
replace above_beta = 1 if beta >= `trueBeta'
egen pValue = total(above_beta)
replace pValue = pValue / 500
sum pValue
local pValue: di `r(mean)'

save "$INTERMEDIATE_DIR/betas_time_placebo_with_interaction.dta", replace

hist beta, color(emerald%70) xline(`trueBeta', lcolor(red))  xtitle("Placebo Coefficients with Random Shock Year") xlabel(0(2)9)
graph export "$FIGURE_DIR/figure3c.pdf", replace

log close
