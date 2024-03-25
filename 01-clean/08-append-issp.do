capture log close
log using 01-clean/_logs/08-append-issp, replace text


//  Program:    08-append-issp.do
//  Task:       Append all ISSP waves into single data file and merge
//              data on OECD membership.
//
//  Input:      state_year_formatv3.csv
//              x-07-issp13-derived.dta
//              x-06-issp03-derived.dta
//              x-05-issp95-derived.dta
//
//  Output:     x-08-issp-allwaves.dta
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
local tag    "08-append-issp.do ml `date'"



//  #1
//  LOAD DATA ON OECD MEMBER COUNTRIES  /////////////////////////////////////

* Import Correlates of War Intergovernmental Orgs data set:
import delimited data/input/state_year_formatv3.csv, clear
* Convert CoW country codes to ISO3N country codes:
kountry ccode, from(cown) to(iso3n)
* Generate indicator for countries that were OECD members in 2014:
gen oecdI = oecd if year == 2014
* Save ISO3N country codes of states that were OECD members in 2014:
levelsof _ISO3N_ if oecdI == 1, local(oecd)



//  #2
//  APPPEND ISSP WAVES  /////////////////////////////////////////////////////

//  #2.1 - Load Data
use data/output/_temp/x-07-issp13-derived.dta, clear
datasignature confirm


//  #2.2 - Append ISSP 03 and 95 to ISSP 13 Data
append using data/output/_temp/x-06-issp03-derived.dta
append using data/output/_temp/x-05-issp95-derived.dta
notes drop _dta in 1/3

notes _dta : (Language "original" uses the original, unrevised labels;  ///
             language "default" uses revised labels \ `tag')


//  #2.3 - Generate OECD Membership Dummy
gen oecdI = 0
label var oecdI "Country is OECD member in 2014"
notes     oecdI: Indicates OECD membership status in 2014 (1 = "OECD member") ///
                 ; membership data from Correlates of War Intergovernmental ///
                 Orgs. data set \ `tag'

foreach i of numlist `oecd' {
    replace oecdI = 1 if countryV3 == `i'
}


//  #2.4 - Organize Data Set
order countryV3 year
order oecdI, after(wave)
order incquinV3, after(edlvlV3)
order ethmajIV2, after(femaleI)
order hompop sss6, after(weight)
order VOTE_LE prty*, last


//  #2.5 - Save Combined ISSP Data File
label data "ISSP National Identity Survey, Harmonized Waves 1-3 \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-08-issp-allwaves.dta, replace


log close
exit
