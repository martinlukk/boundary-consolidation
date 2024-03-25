capture log close
log using 01-clean/_logs/05-derive-issp95, replace text


//  Program:    05-derive-issp95.do
//  Task:       Generate derived variables with ISSP 95 data.
//
//  Input:      x-01-issp95-cleaned.dta
//  Output:     x-05-issp95-derived.dta
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
local tag    "05-derive-issp95.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/output/_temp/x-01-issp95-cleaned.dta, clear
datasignature confirm
notes _dta


//  #2
//  RECODE SSS6 INTO SSS10 (Harmonized 10-cat variable)  ////////////////////

     /* Note: Subjective social status (SSS) is asked on a 6-point scale in
     ISSP 95 and on a 10-point scale in later waves. This section recodes
     the 6-point SSS variables into a 10-point variable for comparisons with
     later waves. */

     /* Recoding is consistent with the derivation of sss10 based on 6-point
     survey questions in ISSP 03. There, the responses for Canada are derived
     from 1 "The lower class", 2 "The working class", 3 "Upper working class/
     lower middle class", 4 "Middle class", 5 "Upper Middle Class", and 6 "Upper
     Class". This recoding scheme is applied below to all ISSP 95 responses. */

clonevar sss10V2 = sss6
    recode sss10V2 (1 = 1) (2 = 3) (3 = 5) (4 = 6) (5 = 7) (6 = 9)
    label var sss10V2 "Subjective social status, 1-10"
    notes sss10V2: Recoded clone of sss6; 6-point scale is recoded into a 10-point ///
                   scale following a derivation scheme found in the ISSP 03 data; ///
                   this is done to harmonize the ISSP 95 SSS question with later ///
                   ISSP waves \ `tag'


//  #3
//  GENERATE HOUSEHOLD SIZE ADJUSTED INCOME VARIABLE  ///////////////////////
gen incomehs_adj = incomehs / sqrt(hompop)
label var incomehs_adj "Household income (adjusted for size)"
notes     incomehs_adj: Household income, adjusted for household size;    ///
                        equals incomehs divided by square root of nr. of  ///
                        persons living in household (hompop) \ `tag'


//  #4
//  GENERATE INCOME QUINTILE VARIABLE V1 (Unadjusted Household Income)  ///////

clonevar incquin = incomehs
recode incquin (* = .)
label var incquin "Household income (quintiles, unadjusted)"
notes incquin: Clone of incomehs recoded into quintiles \ `tag'

egen X_incomehs_allmiss = min(incomehs == .), by(countryV3)
label var X_incomehs_allmiss "Temp. tag: incomehs is missing for entire country"
notes     X_incomehs_allmiss: Tag var for cases whose country is missing incomehs data \ `tag'

levelsof countryV3 if X_incomehs_allmiss == 0, local(cntrys)
drop X_incomehs_allmiss

foreach c of local cntrys {
    xtile X_incquin`c' = incomehs if countryV3 == `c' [pw=weight],  nquantiles(5)
    replace incquin = X_incquin`c' if countryV3 == `c' & !missing(incomehs)
    drop X_incquin`c'
}


//  #5
//  GENERATE INCOME QUINTILE VARIABLE V2 (Adjusted Household Income)  /////////

clonevar incquinV2 = incomehs_adj
recode incquinV2 (* = .)
label var incquinV2 "Household income (quintiles, adjusted for size)"
notes incquinV2: Clone of incomehs_adj recoded into quintiles \ `tag'

egen X_incomehs_adj_allmiss = min(incomehs_adj == .), by(countryV3)
label var X_incomehs_adj_allmiss "Temp. tag: incomehs_adj is missing for entire country"
notes     X_incomehs_adj_allmiss: Tag var for cases whose country is missing incomehs_adj data \ `tag'
levelsof countryV3 if X_incomehs_adj_allmiss == 0, local(cntrys)
drop X_incomehs_adj_allmiss

foreach c of local cntrys {
    xtile X_incquinV2`c' = incomehs_adj if countryV3 == `c' [pw=weight],  nquantiles(5)
    replace incquinV2 = X_incquinV2`c' if countryV3 == `c' & !missing(incomehs_adj)
    drop X_incquinV2`c'
}


//  #6
//  GENERATE INCOME QUINTILE VARIABLE V3 (Adjusted Income Rank)  //////////////
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


//  #8
//  GENERATE ETHNIC MAJORITY MEMBER DUMMY V2  ///////////////////////////////
clonevar ethnicV3 = ethnic
notes    ethnicV3: Recoded clone of ethnic; all W. and N. European ///
                   race/ethnicity categories are collapsed for 124_Canada and 840_USA \ `tag'
recode ethnicV3 (31 35 38 48 58   76 = 151) if countryV3 == 124
recode ethnicV3 (10 14 30 31 32   34 35 38 48 58   61 76 82 83 = 151) ///
                if countryV3 == 840

label copy  V65 ethnicV3
label values ethnicV3 ethnicV3
label define ethnicV3 151 WNEuropean, modify

recode ethnicV3 (66 91 44 43 16 92 64 2 = 152) if countryV3 == 608
notes  ethnicV3: Philippines ethnic groups Tagalog, Cebuano, Ilonggo, ///
                 Ilocano, Bicol, Waray, Pangasinan, Aklan are grouped ///
                 together as "Christian lowlanders" (see Ethnic Power Relations Atlas entry for country) \ `tag'
label define ethnicV3 152 ChristianLowlanders, modify

bysort countryV3: egen X_ethmodeV2 = mode(ethnicV3)
 /* Generates variable X_ethmodeV2, containing the identity of the modal ethnicV3
    category for the respondent's country. */
label values X_ethmodeV2 ethnicV3


gen ethmajIV2  = .
label variable ethmajIV2 "Is member of majority ethnic/racial group"
note ethmajIV2: Dummy variable based on ethnicV3 and X_ethmodeV2 ///
             (1 = "is member of majority ethnic/racial group") \ `tag'
label values ethmajIV2 Lyesno

recode ethmajIV2 (. = 1) if ethnicV3 == X_ethmodeV2 & !missing(ethnicV3)
recode ethmajIV2 (. = 0) if ethnicV3 != X_ethmodeV2 & !missing(ethnicV3)
drop X_ethmodeV2


//  #9
//  GENERATE SURVEY YEAR  ///////////////////////////////////////////////////
generate year = .
    label variable year "Survey year"
    notes          year: Year in which national survey was conducted; for countries ///
                         whose survey spanned multiple years, the first year is ///
                         recorded here \ `tag'
    notes          year: For ISSP 95 data, year is based on information in ///
                         survey codebook; each country's respondents are all ///
                         assigned the earliest year that any of that country's ///
                         respondents had the survey interview \ `tag'
    recode year (. = 1994) if inlist(countryV3,    705                    )
    recode year (. = 1995) if inlist(countryV3,    40,  826, 276, 372, 348,  ///
                                                   380, 528, 578, 752, 203,  ///
                                                   616, 100, 124, 608, 392,  ///
                                                   724, 428               )
    recode year (. = 1996) if inlist(countryV3,    36,  840, 643, 554, 703)


//  #10
//  SAVE DATA  //////////////////////////////////////////////////////////////
drop inchs_95_A-inchs_95_USA

label data "Cleaned ISSP 95 data with derived variables \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-05-issp95-derived.dta, replace

log close
exit
