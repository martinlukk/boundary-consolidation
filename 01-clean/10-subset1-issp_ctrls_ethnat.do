capture log close
log using 01-clean/_logs/10-subset1-issp_ctrls_ethnat, replace text


//  Program:    10-subset1-issp_ctrls_ethnat.do
//  Task:       (1) Drop all cleaned ISSP variables not used in inequality-
//              nationalism analyses,
//              (2) drop cases for country-years where key analysis variables
//              were not asked,
//              (3) save subsetted data file ready for analysis.
//
//  Input:      x-15-issp_ctrls-cleaned.dta
//  Output:     x-16-issp_ctrls_subset1.dta
//
//  Project:    boundary-consolidation
//  Author:     Martin Lukk / 2023-11-03 (last updated)


//  #0
//  PROGRAM SETUP  //////////////////////////////////////////////////////////
version 15
clear all
macro drop _all
set linesize 80

local date : display %tdCY-N-D date("$S_DATE", "DMY")
local tag    "10-subset1-issp_ctrls_ethnat.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/output/_temp/x-15-issp_ctrls-cleaned.dta, clear
datasignature confirm
notes _dta


//  #2
//  DROP UNUSED VARIABLES  //////////////////////////////////////////////////

* Create country-year variable
egen country_year = group(countryV3 year), label

* Identify and keep only analysis variables
local keepvars countryV3 wave year country_year id ///
               age femaleI ethmajIV2 edlvlV3 incquinV3          /// Demog
               impbornP impcitP impfeelP implangP               /// Nationalism
               impliveP impreligP imprespP                      ///
               gdppc governS migstock kof_trade                 /// Country ctrls
               weight                                           //  Other
keep `keepvars' prty*


//  #3
//  DROP COUNTRY-YEARS COMPLETELY MISSING KEY VARIABLES  ////////////////////

* Generate indicator variable if completely missing a variable
foreach v of local keepvars {
  bysort countryV3 year: egen miss_`v' = min(missing(`v'))
}

* Set indicator if any of key variables missing
local keyvars ethmajIV2 impbornP incquinV3 migstock
gen miss_keyvar = .
foreach v of local keyvars {
    replace miss_keyvar = 1 if miss_`v' == 1
}

* Tally missing country-years by key variable
foreach v in ethmajIV2 impbornP incquinV3 migstock {
  di _newline
  tab country_year if miss_`v' == 1
  local n_cntry = r(r)
  local n_resp  = r(N)
  di _newline
  di "^ Key variable " " * `v' * " " missing for " `n_cntry' " countries and " `n_resp' " respondents"
  di _newline
}

foreach v in keyvar {
  di _newline
  tab country_year if miss_`v' == 1
  local n_cntry = r(r)
  local n_resp  = r(N)
  di _newline
  di "^ At least one key variable" " missing for " `n_cntry' " countries and " `n_resp' " respondents"
  di _newline
}

di _newline
di "Missing all values on at least on key variable for following country-years:"
levelsof country_year if miss_keyvar == 1, local(countryyears_miss)
foreach c of numlist `countryyears_miss' {
  local lab: label country_year `c'
  di "    `lab'"
}

* Drop country-years with all missing of kew variables
foreach c of numlist `countryyears_miss' {
    drop if country_year == `c'
}

* Recode missing values in Wave 3 party variables
foreach v of varlist prty_13_BE-prty_13_ZA {
    recode `v' (0 990 = .)
}


//  #4
//  SAVE NEW DATA SET  //////////////////////////////////////////////////////
order country_year
drop miss_* prty*

label data "ISSP Nat. ID Surveys (1-3) with Country-lvl Controls (Subset) \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-16-issp_ctrls_subset1.dta, replace


log close
exit
