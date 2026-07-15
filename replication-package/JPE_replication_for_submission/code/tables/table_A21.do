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
log using "$LOG_DIR/tableA21.log", replace text

global balance_data "$intermediate_data_folder/pre_period_deals.dta"

capture program drop grabc
program define grabc
    args tag yvar fe
    if `fe'==1 reg `yvar' policy_constrained i.marketmap_id, vce(robust)
    else       reg `yvar' policy_constrained, vce(robust)
    local b  = _b[policy_constrained]
    local se = _se[policy_constrained]
    local t  = `b'/`se'
    local star ""
    if abs(`t') > 1.645 local star "*"
    if abs(`t') > 1.960 local star "**"
    if abs(`t') > 2.576 local star "***"
    global b_`tag'  = trim("`: display %9.3f `b''") + "`star'"
    global se_`tag' = "(" + trim("`: display %9.3f `se''") + ")"
end

capture program drop runpanel
program define runpanel
    args pfx cond dochina

    use "$balance_data", clear
    `cond'
    collapse (sum) dealcount dealsize, by(subsegment year policy_constrained)
    sort subsegment year
    fillin subsegment year
    replace dealcount = 0 if dealcount == .
    replace dealsize  = 0 if dealsize  == .
    bysort subsegment: egen pc_new = max(policy_constrained)
    replace policy_constrained = pc_new
    drop pc_new
    by subsegment: gen dc_lag = dealcount[_n-1]
    by subsegment: gen g_dc = (dealcount - dc_lag)/dc_lag if dc_lag>0 & dc_lag!=.
    by subsegment: egen avg_g_dc = mean(g_dc)
    by subsegment: gen ds_lag = dealsize[_n-1]
    by subsegment: gen g_ds = (dealsize - ds_lag)/ds_lag if ds_lag>0 & ds_lag!=.
    by subsegment: egen avg_g_ds = mean(g_ds)
    duplicates drop subsegment policy_constrained, force
    split subsegment, parse("|")
    encode subsegment1, gen(marketmap_id)
    grabc `pfx'_dc_g0 avg_g_dc 0
    grabc `pfx'_dc_g1 avg_g_dc 1
    grabc `pfx'_ds_g0 avg_g_ds 0
    grabc `pfx'_ds_g1 avg_g_ds 1

    if `dochina'==0 {
        use "$balance_data", clear
        `cond'
        duplicates drop hqcountry subsegment year policy_constrained, force
        collapse (count) dealcount, by(subsegment year policy_constrained)
        fillin subsegment year
        replace dealcount = 0 if dealcount == .
        bysort subsegment: egen pc_new = max(policy_constrained)
        replace policy_constrained = pc_new
        drop pc_new
        sort subsegment year
        by subsegment: gen dc_lag = dealcount[_n-1]
        by subsegment: gen g_uc = (dealcount - dc_lag)/dc_lag if dc_lag>0 & dc_lag!=.
        by subsegment: egen avg_g_uc = mean(g_uc)
        duplicates drop subsegment policy_constrained, force
        split subsegment, parse("|")
        encode subsegment1, gen(marketmap_id)
        grabc `pfx'_uc_g0 avg_g_uc 0
        grabc `pfx'_uc_g1 avg_g_uc 1
    }

    use "$balance_data", clear
    `cond'
    duplicates drop companyid subsegment year policy_constrained, force
    collapse (count) dealcount, by(subsegment year policy_constrained)
    fillin subsegment year
    replace dealcount = 0 if dealcount == .
    bysort subsegment: egen pc_new = max(policy_constrained)
    replace policy_constrained = pc_new
    drop pc_new
    sort subsegment year
    by subsegment: gen dc_lag = dealcount[_n-1]
    by subsegment: gen g_ucomp = (dealcount - dc_lag)/dc_lag if dc_lag>0 & dc_lag!=.
    by subsegment: egen avg_g_ucomp = mean(g_ucomp)
    duplicates drop subsegment policy_constrained, force
    split subsegment, parse("|")
    encode subsegment1, gen(marketmap_id)
    grabc `pfx'_ucomp_g0 avg_g_ucomp 0
    grabc `pfx'_ucomp_g1 avg_g_ucomp 1

    use "$balance_data", clear
    `cond'
    collapse (sum) dealcount dealsize, by(subsegment policy_constrained year)
    fillin subsegment year
    replace dealcount = 0 if dealcount == .
    replace dealsize  = 0 if dealsize  == .
    bysort subsegment: egen pc_new = max(policy_constrained)
    replace policy_constrained = pc_new
    drop pc_new
    collapse (mean) dealcount dealsize, by(subsegment policy_constrained)
    split subsegment, parse("|")
    encode subsegment1, gen(marketmap_id)
    grabc `pfx'_dc_l0 dealcount 0
    grabc `pfx'_dc_l1 dealcount 1
    grabc `pfx'_ds_l0 dealsize 0
    grabc `pfx'_ds_l1 dealsize 1

    if `dochina'==0 {
        use "$balance_data", clear
        `cond'
        duplicates drop hqcountry subsegment year, force
        collapse (count) dealcount, by(subsegment policy_constrained year)
        fillin subsegment year
        replace dealcount = 0 if dealcount == .
        bysort subsegment: egen pc_new = max(policy_constrained)
        replace policy_constrained = pc_new
        drop pc_new
        collapse (mean) dealcount, by(subsegment policy_constrained)
        rename dealcount unique_countries
        split subsegment, parse("|")
        encode subsegment1, gen(marketmap_id)
        grabc `pfx'_uc_l0 unique_countries 0
        grabc `pfx'_uc_l1 unique_countries 1
    }

    use "$balance_data", clear
    `cond'
    duplicates drop companyid subsegment year, force
    collapse (count) dealcount, by(subsegment policy_constrained year)
    fillin subsegment year
    replace dealcount = 0 if dealcount == .
    bysort subsegment: egen pc_new = max(policy_constrained)
    replace policy_constrained = pc_new
    drop pc_new
    collapse (mean) dealcount, by(subsegment policy_constrained)
    rename dealcount unique_companies
    split subsegment, parse("|")
    encode subsegment1, gen(marketmap_id)
    grabc `pfx'_ucomp_l0 unique_companies 0
    grabc `pfx'_ucomp_l1 unique_companies 1
end

runpanel A "" 0
runpanel B "keep if OECD_b80s == 0" 0
runpanel C `"keep if hqcountry == "China""' 1

capture file close f
file open f using "$TABLE_DIR/tableA21.csv", write replace text

file write f ",(1),(2),(3),(4)" _n
file write f ",Level Difference,Growth Rate Diff.,Level Diff. (FE),Growth Diff. (FE)" _n

file write f "Panel A: All Countries,,,," _n
file write f "Deal count,${b_A_dc_l0},${b_A_dc_g0},${b_A_dc_l1},${b_A_dc_g1}" _n
file write f ",${se_A_dc_l0},${se_A_dc_g0},${se_A_dc_l1},${se_A_dc_g1}" _n
file write f "Deal size,${b_A_ds_l0},${b_A_ds_g0},${b_A_ds_l1},${b_A_ds_g1}" _n
file write f ",${se_A_ds_l0},${se_A_ds_g0},${se_A_ds_l1},${se_A_ds_g1}" _n
file write f "Unique companies,${b_A_ucomp_l0},${b_A_ucomp_g0},${b_A_ucomp_l1},${b_A_ucomp_g1}" _n
file write f ",${se_A_ucomp_l0},${se_A_ucomp_g0},${se_A_ucomp_l1},${se_A_ucomp_g1}" _n
file write f "Unique countries,${b_A_uc_l0},${b_A_uc_g0},${b_A_uc_l1},${b_A_uc_g1}" _n
file write f ",${se_A_uc_l0},${se_A_uc_g0},${se_A_uc_l1},${se_A_uc_g1}" _n

file write f "Panel B: Emerging Markets,,,," _n
file write f "Deal count,${b_B_dc_l0},${b_B_dc_g0},${b_B_dc_l1},${b_B_dc_g1}" _n
file write f ",${se_B_dc_l0},${se_B_dc_g0},${se_B_dc_l1},${se_B_dc_g1}" _n
file write f "Deal size,${b_B_ds_l0},${b_B_ds_g0},${b_B_ds_l1},${b_B_ds_g1}" _n
file write f ",${se_B_ds_l0},${se_B_ds_g0},${se_B_ds_l1},${se_B_ds_g1}" _n
file write f "Unique companies,${b_B_ucomp_l0},${b_B_ucomp_g0},${b_B_ucomp_l1},${b_B_ucomp_g1}" _n
file write f ",${se_B_ucomp_l0},${se_B_ucomp_g0},${se_B_ucomp_l1},${se_B_ucomp_g1}" _n
file write f "Unique countries,${b_B_uc_l0},${b_B_uc_g0},${b_B_uc_l1},${b_B_uc_g1}" _n
file write f ",${se_B_uc_l0},${se_B_uc_g0},${se_B_uc_l1},${se_B_uc_g1}" _n

file write f "Panel C: China,,,," _n
file write f "Deal count,${b_C_dc_l0},${b_C_dc_g0},${b_C_dc_l1},${b_C_dc_g1}" _n
file write f ",${se_C_dc_l0},${se_C_dc_g0},${se_C_dc_l1},${se_C_dc_g1}" _n
file write f "Deal size,${b_C_ds_l0},${b_C_ds_g0},${b_C_ds_l1},${b_C_ds_g1}" _n
file write f ",${se_C_ds_l0},${se_C_ds_g0},${se_C_ds_l1},${se_C_ds_g1}" _n
file write f "Unique companies,${b_C_ucomp_l0},${b_C_ucomp_g0},${b_C_ucomp_l1},${b_C_ucomp_g1}" _n
file write f ",${se_C_ucomp_l0},${se_C_ucomp_g0},${se_C_ucomp_l1},${se_C_ucomp_g1}" _n
file close f

log close
