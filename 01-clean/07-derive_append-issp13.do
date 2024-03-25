capture log close
log using 01-clean/_logs/07-derive_append-issp13, replace text


//  Program:    07-append_derive-issp13.do
//  Task:       Append ISSP 13 and ISSP 13NL data, generate derived variables.
//
//  Input:      x-03-issp13-cleaned.dta
//              x-04-issp13NL-cleaned.dta
//
//  Output:     x-07-issp13-derived.dta
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
local tag    "07-append_derive-issp13.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/output/_temp/x-03-issp13-cleaned.dta, clear
datasignature confirm
notes _dta


//  #2
//  APPEND ISSP 13 DUTCH SAMPLE  ////////////////////////////////////////////
append using data/output/_temp/x-04-issp13NL-cleaned.dta, nonotes


//  #3
//  GENERATE HOUSEHOLD SIZE ADJUSTED INCOME VARIABLE  ///////////////////////
local inchs_all inchs_13_BE_V2 inchs_13_CH_V2 inchs_13_CZ_V2 inchs_13_DE_V2 ///
                inchs_13_DK_V2 inchs_13_EE_V2 inchs_13_ES_V2 inchs_13_FI_V2 ///
                inchs_13_FR_V2 inchs_13_GB_V2 inchs_13_GE_V2 inchs_13_HR_V2 ///
                inchs_13_HU_V2 inchs_13_IE_V2 inchs_13_IL_V2 inchs_13_IN_V2 ///
                inchs_13_IS_V2 inchs_13_JP_V2 inchs_13_KR_V2 inchs_13_LT_V2 ///
                inchs_13_LV_V2 inchs_13_MX_V2 inchs_13_NO_V2 inchs_13_PH_V2 ///
                inchs_13_PT_V2 inchs_13_RU_V2 inchs_13_SE_V2 inchs_13_SI_V2 ///
                inchs_13_SK_V2 inchs_13_TR_V2 inchs_13_TW_V2 inchs_13_US_V2 ///
                inchs_13_ZA_V2 inchs_13_NL_V2

gen incomehs_adj = .
label var incomehs_adj "Household income (adjusted for size)"
notes     incomehs_adj: Household income, adjusted for household size;    ///
                        equals incomehs divided by square root of nr. of  ///
                        persons living in household (hompop) \ `tag'

foreach c of local inchs_all {
    gen incadj_`c' = `c' / sqrt(hompop)
    replace incomehs_adj = incadj_`c' if !missing(incadj_`c')
    drop incadj_`c'
}


//  #4
//  GENERATE INCOME QUINTILE VARIABLE    (Unadjusted Household Income)  ///////
gen incquin = .
label var incquin "Household income (quintiles, unadjusted)"
notes incquin: Country-specific household income recoded into quintiles \ `tag'

foreach c of local inchs_all {
    xtile X_incquin`c' = `c' [pw=weight],  nquantiles(5)
    replace incquin = X_incquin`c' if !missing(`c')
    drop X_incquin`c'
}


//  #5
//  GENERATE INCOME QUINTILE VARIABLE    (Adjusted Household Income)  /////////
clonevar incquinV2 = incomehs_adj
recode incquinV2 (* = .)
label var incquinV2 "Household income (quintiles, adjusted for size)"
notes incquinV2: Clone of incomehs_adj recoded into quintiles \ `tag'

levelsof countryV3, local(cntrys)
foreach c of local cntrys {
    xtile X_incquinV2`c' = incomehs_adj if countryV3 == `c' [pw=weight],  nquantiles(5)
    replace incquinV2 = X_incquinV2`c' if countryV3 == `c' & !missing(incomehs_adj)
    drop X_incquinV2`c'
}


//  #6
//  GENERATE INCOME QUINTILE VARIABLE    (Adjusted Income Rank)  //////////////
gen X_inc_predict = .
label var X_inc_predict "PREDICTED household income"

gen incrank = .
label var incrank "Income rank from predicted household income"

clonevar incquinV3 = incomehs_adj
recode incquinV3 (* = .)
label var incquinV3 "Household income (quintiles, adjusted income rank)"
notes incquinV3: Predicted adjusted household income rank recoded into  ///
                quintiles; adjusted household income was predicted from  ///
                a regression model, respondents within same reported   ///
                income category were ranked based on predicted incomes, ///
                and a uniform distribution (0-1) of rank was computed   ///
                based on the resulting rank order \ `tag'

foreach c of local cntrys {
    * Fit regression model:
    qui reg incomehs_adj c.age##c.age i.edlvlV2 femaleI 1.maritalV2 1.wrkstatV2 ///
        if countryV3 == `c' [pw = weight]
    * Predict fitted values per country:
    predict X_inc_predict`c' if countryV3 == `c' & e(sample), xb
    * Use actual income if cannot be predicted (missing predictors):
    replace X_inc_predict`c' = incomehs_adj if missing(X_inc_predict`c') & countryV3 == `c'
    * Merge into cross-national predicted income variable:
    replace X_inc_predict = X_inc_predict`c' if countryV3 == `c' & !missing(incomehs_adj)
    * Generate tag for country sample:
    gen nmiss = 1 if !missing(X_inc_predict`c')
    sort nmiss incomehs_adj X_inc_predict`c'
    * Generate income rank:
    gen incrank`c' = _n if countryV3 == `c' & !missing(incomehs_adj)
    * Divide rank by country N:
    qui sum id    if countryV3 == `c' & !missing(incomehs_adj)
    replace incrank`c' = incrank`c' / r(N)
    replace incrank = incrank`c' if countryV3 == `c' & !missing(incomehs_adj)
    * Generate income rank QUINTILES:
    xtile incquinV3`c' = incrank`c' if countryV3 == `c' & nmiss == 1, nquantiles(5)
    replace incquinV3 = incquinV3`c' if countryV3 == `c' & nmiss == 1
    drop nmiss X_inc_predict`c' incrank`c' incquinV3`c'
}

drop X_inc_predict


//  #7
//  GENERATE ETHNIC MAJORITY MEMBER DUMMY     ///////////////////////////////

      /* Creating single cross-national ethnicity variable is not feasible here
       since country-specific ethnicity variables have completely different
       ethnicity coding schemes (i.e. many identical values referring to
       different groups). */

clonevar ethn1_13_US_V4 = ethn1_13_US_V2
notes    ethn1_13_US_V4: Recoded clone of ethn1_13_US_V2; all W./N.  ///
         European race/ethnicity categories are collapsed for USA, \ `tag'
recode ethn1_13_US_V4 (40 56 203 208 246   250 276 372 442 528  ///
                       578 752 756 826 840    = 151)

label copy ethn1_13_US_V2 ethn1_13_US_V4
label values ethn1_13_US_V4 ethn1_13_US_V4
label define ethn1_13_US_V4 151 WNEuropean, modify

clonevar ethn1_13_PH_V3 = ethn1_13_PH_V2
notes    ethn1_13_PH_V3: Recoded clone of ethn1_13_PH_V2, Philippines country-specific ///
                         ethnicity variable; ethnic groups Tagalog, Cebuano, Ilonggo, ///
                         Ilocano, Bicol, Waray, Pangasinense are grouped together as  ///
                         "Christian lowlanders" (see Ethnic Power Relations Atlas entry for country) \ `tag'
recode ethn1_13_PH_V3 (12 6 5 4 1 31 27 = 200)
label copy ethn1_13_PH_V2 ethn1_13_PH_V3
label values ethn1_13_PH_V3 ethn1_13_PH_V3
label define ethn1_13_PH_V3 200 ChristianLowlanders, modify

generate X_ethmode = .
label variable X_ethmode "Modal ethnic cateogry"
notes X_ethmode: Value of modal ethnic category per each country; generated ///
                 using egen, mode from each country-specific ethnicity var \ `tag'

local ethn_all ethn1_13_BE_V2 ethn1_13_CZ_V2 ethn1_13_DE_V2 ethn1_13_EE_V2 ///
               ethn1_13_ES_V2 ethn1_13_FI_V2 ethn1_13_FR_V2 ethn1_13_GB_V2 ///
               ethn1_13_GE_V2 ethn1_13_HR_V2 ethn1_13_HU_V2 ethn1_13_IE_V2 ///
                                             ethn1_13_IS_V2 ethn1_13_JP_V2 ///
               ethn1_13_KR_V2 ethn1_13_LT_V2 ethn1_13_LV_V2 ethn1_13_MX_V2 ///
               ethn1_13_NO_V2 ethn1_13_PH_V3 ethn1_13_PT_V2 ethn1_13_RU_V2 ///
               ethn1_13_SI_V2 ethn1_13_SK_V2 ethn1_13_TR_V2 ethn1_13_TW_V2 ///
                                             ethn1_13_DK_V2 ethn1_13_US_V4 ///
               ethn1_13_SE_V2 ethn1_13_NL_V2

local counter = 0
foreach v of local ethn_all {
    local ++counter
    qui egen X_ethmode_`counter' = mode(`v') if !missing(`v')
    * Compute modal categories from each country's ethnic variable:
    label values X_ethmode_`counter' `v'
    qui levelsof X_ethmode_`counter', local(val)
    local ethn_lab : label (X_ethmode_`counter') `val'
    * Displays label for country's modal ethnicity category:
    di "Modal Ethnic Category for `v' ... " `" "`ethn_lab'" "'
    replace X_ethmode = X_ethmode_`counter' if !missing(`v')
    drop X_ethmode_`counter'
}

gen ethmajI = .
label variable ethmajI "Is member of majority ethnic/racial group"
note ethmajI: Dummy variable based on X_ethmode ///
              (1 = "is member of majority ethnic/racial group") \ `tag'
label values ethmajI Lyesno

foreach v of local ethn_all {
    recode ethmajI (. = 1) if `v' == X_ethmode & !missing(`v')
    recode ethmajI (. = 0) if `v' != X_ethmode & !missing(`v')
}
drop X_ethmode

recode ethmajI (1 = 0) if countryV3 == 840 & ethn1_13_US_V4 != 151 & !missing(ethn1_13_US_V4)

recode ethmajI (. = 1) if V3 == 37601
recode ethmajI (. = 0) if V3 == 37602
 /* Codes ISRAEL ethmaj based on V3 variable, which separates
    37601 "Israel Jews" and 37602 "Israel Arabs". */
note ethmajI: For Israel sample, dummy variable is based on "Israel Jews" ///
              "Israel Arabs" coding in V3 \ `tag'
drop V3

* Codes India ethnic group "Hindu (Upper caste Hindu)" as ethnic maj group
recode ethmajI (. = 0) if countryV3 == 356 & !missing(ethn1_13_IN_V2)
recode ethmajI (0 = 1) if countryV3 == 356 & ethn1_13_IN_V2 == 4 ///
    & !missing(ethn1_13_IN_V2)

rename ethmajI ethmajIV2


//  #8
//  GENERATE SURVEY YEAR  ///////////////////////////////////////////////////
bysort countryV3: egen X_minyear = min(DATEYR)
  // Generates X_minyear, containing the earliest interview year in R's country.
label var X_minyear "Earliest country interview year"
notes X_minyear: Temp. var containing year that national survey began \ `tag'

generate year = X_minyear
    label variable year "Survey year"
    notes          year: Year in which national survey was conducted; for countries ///
                         whose survey spanned multiple years, the first year is ///
                         recorded here \ `tag'
    notes          year: for ISSP 13 data, year is based on source variable ///
                         DATEYR, which records year of each respondent's ///
                         interview; each country's respondents are all ///
                         assigned the earliest year that any of that country's ///
                         respondents had the survey interview \ `tag'
drop X_minyear


//  #9
//  SAVE DATA  //////////////////////////////////////////////////////////////
drop ethn1_13_BE_V2-inchs_13_ZA_V2 DATEYR-inchs_13_NL ethn1_13_US_V4 ethn1_13_PH_V3

label data "Cleaned ISSP 13 data (NL incl.) with derived variables \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-07-issp13-derived.dta, replace


log close
exit
