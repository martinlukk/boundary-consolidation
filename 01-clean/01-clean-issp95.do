capture log close
log using 01-clean/_logs/01-clean-issp95, replace text


//  Program:    01-clean-issp95.do
//  Task:       Clean ISSP 95 data.
//
//  Input:      ZA2880.dta
//  Output:     x-01-issp95-cleaned.dta
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
local tag    "01-clean-issp95.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/input/ZA2880.dta, clear


//  #2
//  REMOVE DUPLICATE CASES & FIX NON-UNIQUE IDS  ////////////////////////////

    /* "ZA1490_all_Overview_Duplicated_Records" (1995 tab) in ISSP
    documentation identifies a list of duplicate cases recommended for
    deletion and non-unique IDs for cases recommended for assignment to
    new, unique IDs. */

//  #2.1 - Save Values from ISSP Documention
* Duplicate ID values:
local dup_id 1400384 1401067 1900951 2400064 2400067 2400079 2400095 2400096 ///
2400098 2400104 2400489 2401115
* Reference variables to distinguish cases with same ID:
local ref_vars v8 v9 v7 v4 v4 v8 ///
               v4 v8 v8 v8 v8 v7
* Values of ref. variables to distinguish cases with same ID:
local ref_values 3 4 1 1 3 3 ///
                 2 2 2 2 3 3
* New unoccupied ID values:
local new_ids 1401112 1401113 1901902 5014489  ///
              5014490 5014491 5014492 5014493  ///
              5014494 5014495 5014496 5014497

//  #2.2 - Confirm Problematic Cases
duplicates tag v2, gen(X_dtag)
levelsof v2 if X_dtag == 1, local(dup_id_check)
drop X_dtag
assert "`dup_id'" == "`dup_id_check'"

//  #2.3 - Recode Non-Unique IDs
clonevar  v2_V2  = v2
label var v2_V2  "Respondent ID nr. (duplicates fixed)"

local n : word count `dup_id'
forvalues i = 1/`n' {
    local   i_dup_id  : word `i' of `dup_id'
    local   i_new_id  : word `i' of `new_ids'
    local   i_ref_var : word `i' of `ref_vars'
    local   i_ref_val : word `i' of `ref_values'
    recode  v2_V2 (`i_dup_id' = `i_new_id') if `i_ref_var' == `i_ref_val'
}

isid v2_V2

//  #2.4 - Remove "Serious Duplicate" Cases

    /* Drops 2 observations that are believed to be problematic near-
    duplicates and recommended for deletion in survey documentation.
    Cases such as this, that differ in a minimal nr. of administrative,
    derived, or protocol variables, are recommended for deletion since they
    are believed to have been produced in error but it is not possible to
    determine which is the copy and which is the true case. */

drop if v2_V2 == 2000543 | v2_V2 == 2000563


//  #3
//  APPLY REUNIFIED GERMANY WEIGHTING FACTORS  //////////////////////////////

    /* Additional weights must be applied to E. and W. German samples to
    achieve representative reunified Germany sample. These weighting factors
    are found in survey documentation file "Weighting_ISSP1995_english.pdf." */

clonevar  v342_V2  = v342
label var v342_V2  "Weighting factor (Reunified GER incl.)"
* Save weighting factors:
local    GER_W_weight = 1.19455
local    GER_E_weight = 0.59238
* Save country ID values:
local    GER_W_id     = 2
local    GER_E_id     = 3
* Apply weighting factors:
replace  v342_V2      = v342_V2 * `GER_W_weight' if v3 == `GER_W_id'
replace  v342_V2      = v342_V2 * `GER_E_weight' if v3 == `GER_E_id'


//  #4
//  RENAME VARIABLES  ///////////////////////////////////////////////////////

//  #4.1 - Rename Cross-National Variables
local old_new_varname ///
      v2_V2 id        ///
      v3 country      ///
                      ///
      v15 impborn     ///
      v16 impcit      ///
      v17 implive     ///
      v18 implang     ///
      v19 imprelig    ///
      v20 impresp     ///
      v21 impfeel     ///
                      ///
      v63 cit         ///
      v65 ethnic      ///
      v200 sex        ///
      v201 age        ///
      v202 marital    ///
      v205 edlvl      ///
      v206 wrkstat    ///
      v216 wrksup     ///
                      ///
      v241 incomehs   ///
      v268 union      ///
      v267 sss6       ///
      v295 urbrural   ///
      v342_V2 weight  ///
                      ///
      v293 hompop

local n : word count `old_new_varname'
forvalues i = 1 (2) `n' {
    local   old_varname : word `i' of `old_new_varname'
    local   j = `i' + 1
    local   new_varname : word `j' of `old_new_varname'
    di      "Renaming `old_varname' ... `new_varname'"
    rename  `old_varname' `new_varname'
}

//  #4.2 - Rename Country-Specific Variables
local inchs_vrange  v242-v264
local prty_vrange   v270-v292
local vranges inchs_vrange prty_vrange

foreach vrange in `vranges'  {
    foreach v of varlist ``vrange'' {
        di "Renaming ... `v'"
        local old_label : variable label `v'
        * Extract country prefix:
        if regexm("`old_label'", "^([A-Z]+)") {
            local cntry_prefix = "`=regexs(0)'"
        }
        * Extract varname prefix:
        if regexm("`vrange'", "^([a-z]+)(_)") {
            local vrange_abbr = "`=regexs(1)'"
        }
        di "New varname is ... " `" `vrange_abbr'_95_`cntry_prefix' "'
        rename `v' `vrange_abbr'_95_`cntry_prefix'
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
`"  id        "Respondent ID nr."
    country   "Country"

    impborn   "Important: born in"
    impcit    "Important: citizenship"
    implive   "Important: lived most of life"
    implang   "Important: language"
    imprelig   "Important: religion"
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
    sss6      "Subjective social status, 1-6"

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
local inchs   inchs_95_A-inchs_95_USA
local prty    prty_95_A-prty_95_USA

#delimit ;
local labels  `"  "Household income"
                  "Party affiliation"
                  "' ;
#delimit cr

local n : word count `labels'
local nat_vars inchs prty
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
        di "Labelling var `var' ... " `" "`label' `yr_abbr' (`cntry_abbr')" "'
        label var `var' "`label' `yr_abbr' (`cntry_abbr')"
    }
}


//  #6
//  RECODE AND RELABEL: NATIONAL IDENTITY VARIABLES  ////////////////////////
local v_in   impborn impcit impfeel implang implive imprelig impresp
label define LimpP 1 NImpAtAll  2 NotVImp  3 FairImp  4 VeryImp

foreach v of varlist `v_in' {
    clonevar "`v'P" = `v'
    recode    `v'P     (1 = 4) (2 = 3) (3 = 2) (4 = 1) (missing = .)
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
               categories 1-2 ("none" and "incpl primary") collapsed into  ///
               category 0 ("no formal ed"), others retained but labeled ///
               according to ISSP 03 categories \ `tag'
recode edlvlV2 (1 2 = 0) (3 = 1) (4 = 2) (5 = 3) (6 = 4) (7 = 5) (missing = .)
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
                 categories 1-3 (f-time, p-time, less p-time employment) ///
                 collapsed into category 1 ("in paid work") \ `tag'
recode wrkstatV2 (1 2 3 = 1) (5 = 2) (6 = 3) (7 = 5) ///
                 (4 8 9 10 = 7) (missing = .)
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
    * Defines parallel lists:
    local vin :   word `i' of `var_in'
    local vout:   word `i' of `var_out'
    local nvlbl:  word `i' of `new_varlabel'
    local ndet:   word `i' of `note_det'
    *  Performs recoding:
    clonevar `vout' = `vin'
    recode   `vout' (1 = 1) (2 = 0)
    lab var  `vout' "`nvlbl'"
    notes    `vout' : Dummy-coded clone of renamed source variable ///
                      `vin' (1 = "`ndet'") \ `tag'
    label values `vout' Lyesno
}

clonevar femaleI = sex
    recode   femaleI (1 = 0) (2 = 1)
    label var femaleI "Sex is female"
    notes    femaleI : Dummy-coded clone of renamed source variable sex ///
             (1 = "female") \ `tag'
    label values femaleI Lyesno


//  #7.5 - REVISE VALUE LABELS: URBRURAL, SSS6
clonevar urbruralV2 = urbrural
notes urbruralV2: Recoded clone of renamed source variable urbrural ///
                  response categories collapsed into 3 main categories \ `tag'
label define urbruralV2 1 Urban 2 SubrbTwn 3 Rural
label values urbruralV2 urbruralV2

label define sss6 1 LowerCl 2 WrkingC 3 LwrMidC ///
                  4 MiddleC 5 UprMidC 6 UpperCl
label values sss6 sss6


//  #8
//  RECODE COUNTRY VARIABLE  ////////////////////////////////////////////////
clonevar countryV2 = country
notes countryV2:   Recoded clone of renamed source variable country; ///
                   E. and W. GER have been combined \ `tag'
recode countryV2 (2 3 = 5)

label copy V3 countryV2
label values countryV2 countryV2
* Recode E-Germany and W-Germany to "Germany":
label define countryV2 5 Germany, modify

* Convert country variable into string format:
decode countryV2, gen(X_countryV2)
label var X_countryV2 "Country (String)"
notes     X_countryV2: Temporary country ID variable in string format, based ///
                       on labels for countryV2; for matching country labels ///
                       will full, standard names using kountry command \ `tag'

/* Save non-standard ISSP country designations to kountry dictionary, so
   kountry can accurately recode these labels into standard country names: */
*ssc install kountry  // Install if necessary!
kountryadd "aus" to "Australia" add
kountryadd "gb"  to "United Kingdom" add
kountryadd "a"   to "Austria" add
kountryadd "h"   to "Hungary" add
kountryadd "i"   to "Italy" add
kountryadd "irl" to "Ireland" add
kountryadd "nl"  to "Netherlands" add
kountryadd "n"   to "Norway" add
kountryadd "s"   to "Sweden" add
kountryadd "cz"  to "Czech Republic" add
kountryadd "slo" to "Slovenia" add
kountryadd "pl"  to "Poland" add
kountryadd "bg"  to "Bulgaria" add
kountryadd "rus" to "Russia" add
kountryadd "nz"  to "New Zealand" add
kountryadd "cdn" to "Canada" add
kountryadd "rp"  to "Philippines" add
kountryadd "j"   to "Japan" add
kountryadd "e"   to "Spain" add
kountryadd "lv"  to "Latvia" add
kountryadd "sk"  to "Slovak Republic" add

* Match non-standard ISSP country labels to standard long country names:
kountry X_countryV2, from(other) marker
* Rename  var created by kountry featuring standard long country names:
rename NAMES_STD X_countryV3
label var X_countryV3 "Country (Standardized Names)"
notes X_countryV3: Temporary standardized (long) country names; var generated by kountry \ `tag'
* Check that all country labels were recognized and matched:
assert MARKER!=0
drop MARKER

* Match standard long country names to standard ISO country codes:
kountry X_countryV3, from(other) stuck marker
* Clone var created by kountry featuring ISO country codes:
clonevar countryV3 = _ISO3N_
* Fix obsolete USSR code (810) for Russia:
recode countryV3 (810 = 643)

label var countryV3 "Country"
notes     countryV3: Clone of variable _ISO3N_ created by kountry \ `tag'
notes     countryV3: Standard ISO 3166 numeric (iso3n) country codes were ///
                     mapped over original country codes in countryV2 (recoded ///
                     source var); combined E. and W. GER \ `tag'
notes     countryV3: Russian code updated to "643" from old USSR code 810 ///
                     provided by kountry \ `tag'
assert MARKER!=0
drop MARKER

/* Use labmask to assign values of one variable (X_countryV3) as the value
   labels of another variable (countryV3). This is required since kountry
   does not map country names to standardized codes (only vice versa): */

labmask countryV3, values(X_countryV3) lblname(countryV3)
* Adjust labels slightly for legibility:
label define countryV3 203 CzechRep       554 NewZealand    ///
                       703 Slovakia       826 UK            ///
                       840 USA            410 SKorea        ///
                       710 SAfrica        528 Netherlands   ///
                       , modify

drop X_countryV2 X_countryV3 _ISO3N_


//  #9
//  DROP UNNECESSARY VARIABLES & RE-ORDER  //////////////////////////////////
#delimit ;
order countryV3 id
      age femaleI ethnic citizenI
      edlvlV2 edlvlV3
      incomehs hompop
      unemployedI wrkstatV2 wrksupI unionI maritalV2
      urbruralV2
      sss6
      impbornP-imprespP
      weight
      inchs_95_A-inchs_95_USA prty_95_A-prty_95_USA ;
#delimit cr

keep countryV3-prty_95_USA


//  #10
//  SAVE NEW DATA SET  //////////////////////////////////////////////////////
gen       wave = 1
order     wave
label var wave   "ISSP National Identity Survey Module Wave"
notes     wave : Uniquely identifies ISSP national identity survey module ///
                 wave (1-3) \ `tag'

label data "Cleaned ISSP 95 data \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-01-issp95-cleaned.dta, replace


log close
exit
