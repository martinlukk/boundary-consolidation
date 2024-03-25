capture log close
log using 01-clean/_logs/04-clean-issp13NL, replace text


//  Program:    04-clean-issp13NL.do
//  Task:       Clean ISSP 13 (Netherlands) data.
//
//  Input:      ZA5517_v1-0-0.dta
//  Output:     x-04-issp13NL-cleaned.dta
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
local tag    "04-clean-issp13NL.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/input/ZA5517_v1-0-0.dta, clear


//  #2
//  RENAME VARIABLES  ///////////////////////////////////////////////////////
local old_new_varname     ///
    CASEID id             ///
    v4 country            ///
                          ///
    V9 impborn            ///
    V10 impcit            ///
    V11 implive           ///
    V12 implang           ///
    V13 imprelig          ///
    V14 impresp           ///
    V15 impfeel           ///
                          ///
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
                          ///
    HOMPOP hompop

local n : word count `old_new_varname'
forvalues i = 1 (2) `n' {
   local   old_varname : word `i' of `old_new_varname'
   local   j = `i' + 1
   local   new_varname : word `j' of `old_new_varname'
   di      "Renaming `old_varname' ... `new_varname'"
   rename  `old_varname' `new_varname'
}

rename NL_PRTY  prty_13_NL
rename NL_INC   inchs_13_NL
rename NL_ETHN1 ethn1_13_NL


//  #3
//  RELABEL VARIABLES  //////////////////////////////////////////////////////

//  #3.1 - Relabel Cross-National Variables
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

//  #3.2 - Relabel Country-Specific Variables
label var ethn1_13_NL   "Ethnic group I 13 (NL)"
label var inchs_13_NL   "Household income 13 (NL)"
label var prty_13_NL    "Party affiliation 13 (NL)"


//  #4
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


//  #5
//  RECODE AND RELABEL: DEMOGRAPHIC VARIABLES  //////////////////////////////

//  #5.1 - EDLVL
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

//  #5.2 - WRKSTAT
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

//  #5.3 - MARITAL
label define maritalV2 1 MarriedCivPartnrshp  2 Widowed    ///
                       3 DivorcdLegSepartd    4 Separated  ///
                       5 NvrMarriedSingle
clonevar maritalV2 = marital
notes maritalV2: Recoded clone of renamed source variable marital; ///
                 Married/civ. partnership categories collapsed (1) \ `tag'
recode maritalV2 (1 2 = 1) (5 = 2) (4 = 3) (3 = 4) (6 = 5) ///
                 (9 = .)
label values maritalV2 maritalV2

//  #5.4 - RECODE TO DUMMY VARIABLES: SEX, WRKSUP, UNION
label define Lyesno 0 No 1 Yes

* (Loops used to enable easier comparisons with other ISSP wave cleaning code.)
local var_in        wrksup
local var_out       wrksupI
#delimit ;
local new_varlabel `" "Supervises someone at work" "' ;
local note_det     `" "supervises someone at work" "' ;
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
recode   femaleI (1 = 0) (2 = 1)
label var femaleI "Sex is female"
notes    femaleI : Dummy-coded clone of renamed source variable sex ///
        (1 = "female") \ `tag'
label values femaleI Lyesno

//  #5.5 - REVISE VALUE LABELS: URBRURAL, SSS10
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


//  #6
//  RECODE MISSING VALUES: ETHNIC, INCOMEHS  ////////////////////////////////

//  #6.1 - ETHNIC
local ethn_vars ethn1_13_NL
foreach v of varlist `ethn_vars' {
    clonevar `v'_V2 = `v'
    notes `v'_V2: Recoded clone of renamed source variable `v'; ///
                  missing value categories recoded \ `tag'
    local vallab : value label `v'
    label copy `vallab' `v'_V2
    recode `v'_V2 (0     = .) ///
                  (97 99 = .) ///
                  (98    = .)
    label values `v'_V2 `v'_V2
}

//  #6.2 - INCOMEHS
local inchs_vars inchs_13_NL
foreach v of varlist `inchs_vars' {
    clonevar `v'_V2 = `v'
    notes `v'_V2: Recoded clone of renamed source variable `v'; ///
                  missing value categories recoded \ `tag'
    local vallab : value label `v'
    label copy `vallab' `v'_V2
    recode `v'_V2 (999990 9999990 99999990 99999992  = .)  ///
                  (99999999 999997 9999997 999999 9999999 100000000 = .)  ///
                  (999998 9999998 = .)
    label values `v'_V2 `v'_V2
}


//  #7
//  RECODE COUNTRY VARIABLE  ////////////////////////////////////////////////

     /* Note: NL sample already includes ISO3N country code for the
     Netherlands. Only value label must be applied additionally. */

clonevar countryV3 = country
notes countryV3: Clone of renamed source variable country \ `tag'
label define countryV3 203 CzechRep       554 NewZealand    ///
                       703 Slovakia       826 UK            ///
                       840 USA            410 SKorea        ///
                       710 SAfrica        528 Netherlands
label value countryV3 countryV3


//  #8
//  DROP UNNECESSARY VARIABLES & RE-ORDER ///////////////////////////////////
#delimit ;
order countryV3 id
      age femaleI
      edlvlV2 edlvlV3 hompop
      unemployedI wrkstatV2 wrksupI unionI maritalV2
      urbruralV2
      sss10V2
      impbornP-imprespP
      weight
      ethn1_13_NL_V2
      inchs_13_NL_V2
      prty_13_NL VOTE_LE
      DATEYR ;
#delimit cr

keep countryV3-DATEYR


//  #9
//  SAVE NEW DATA SET  //////////////////////////////////////////////////////
gen       wave = 3
order     wave
label var wave   "ISSP National Identity Survey Module Wave"
notes     wave : Uniquely identifies ISSP national identity survey module ///
                 wave (1-3) \ `tag'

label data "Cleaned ISSP 13 NL data \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-04-issp13NL-cleaned.dta, replace


log close
exit
