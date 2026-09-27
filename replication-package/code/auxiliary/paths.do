global data_version "v2"
global suffix "corrected.dta"
global saving_suffix "corrected_120623.dta"
global regression_file "regression_corrected_120623.dta"
global suit_all "suitability_score_all_corrected.dta"
global patent_suffix "new_100k"

if "$REPLICATION_ROOT" == "" {
    local _envroot : environment JPE_GENERATE_ROOT
    if "`_envroot'" != "" {
        global REPLICATION_ROOT "`_envroot'"
    }
    else {
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
}
if "$REPLICATION_ROOT" == "" {
    di as error "Cannot locate the replication package root: no code/auxiliary/paths.do above `c(pwd)'."
    di as error "Run from the package root (or any folder inside it), or set the global REPLICATION_ROOT first."
    exit 601
}

local _orig_pwd "`c(pwd)'"
quietly cd "$REPLICATION_ROOT"
global REPLICATION_ROOT "`c(pwd)'"
quietly cd "`_orig_pwd'"

global CONF_DIR "$REPLICATION_ROOT/confidential-data-not-for-publication"
global PUB_RAW "$REPLICATION_ROOT/data/raw"
global data_folder "$CONF_DIR/Analysis"
global intermediate_data_folder "$CONF_DIR/Analysis/intermediate_and_other_data"
global suit_output_folder "$intermediate_data_folder"
global geolocating_output_folder "$intermediate_data_folder"
global simulation_folder "$intermediate_data_folder"
global patent_output_folder "$PUB_RAW/patent_resource"
global invariant_data_folder "$CONF_DIR/Raw/pitchbook"
global manual_exhibit_folder "$PUB_RAW/other_data_resource"
global manual_exhibit_folder_conf "$CONF_DIR/Raw/other_data_resource"
global tradable_sector "$PUB_RAW/other_data_resource/hand_collected"
global hand_collected_folder "$PUB_RAW/other_data_resource/hand_collected"
global balance_data "$data_folder/analysis_v2.dta"

capture mkdir "$CONF_DIR/Analysis"
capture mkdir "$intermediate_data_folder"

adopath + "$REPLICATION_ROOT/code/auxiliary"

global LOG_DIR "$REPLICATION_ROOT/output/logs"
global TABLE_DIR "$REPLICATION_ROOT/output/tables"
global FIGURE_DIR "$REPLICATION_ROOT/output/figures"
global INTERMEDIATE_DIR "$REPLICATION_ROOT/output/intermediate"

capture mkdir "$REPLICATION_ROOT/output"
capture mkdir "$LOG_DIR"
capture mkdir "$TABLE_DIR"
capture mkdir "$FIGURE_DIR"
capture mkdir "$INTERMEDIATE_DIR"
