

//  Program:    00-run_all.do
//  Task:       Run all `01-clean` data cleaning scripts.
//
//  Project:    boundary-consolidation
//  Author:     Martin Lukk / 2023-11-03 (last updated)


* NOTE: Insert project directory file path between quotes
local path ""

* Set working directory
cd "`path'"

* Install necessary user-created commands
ssc install kountry
ssc install labutil

* Clean data in each ISSP survey wave
do 01-clean/01-clean-issp95.do
do 01-clean/02-clean-issp03.do
do 01-clean/03-clean-issp13.do
do 01-clean/04-clean-issp13NL.do

* Generate derived variables in each ISSP survey wave
do 01-clean/05-derive-issp95.do
do 01-clean/06-derive-issp03.do
do 01-clean/07-derive_append-issp13.do

* Append ISSP survey waves into single data set
do 01-clean/08-append-issp.do

* Merge country-level control variables
do 01-clean/09-merge-controls.do

* Drop countries missing key variables and unused variables
do 01-clean/10-subset1-issp_ctrls_ethnat.do
do 01-clean/11-subset2-issp_ctrls_voting.do
