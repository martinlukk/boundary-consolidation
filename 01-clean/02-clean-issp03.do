capture log close
log using 01-clean/_logs/02-clean-issp03, replace text


//  Program:    02-clean-issp03.do
//  Task:       Clean ISSP 03 data.
//
//  Input:      ZA3910_v2-1-0.dta
//  Output:     x-02-issp03-cleaned.dta
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
local tag    "02-clean-issp03.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/input/ZA3910_v2-1-0.dta, clear


//  #2
//  REMOVE DUPLICATE CASES  /////////////////////////////////////////////////

    /* "ZA1490_all_Overview_Duplicated_Records" (2003 tab) in ISSP
    documentation identifies a list of duplicate cases recommended for
    deletion. */

    /* Drops 2 observations that are believed to be problematic near-
    duplicates and recommended for deletion in survey documentation.
    Cases such as this, that differ in a minimal nr. of administrative,
    derived, or protocol variables, are recommended for deletion since they
    are believed to have been produced in error but it is not possible to
    determine which is the copy and which is the true case. */

drop if V3 == 30001899 | V3 == 30003014


//  #3
//  APPLY REUNIFIED GERMANY WEIGHTING FACTORS  //////////////////////////////

    /* Additional weights must be applied to E. and W. German samples to
    achieve representative reunified Germany sample. These weighting factors
    are found in survey documentation file "Weighting_ISSP2003_english.pdf." */

clonevar  weight_V2 = weight
label var weight_V2   "Weighting factor (Reunified GER incl.)"
notes     weight_V2:  Weights modified and appropriate for analysis of reunified Germany \ `tag'

local     GER_W_weight = 1.232524
local     GER_E_weight = 0.547722
local     GER_W_id     = 2
local     GER_E_id     = 3

replace weight_V2      = weight_V2 * `GER_W_weight' if COUNTRY == `GER_W_id'
replace weight_V2      = weight_V2 * `GER_E_weight' if COUNTRY == `GER_E_id'


//  #4
//  RENAME VARIABLES  ///////////////////////////////////////////////////////
* Drop unnecessary variables, freeing up names:
drop ethnic
drop weight

//  #4.1 - Rename Cross-National Variables
local old_new_varname     ///
    V3 id                 ///
    COUNTRY country       ///
                          ///
    v11 impborn           ///
    v12 impcit            ///
    v13 implive           ///
    v14 implang           ///
    v15 imprelig          ///
    v16 impresp           ///
    v17 impfeel           ///
                          ///
    v56 cit               ///
    v58 ethnic            ///
                          ///
    degree edlvl          ///
    wrkst wrkstat         ///
    income incomehs       ///
                          ///
    topbot sss10          ///
    weight_V2 weight

local n : word count `old_new_varname'
forvalues i = 1 (2) `n' {
    local   old_varname : word `i' of `old_new_varname'
    local   j = `i' + 1
    local   new_varname : word `j' of `old_new_varname'
    rename  `old_varname' `new_varname'
}

//  #4.2 - Rename Country-Specific Variables
local prty_vrange  at_prty-za_prty
local vranges      prty_vrange

foreach vrange in `vranges'  {
    foreach v of varlist ``vrange'' {
        di "Renaming ... `v'"
        if regexm("`v'", "^([a-z]+)(_)") {
            local cntry_prefix = "`=regexs(1)'"
        }
        if regexm("`vrange'", "^([a-z]+)(_)") {
            local vrange_abbr = "`=regexs(1)'"
        }
        local up_cntry_prefix = upper("`cntry_prefix'")
        di "New varname is ... " `" `vrange_abbr'_03_`up_cntry_prefix' "'
        rename `v' `vrange_abbr'_03_`up_cntry_prefix'
    }
}


//  #5
//  RELABEL VARIABLES  //////////////////////////////////////////////////////

//  #5.1 - Relabel Cross-National Variables
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
   ethnic    "Racial/ethnic group"

   sex       "Sex"
   age       "Age"
   marital   "Marital status"
   edlvl     "Education: highest completed lvl"
   wrkstat   "Rs current employmnt status"
   wrksup    "Supervise anyone at work"

   incomehs  "Household income"
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

//  #5.2 - Relabel Country-Specific Variables
local prty  prty_03_AT-prty_03_ZA
#delimit ;
local labels `" "Party affiliation" "' ;
#delimit cr

local n : word count `labels'
local nat_vars prty
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

//  #5.3 - Assign Country-Specific Party Variable Unique Value Label Name (avoid conflict with ISSP 13)
foreach var of varlist `prty' {
    local lblname_old : value label `var'
    local lblname_new "`lblname_old'_03"
    label copy `lblname_old' `lblname_new'
    label values `var' `lblname_new'
}


//  #6
//  RECODE AND RELABEL: NATIONAL IDENTITY VARIABLES  ////////////////////////
label define LimpP 1 NImpAtAll  2 NotVImp  3 FairImp  4 VeryImp

local v_in impborn impcit impfeel implang implive imprelig impresp
foreach v of varlist `v_in' {
    clonevar "`v'P" = `v'
    recode    `v'P     (1 = 4) (2 = 3) (3 = 2) (4 = 1) ///
                       (missing = .)
    notes     `v'P   : Positively coded clone of renamed source variable `v' \ `tag'
    label values `v'P LimpP
}


//  #7
//  RECODE AND RELABEL: DEMOGRAPHIC VARIABLES  //////////////////////////////

//  #7.1 - EDLVL
label define edlvlV2 0 NoFormalEd 1 PrimarySch  2 IncomplSec ///
                     3 Secondary  4 AboveSecnd  5 UniDegreeOrMo
clonevar edlvlV2 = edlvl
notes edlvlV2: Recoded clone of renamed source variable edlvl; ///
               ISSP 03 codings retained \ `tag'
recode edlvlV2 (0 = 0) (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5 = 5) ///
               (7 = . )  /// Swiss "other ed." recoded to sysmiss.
               (missing = .)
label values edlvlV2 edlvlV2

label define edlvlV3 1 LessThanSec 2 Secondary  ///
                     3 AboveSecnd  4 UniDegreeOrMo
clonevar edlvlV3 = edlvlV2
recode edlvlV3 (0 1 2 = 1) (3 = 2) (4 = 3) (5 = 4)
label values edlvlV3 edlvlV3

//  #7.2 - WRKSTAT
label define wrkstatV2 1 InPaidWrk      2 Unemployed  3 InEdVocTrain ///
                       4 PermSickDisab  5 Retired     6 UnpaidDomWrk ///
                       7 OthrNotinLabrFrc
clonevar wrkstatV2 = wrkstat
notes wrkstatV2: Recoded clone of renamed source variable wrkstat; ///
                 categories 1-3 (f-time, p-time, less p-time employment)  ///
                 collapsed into category 1 ("in paid work") \ `tag'
recode wrkstatV2 (1 2 3 = 1) (5 = 2) (6 = 3) (7 = 5) (4 8 9 10 = 7) ///
                 (missing = .)
label values wrkstatV2 wrkstatV2

clonevar unemployedI = wrkstatV2
notes unemployedI: Recoded clone of wrkstatV2; ///
                 category 2 "Unemployed" coded 1 and others 0 \ `tag'
recode unemployedI (2 = 1) (nonmissing = 0)
label values unemployedI .

//  #7.3 - MARITAL
label define maritalV2 1 MarriedCivPartnrshp  2 Widowed    ///
                       3 DivorcdLegSepartd    4 Separated  ///
                       5 NvrMarriedSingle
clonevar maritalV2 = marital
notes maritalV2: Recoded clone of renamed source variable marital \ `tag'
recode maritalV2 (missing = .)
label values maritalV2 maritalV2

//  #7.4 - RECODE TO DUMMY VARIABLES: SEX, WRKSUP, UNION, CITIZEN
label define Lyesno 0 No 1 Yes

local var_in        wrksup union cit
local var_out       wrksupI unionI citizenI
#delimit ;
local new_varlabel `" "Supervises someone at work"
                      "Is trade union member"
                      "Is citizen of country" "' ;
local note_det     `" "supervises someone at work"
                      "trade union member"
                      "citizen" "' ;
#delimit cr

local n : word count `var_in'
forvalues i = 1/`n' {
    * Define parallel lists:
    local vin :   word `i' of `var_in'
    local vout:   word `i' of `var_out'
    local nvlbl:  word `i' of `new_varlabel'
    local ndet:   word `i' of `note_det'
    * Perform recoding:
    clonevar `vout' = `vin'
    recode   `vout' (1 = 1) (2 3 = 0) ///
                    (missing = .)
    lab var  `vout' "`nvlbl'"
    notes    `vout' : Dummy-coded clone of renamed source variable ///
                      `vin' (1 = "`ndet'") \ `tag'
    label values `vout' Lyesno
}

clonevar femaleI = sex
recode   femaleI (1 = 0) (2 = 1) ///
                 (missing = .)
label var femaleI "Sex is female"
notes    femaleI : Dummy-coded clone of renamed source variable sex ///
        (1 = "female") \ `tag'
label values femaleI Lyesno

//  #7.5 - RECODE MISSING VALUES: ETHNIC, INCOMEHS
local var_in ethnic incomehs

foreach v of varlist `var_in' {
  clonevar `v'V2 = `v'
  notes `v'V2: Recoded clone of renamed source variable `v' \ `tag'
  local oldvallab : value label `v'
  label copy `oldvallab' `v'V2
  recode `v'V2 (missing = .)
  label values `v'V2 `v'V2
}

//  #7.6 - REVISE VALUE LABELS: URBRURAL, SSS6
clonevar urbruralV2 = urbrural
    recode urbruralV2 (1 = 1) (2 3 = 2) (4 5 = 3) ///
                      (missing = .)
    notes urbruralV2: Recoded clone of renamed source variable urbrural ///
                      response categories collapsed into 3 main categories \ `tag'
    label define urbruralV2 1 1_Urban 2 2_SubrbTwn 3 3_Rural
    label values urbruralV2 urbruralV2

clonevar sss10V2 = sss10
    recode sss10V2 (missing = .)
    notes sss10V2: Recoded clone of renamed source variable sss10 ///
                   recoded missing value codes \ `tag'
    label copy TOPBOT sss10V2
    label values sss10V2 sss10V2


//  #8
//  RECODE COUNTRY VARIABLE  ////////////////////////////////////////////////
clonevar countryV2 = country
notes countryV2:   Recoded clone of renamed source variable country; ///
                   E. and W. GER samples, Israel Jewish and Arab samples ///
                   have been combined \ `tag'
recode countryV2 (2 3 = 5) (22 23 = 44)

label copy COUNTRY countryV2
label values countryV2 countryV2
label define countryV2 5 Germany 44 Israel, modify

* Convert country variable into string format based on labels:
decode countryV2, gen(X_countryV2)
label var X_countryV2 "Country (String)"
notes     X_countryV2: Temporary country ID variable in string format, based ///
                       on labels for countryV2; for matching country labels ///
                       will full, standard names using kountry package \ `tag'

* Remove abbreviations behind existing country names:
replace X_countryV2 = regexr(X_countryV2, " +\([A-Z]*-?[A-Z]+\)$", "")
* Match standard long country names to standard ISO country codes:
kountry X_countryV2, from(other) stuck marker

* Clone var created by kountry featuring ISO country codes:
clonevar countryV3 = _ISO3N_
* Fix obsolete USSR code (810) for Russia:
recode countryV3 (810 = 643)
label var countryV3 "Country"
notes     countryV3: Clone of variable _ISO3N_ created by kountry \ `tag'
notes     countryV3: Standard ISO 3166 numeric (iso3n) country codes were ///
                     mapped over original country codes in countryV2 (recoded ///
                     source var clone); combined E. and W. GER, ///
                     Jewish and Arab Israel sample \ `tag'
notes     countryV3: Russian code updated to "643" from old USSR code 810 ///
                     provided by kountry \ `tag'
assert MARKER!=0
drop MARKER

/* Use labmask to assign values of one variable (X_countryV2) as the value
   labels of another variable (countryV3). This is required since kountry
   does not map country names to standardized codes (only vice versa): */
labmask countryV3, values(X_countryV2) lblname(countryV3)

label define countryV3 203 CzechRep       554 NewZealand    ///
                       703 Slovakia       826 UK            ///
                       840 USA            410 SKorea        ///
                       710 SAfrica        528 Netherlands   ///
                       , modify

drop X_countryV2 _ISO3N_


//  #9
//  SORT VARIABLES  /////////////////////////////////////////////////////////
#delimit ;
order countryV3 id
      age femaleI ethnicV2 citizenI
      edlvlV2 edlvlV3
      incomehsV2 hompop
      unemployedI wrkstatV2 wrksupI unionI maritalV2
      urbruralV2
      sss10V2
      impbornP-imprespP
      weight country
      prty_03_AT-prty_03_ZA  ;
#delimit cr

keep countryV3-prty_03_ZA


//  #10
//  SAVE NEW DATA SET  //////////////////////////////////////////////////////
gen       wave = 2
order     wave
label var wave   "ISSP National Identity Survey Module Wave"
notes     wave : Uniquely identifies ISSP national identity survey module ///
                 wave (1-3) \ `tag'

label data "Cleaned ISSP 03 data \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-02-issp03-cleaned.dta, replace


log close
exit
