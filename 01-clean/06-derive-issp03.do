capture log close
log using 01-clean/_logs/06-derive-issp03, replace text


//  Program:    06-derive-issp03.do
//  Task:       Generate derived variables with ISSP 03 data.
//
//  Input:      x-02-issp03-cleaned.dta
//  Output:     x-06-issp03-derived.dta
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
local tag    "06-derive-issp03.do ml `date'"


//  #1
//  LOAD DATA  //////////////////////////////////////////////////////////////
use data/output/_temp/x-02-issp03-cleaned.dta, clear
datasignature confirm
notes _dta


//  #2
//  GENERATE HOUSEHOLD SIZE ADJUSTED INCOME VARIABLE  ///////////////////////
gen incomehs_adj = incomehsV2 / sqrt(hompop)
label var incomehs_adj "Household income (adjusted for size)"
notes     incomehs_adj: Household income, adjusted for household size;    ///
                        equals incomehs divided by square root of nr. of  ///
                        persons living in household (hompop) \ `tag'


//  #3
//  GENERATE INCOME QUINTILE VARIABLE V1 (Unadjusted Household Income)  ///////
clonevar incquin = incomehsV2
recode incquin (* = .)
label var incquin "Household income (quintiles, unadjusted)"
notes incquin: Clone of incomehsV2 recoded into quintiles \ `tag'

levelsof countryV3, local(cntrys)
foreach c of local cntrys {
    xtile X_incquin`c' = incomehsV2 if countryV3 == `c' [pw=weight],  nquantiles(5)
    replace incquin = X_incquin`c' if countryV3 == `c' & !missing(incomehsV2)
    drop X_incquin`c'
}


//  #4
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


//  #5
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


//  #6
//  GENERATE ETHNIC MAJORITY MEMBER DUMMY     ///////////////////////////////
clonevar ethnicV3 = ethnic
notes    ethnicV3: Recoded clone of ethnic; all W. European race/ethnicity ///
                 categories are collapsed for 124_Canada \ `tag'
recode ethnicV3 (39 46 49 111 984 = 151) if countryV3 == 124

label copy ethnicV2 ethnicV3
label values ethnicV3 ethnicV3
label define ethnicV3 151 WEuropean, modify

recode ethnicV3 (3 18 57 58 99 100 133 134 = 152) if countryV3 == 608
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

recode ethmajIV2 (. = 1) if country == 22
recode ethmajIV2 (. = 0) if country == 23
  /* Codes ISRAEL ethmajIV2 based on country variable, which separates
     22 "Israel Jews" and 23 "Israel Arabs". */
note ethmajIV2: For Israel sample, dummy variable is based on "Israel Jews" ///
              "Israel Arabs" coding in country \ `tag'
drop country


//  #7
//  GENERATE SURVEY YEAR  ///////////////////////////////////////////////////
generate year = .
    label variable year "Survey year"
    notes          year: Year in which national survey was conducted; for countries ///
                         whose survey spanned multiple years, the first year is ///
                         recorded here \ `tag'
    notes          year: for ISSP 03 data, year is based on information in ///
                         survey codebook; each country's respondents are all ///
                         assigned the earliest year that any of that country's ///
                         respondents had the survey interview \ `tag'
    recode year (. = 2002) if inlist(countryV3,    756                    )
    recode year (. = 2003) if inlist(countryV3,    36,  826, 348, 372, 578,  ///
                                                   752, 203, 705, 100, 643,  ///
                                                   554, 608, 376, 392, 724,  ///
                                                   428, 250, 152, 208, 246,  ///
                                                   710, 158, 410          )
    recode year (. = 2004) if inlist(countryV3,    276, 840, 40,  528, 124,  ///
                                                   703, 620, 862, 858     )
    recode year (. = 2005) if inlist(countryV3,    616                    )


//  #8
//  SAVE DATA  //////////////////////////////////////////////////////////////
label data "Cleaned ISSP 03 data with derived variables \ `date'"
compress
datasignature set, reset
save data/output/_temp/x-06-issp03-derived.dta, replace


log close
exit
