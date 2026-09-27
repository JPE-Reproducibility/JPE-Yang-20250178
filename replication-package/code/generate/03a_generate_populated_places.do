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
cap mkdir "$ROOT/confidential-data-not-for-publication/Analysis"
cap mkdir "$TMP"

cd "$TMP"
shp2dta using $RAW/geocoding_resource/ne_10m_populated_places, database(populated_places_data) coordinates(populated_places_coords) replace
use populated_places_data, clear
merge 1:1 _ID using populated_places_coords
drop _merge
drop MEGANAME LS_NAME MAX_POP10 MAX_POP20 MAX_POP50 MAX_POP300 MAX_POP310 MAX_NATSCA MIN_AREAKM MAX_AREAKM MIN_AREAMI MAX_AREAMI MIN_PERKM MAX_PERKM MIN_PERMI MAX_PERMI MIN_BBXMIN MAX_BBXMIN MIN_BBXMAX MAX_BBXMAX MIN_BBYMIN MAX_BBYMIN MIN_BBYMAX MAX_BBYMAX MEAN_BBXC MEAN_BBYC TIMEZONE UN_FID POP1950 POP1955 POP1960 POP1965 POP1970 POP1975 POP1980 POP1985 POP1990 POP1995 POP2000 POP2005 POP2010 POP2015 POP2020 POP2025 POP2050 MIN_ZOOM WIKIDATAID WOF_ID CAPALT NAME_EN NAME_DE NAME_ES NAME_FR NAME_PT NAME_RU NAME_ZH LABEL NAME_AR NAME_BN NAME_EL NAME_HI NAME_HU NAME_ID NAME_IT NAME_JA NAME_KO NAME_NL NAME_PL NAME_SV NAME_TR NAME_VI NE_ID NAME_FA NAME_HE NAME_UK NAME_UR NAME_ZHT GEONAMESID FCLASS_ISO FCLASS_US FCLASS_FR FCLASS_RU FCLASS_ES FCLASS_CN FCLASS_TW FCLASS_IN FCLASS_NP FCLASS_PK FCLASS_DE FCLASS_GB FCLASS_BR FCLASS_IL FCLASS_PS FCLASS_SA FCLASS_EG FCLASS_MA FCLASS_PT FCLASS_AR FCLASS_JP FCLASS_KO FCLASS_VN FCLASS_TR FCLASS_ID FCLASS_PL FCLASS_GR FCLASS_IT FCLASS_NL FCLASS_SE FCLASS_BD FCLASS_UA FCLASS_TLC NOTE LATITUDE LONGITUDE POP_MAX POP_MIN POP_OTHER RANK_MAX RANK_MIN SCALERANK NATSCALE LABELRANK FEATURECLA NAMEPAR NAMEALT ADM0CAP CAPIN WORLDCITY MEGACITY NOTE
save populated_places.dta, replace
di as result "DONE populated_places -> intermediate_and_other_data"
