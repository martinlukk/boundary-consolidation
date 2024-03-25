capture log close
log using 01-clean/_logs/03-clean-issp13, replace text


//  Program:    03-clean-issp13.do
//  Task:       Clean ISSP 13 data.
//
//  Input:      ZA5950_v2-0-0.dta
//  Output:     x-03-issp13-cleaned.dta
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
local tag    "03-clean-issp13.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/input/ZA5950_v2-0-0.dta, clear


//  #2
//  REMOVE DUPLICATE CASES  /////////////////////////////////////////////////

    /* "ZA1490_all_Overview_Duplicated_Records" (2013 tab) in ISSP
    documentation identifies a list of duplicate cases recommended for
    deletion. */

    /* Drops observations that are believed to be problematic near-
    duplicates and recommended for deletion in survey documentation.
    Cases such as this, that differ in a minimal nr. of administrative,
    derived, or protocol variables, are recommended for deletion since they
    are believed to have been produced in error but it is not possible to
    determine which is the copy and which is the true case. */

drop if CASEID == 201306430001515 | CASEID == 201306430001516

local dup_cases 201307100000198 201307100000348 201307100000346 ///
                201307100000197 201307100000203 201307100000349 ///
                201307100000345 201307100000199
foreach case in `dup_cases' {
    di "Drop CASEID == " %15.0f `case' " ..."
    drop if CASEID == `case'
}


//  #3
//  RENAME VARIABLES  ///////////////////////////////////////////////////////

//  #3.1 - Rename Cross-National Variables
local old_new_varname     ///
    CASEID id             ///
    V4 country            ///
                          ///
    V9 impborn            ///
    V10 impcit            ///
    V11 implive           ///
    V12 implang           ///
    V13 imprelig          ///
    V14 impresp           ///
    V15 impfeel           ///
                          ///
    V63 cit               ///
    SEX sex               ///
    AGE age               ///
    MARITAL marital       ///
    DEGREE edlvl          ///
    MAINSTAT wrkstat      ///
    WRKSUP wrksup         ///
                          ///
    UNION union           ///
    TOPBOT sss10          ///
    URBRURAL urbrural     ///
    WEIGHT weight         ///
    HOMPOP hompop

local n : word count `old_new_varname'
forvalues i = 1 (2) `n' {
    local   old_varname : word `i' of `old_new_varname'
    local   j = `i' + 1
    local   new_varname : word `j' of `old_new_varname'
    di      "Renaming `old_varname' ... `new_varname'"
    rename  `old_varname' `new_varname'
}

//  #3.2 - Rename Country-Specific Variables
local prty_vrange   BE_PRTY-ZA_PRTY
local inchs_vrange  BE_INC-ZA_INC
* Separate ETHN1 and ETHN2 variables:
local ETHN1_ETHN2_vrange BE_ETHN1-ZA_ETHN2
foreach v of varlist `ETHN1_ETHN2_vrange' {
   if regexm("`v'", "(1+)$") {
     local ethn1_vrange `ethn1_vrange' `v'
   }
   if regexm("`v'", "(2+)$") {
     local ethn2_vrange `ethn2_vrange' `v'
   }
}

local vranges       prty_vrange                             ///
                    ethn1_vrange ethn2_vrange               ///
                    inchs_vrange
foreach vrange in `vranges'  {
    foreach v of varlist ``vrange'' {
        di "Renaming ... `v'"
        if regexm("`v'", "^([A-Z]+)(_)") {
            local cntry_prefix = "`=regexs(1)'"
        }
        if regexm("`vrange'", "^[a-z]+[0-9]*") {
            local vrange_abbr = "`=regexs(0)'"
        }
        di "New varname is ... " `" `vrange_abbr'_13_`cntry_prefix' "'
        rename `v' `vrange_abbr'_13_`cntry_prefix'
    }
}


//  #4
//  RELABEL VARIABLES  //////////////////////////////////////////////////////

//  #4.1 - Relabel Cross-National Variables
label language original, new copy
label language default
notes: Language "original" uses the original, unrevised labels; language ///
       "default" uses revised labels \ `tag'

#delimit ;
local var_newvarlabel
`" id        "Respondent ID nr."
   country   "Country"

   impborn   "Important: born in"
   impcit    "Important: citizenship"
   implive   "Important: lived most of life"
   implang   "Important: language"
   imprelig  "Important: religion"
   impresp   "Important: respect laws, inst"
   impfeel   "Important: feel member"

   cit       "Is citizen of country"
   sex       "Sex"
   age       "Age"
   marital   "Marital status"
   edlvl     "Education: highest completed lvl"
   wrkstat   "Rs current employmnt status"
   wrksup    "Supervise anyone at work"

   union     "Trade union membership"
   sss10     "Subjective social status, 1-10"
   urbrural  "Urban or rural community"
   weight    "Weighting factor"
   hompop    "Nr of persons in household"
   "' ;
#delimit cr

local n : word count `var_newvarlabel'
forvalues i = 1 (2) `n' {
  local v :             word `i' of `var_newvarlabel'
  local j =             `i' + 1
  local newvarlabel :   word `j' of `var_newvarlabel'
  di "Relabeling `v' ... `newvarlabel'"
  label var `v'   "`newvarlabel'"
}

//  #4.2 - Relabel Country-Specific Variables
local ethn1 ethn1_13_BE-ethn1_13_ZA
local ethn2 ethn2_13_BE-ethn2_13_ZA
local inchs inchs_13_BE-inchs_13_ZA
local prty  prty_13_BE-prty_13_ZA

#delimit ;
local labels `"
    "Ethnic group I"
    "Ethnic group II"
    "Household income"
    "Party affiliation" "' ;
#delimit cr

local n : word count `labels'
local nat_vars ethn1 ethn2 inchs prty
forvalues i = 1/`n' {
    local label : word `i' of `labels'
    local set   : word `i' of `nat_vars'
    foreach var of varlist ``set'' {
        if regexm("`var'", "_([A-Z]+)$") {
            local cntry_abbr = "`=regexs(1)'"
        }
        if regexm("`var'", "[0-9][0-9]") {
            local yr_abbr = "`=regexs(0)'"
        }
        label var `var' "`label' `yr_abbr' (`cntry_abbr')"
    }
}


//  #5
//  RECODE AND RELABEL: NATIONAL IDENTITY VARIABLES  ////////////////////////
label define LimpP 1 NImpAtAll 2 NotVImp 3 FairImp 4 VeryImp

local v_in impborn impcit impfeel implang implive imprelig impresp
foreach v of varlist `v_in' {
   clonevar "`v'P" = `v'
   recode    `v'P     (1 = 4) (2 = 3) (3 = 2) (4 = 1) ///
                      (0 8 9 = .)
   notes     `v'P   : Positively coded clone of renamed source variable `v' \ `tag'
   label values `v'P LimpP
}


//  #6
//  RECODE AND RELABEL: DEMOGRAPHIC VARIABLES  //////////////////////////////

//  #6.1 - EDLVL
label define edlvlV2 0 NoFormalEd 1 PrimarySch  2 IncomplSec ///
                     3 Secondary  4 AboveSecnd  5 UniDegreeOrMo
clonevar edlvlV2 = edlvl
notes edlvlV2: Recoded clone of renamed source variable edlvl; ///
               ISSP 03 codings retained, missing values recoded \ `tag'
recode edlvlV2 (0 = 0) (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5 6 = 5) ///
               (9 = .)
label values edlvlV2 edlvlV2

label define edlvlV3 1 LessThanSec 2 Secondary  ///
                     3 AboveSecnd  4 UniDegreeOrMo
clonevar edlvlV3 = edlvlV2
recode edlvlV3 (0 1 2 = 1) (3 = 2) (4 = 3) (5 = 4)
label values edlvlV3 edlvlV3

//  #6.2 - WRKSTAT
label define wrkstatV2 1 InPaidWrk      2 Unemployed  3 InEdVocTrain ///
                       4 PermSickDisab  5 Retired     6 UnpaidDomWrk ///
                       7 OthrNotinLabrFrc
clonevar wrkstatV2 = wrkstat
notes wrkstatV2: Recoded clone of renamed source variable wrkstat \ `tag'
recode wrkstatV2 (1 = 1) (2 = 2) (3 4 = 3) (6 = 5) (5 7 8 9 = 7) ///
                 (99 = .)
label values wrkstatV2 wrkstatV2

clonevar unemployedI = wrkstatV2
notes unemployedI: Recoded clone of wrkstatV2; ///
                 category 2 "unemployed" coded 1 and others 0 \ `tag'
recode unemployedI (2 = 1) (nonmissing = 0)
label values unemployedI .

//  #6.3 - MARITAL
label define maritalV2 1 MarriedCivPartnrshp  2 Widowed    ///
                       3 DivorcdLegSepartd    4 Separated  ///
                       5 NvrMarriedSingle
clonevar maritalV2 = marital
notes maritalV2: Recoded clone of renamed source variable marital; ///
                 Married/civ. partnership categories collapsed (1) \ `tag'
recode maritalV2 (1 2 = 1) (5 = 2) (4 = 3) (3 = 4) (6 = 5) ///
                 (7 9 = .)
label values maritalV2 maritalV2

//  #6.4 - RECODE TO DUMMY VARIABLES: SEX, WRKSUP, UNION, CITIZEN
label define Lyesno 0 No 1 Yes

* (Loops for easier comparisons with other ISSP wave cleaning code.)
local var_in        wrksup cit
local var_out       wrksupI citizenI
#delimit ;
local new_varlabel `" "Supervises someone at work"
                      "Is citizen of country" "' ;
local note_det     `" "supervises someone at work"
                      "citizen" "' ;
#delimit cr

local n : word count `var_in'
forvalues i = 1/`n' {
    local vin :   word `i' of `var_in'
    local vout:   word `i' of `var_out'
    local nvlbl:  word `i' of `new_varlabel'
    local ndet:   word `i' of `note_det'
    clonevar `vout' = `vin'
    recode   `vout' (1 = 1) (2 = 0) ///
                    (8 9 0 = .)
    lab var  `vout' "`nvlbl'"
    notes    `vout' : Dummy-coded clone of renamed source variable ///
                      `vin' (1 = "`ndet'") \ `tag'
    label values `vout' Lyesno
}


local var_in        union
local var_out       unionI
#delimit ;
local new_varlabel `" "Is trade union member"  "' ;
local note_det     `" "trade union member" "' ;
#delimit cr
local n : word count `var_in'
forvalues i = 1/`n' {
    local vin :   word `i' of `var_in'
    local vout:   word `i' of `var_out'
    local nvlbl:  word `i' of `new_varlabel'
    local ndet:   word `i' of `note_det'
    clonevar `vout' = `vin'
    recode   `vout' (1 = 1) (2 3 = 0) ///
                    (0 7 9 8 = .)
    lab var  `vout' "`nvlbl'"
    notes    `vout' : Dummy-coded clone of renamed source variable ///
                      `vin' (1 = "`ndet'") \ `tag'
    label values `vout' Lyesno
}

clonevar femaleI = sex
recode   femaleI (1 = 0) (2 = 1) ///
                 (9 = .)
label var femaleI "Sex is female"
notes    femaleI : Dummy-coded clone of renamed source variable sex ///
        (1 = "female") \ `tag'
label values femaleI Lyesno

//  #6.5 - REVISE VALUE LABELS: URBRURAL, SSS10, AGE
clonevar urbruralV2 = urbrural
recode urbruralV2 (1 = 1) (2 3 = 2) (4 5 = 3) ///
                  (7 9 = .)
notes urbruralV2: Recoded clone of renamed source variable urbrural ///
                  response categories collapsed into 3 main categories \ `tag'
label define urbruralV2 1 Urban 2 SubrbTwn 3 Rural
label values urbruralV2 urbruralV2

clonevar sss10V2 = sss10
recode sss10V2 (0 99 98 = .)
notes sss10V2: Recoded clone of renamed source variable sss10 ///
               recoded missing value codes \ `tag'
label copy TOPBOT sss10V2
label values sss10V2 sss10V2

recode age (999 = .)
notes age: NOTE: 999 "No answer" has been recoded  to sysmiss (.) in ISSP ///
           13 age variable without renaming the variable or applying a .r ///
           value label. This is to maintain consistency with ISSP 95 and 03 ///
           age variables \ `tag'
label values age .


//  #7
//  RECODE MISSING VALUES: ETHNIC, INCOMEHS  ////////////////////////////////

//  #7.1 - ETHNIC
local ethn_vars ethn1_13_BE ethn1_13_CH ethn1_13_CZ ethn1_13_DE             ///
                ethn1_13_EE ethn1_13_ES ethn1_13_FI ethn1_13_FR ethn1_13_GB ///
                ethn1_13_GE ethn1_13_HR ethn1_13_HU ethn1_13_IE ethn1_13_IL ///
                ethn1_13_IN ethn1_13_IS ethn1_13_JP ethn1_13_KR ethn1_13_LT ///
                ethn1_13_LV ethn1_13_MX ethn1_13_NO ethn1_13_PH ethn1_13_PT ///
                ethn1_13_RU ethn1_13_SE ethn1_13_SI ethn1_13_SK ethn1_13_TR ///
                ethn1_13_TW ethn1_13_ZA
foreach v of varlist `ethn_vars' {
    clonevar `v'_V2 = `v'
    notes `v'_V2: Recoded clone of renamed source variable `v'; ///
                  missing value categories recoded \ `tag'
    local vallab : value label `v'
    label copy `vallab' `v'_V2
    recode `v'_V2 (0 97 98 99 9999 = .)
    label values `v'_V2 `v'_V2
}

local ethn_vars2 ethn1_13_DK ethn1_13_US
    foreach v of varlist `ethn_vars2' {
        clonevar `v'_V2 = `v'
        notes `v'_V2: Recoded clone of renamed source variable `v'; ///
                      missing value categories recoded \ `tag'
        local vallab : value label `v'
        label copy `vallab' `v'_V2
        recode `v'_V2 (0 999 998 = .)
        label values `v'_V2 `v'_V2
    }

//  #7.2 - INCOMEHS
local inchs_vars inchs_13_BE inchs_13_CH inchs_13_CZ inchs_13_DE ///
                 inchs_13_DK inchs_13_EE inchs_13_ES inchs_13_FI ///
                 inchs_13_FR inchs_13_GB inchs_13_GE inchs_13_HR ///
                 inchs_13_HU inchs_13_IE inchs_13_IL inchs_13_IN ///
                 inchs_13_IS inchs_13_JP inchs_13_KR inchs_13_LT ///
                 inchs_13_LV inchs_13_MX inchs_13_NO inchs_13_PH ///
                 inchs_13_PT inchs_13_RU inchs_13_SE inchs_13_SI ///
                 inchs_13_SK inchs_13_TR inchs_13_TW inchs_13_US inchs_13_ZA
foreach v of varlist `inchs_vars' {
    clonevar `v'_V2 = `v'
    notes `v'_V2: Recoded clone of renamed source variable  `v'; ///
                  missing value categories recoded \ `tag'
    local vallab : value label `v'
    label copy `vallab' `v'_V2
    recode `v'_V2 (999990 9999990 99999990 99999992  = .)  ///
                  (99999999 999997 9999997 999999 9999999 100000000 = .)  ///
                  (999998 9999998 = .)
    label values `v'_V2 `v'_V2
}


//  #8
//  RECODE COUNTRY VARIABLE  ////////////////////////////////////////////////

     /* NOTE: ISSP 13 country variable already uses standard ISO 3166 numeric
     (iso3n) country codes; no additional recoding is required to harmonize
     with 95 and 03 waves. Only value labels are adjusted here. */

* Converts country variable into string format based on labels:
decode country, gen(X_country)
label var X_country "Country (String)"
notes     X_country: Temporary country ID variable in string format, based ///
                     on labels for country; for adjusting final country labels \ `tag'
* Remove abbreviations before existing country names:
replace X_country = regexr(X_country, "^[A-Z]+-+", "")

clonevar countryV3 = country
notes countryV3: Clone of renamed source variable country \ `tag'
/* Assign the values of one variable (X_country) as the value labels of
   another variable (countryV3): */
labmask countryV3, values(X_country) lblname(countryV3)

label define countryV3 203 CzechRep       554 NewZealand    ///
                       703 Slovakia       826 UK            ///
                       840 USA            410 SKorea        ///
                       710 SAfrica        528 Netherlands   ///
                       , modify

/* These countries appear in other ISSP waves and labeling them here ensures
   that they remain labeled in the combined ISSP 1-3 data set: */
label define countryV3 36 Australia 40 Austria   100 Bulgaria    ///
                       124 Canada  152 Chile     616 Poland      ///
                       858 Uruguay 862 Venezuela 380 Italy       ///
                       , modify

drop X_country


//  #9
//  DROP UNNECESSARY VARIABLES & RE-ORDER ///////////////////////////////////
#delimit ;
order countryV3 id
      age femaleI citizenI
      edlvlV2 edlvlV3 hompop
      unemployedI wrkstatV2 wrksupI unionI maritalV2
      urbruralV2
      sss10V2
      impbornP-imprespP
      weight
      ethn1_13_BE_V2-ethn1_13_US_V2
      inchs_13_BE_V2-inchs_13_ZA_V2
      prty_13_BE-prty_13_ZA VOTE_LE
      V3 DATEYR ;
#delimit cr

keep countryV3-DATEYR


//  #10
//  SAVE NEW DATA SET  //////////////////////////////////////////////////////
gen       wave = 3
order     wave
label var wave   "ISSP National Identity Survey Module Wave"
notes     wave : Uniquely identifies ISSP national identity survey module ///
                 wave (1-3) \ `tag'

label data "Cleaned ISSP 13 data \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-03-issp13-cleaned.dta, replace


log close
exit
