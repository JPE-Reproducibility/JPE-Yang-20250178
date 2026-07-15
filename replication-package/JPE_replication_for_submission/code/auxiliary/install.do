version 17
set more off
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

capture log close _all
log using "$LOG_DIR/install.log", replace text

* ---------------------------------------------------------------------------
* Compatibility check. Force-reinstall (replace) every dependency so a package
* that is already present but from an older, incompatible vintage is refreshed
* to the current version.
* ---------------------------------------------------------------------------
foreach pkg in ftools reghdfe require estout ivreghdfe ivreg2 ranktest geonear shp2dta nrow {
    display as text "Installing/updating `pkg' from SSC."
    capture noisily ssc install `pkg', replace
}

display as text "Installing/updating binscatter2 from GitHub (mdroste/stata-binscatter2; not on SSC)."
capture noisily net install binscatter2, from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/") replace

* ---------------------------------------------------------------------------
* Availability check. Confirm every dependency is now installed and loadable;
* flag any still missing (e.g., no internet access during the install step).
* ---------------------------------------------------------------------------
local missing 0
foreach pkg in ftools reghdfe require estout ivreghdfe ivreg2 ranktest geonear shp2dta nrow binscatter2 {
    capture which `pkg'
    if _rc != 0 {
        display as error "DEPENDENCY MISSING: `pkg'"
        local missing 1
    }
}
if `missing' == 0 display as result "All Stata dependencies resolved."

log close
