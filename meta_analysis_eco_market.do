*Meta-Analysis of Studies on How Market Affects Eco-Innovation*
*Iryna Sauchanka, January 2026
*Econometrics for Decision-Making


/*******************************************/
/*            Setup                        */ 
/*******************************************/

clear
set more off
set matsize 11000
set linesize 255
mata: mata set matafavor speed


*change the path before running

cd ""

*creating the folders
*mkdir "./output"

global outputs "./output/"

/*******************************************/
/*	            Reviewing phase           */ 
/*******************************************/


*loading the dataset

import excel "Prep_Work-Meta analysis_04-06-25.xlsx", ///
    sheet("Sample studies_Coding variables") ///
    cellrange(A2:AR894) firstrow clear

save "meta_raw.dta", replace

use "meta_raw.dta", clear

descr

/*******************************************/
/*	     Rename variables (the cleanup)   */ 
/*******************************************/
capture rename Coefficient* beta 
capture rename MarginalEffect* m_eff
capture rename Standarderror* se
capture rename Numberof* n
capture rename pvalue p_value 

capture rename Tvalues* t_stat
capture rename Ztest* z_stat

capture rename Sourcenumbering study_id

*check the names are correct
describe beta m_eff se n p_value t_stat z_stat

/*******************************************/
/*	 Theoretical Screening and Study Selection  */ 
/*******************************************/

*screening out the papers that don't study the market forces impact on eco-innovation
gen to_exclude = 0

*list is created based on the personal evaluation of the content of any paper in the dataset
replace to_exclude = 1 if inlist(study_id, 3, 4, 8, 12, 14, 17, 18, 19, 20, 23, 32, 33, 34, 39, 40)

*check how many rows are about to be dropped
tab to_exclude

drop if to_exclude == 1
drop to_exclude

save "meta_market_only.dta", replace

/*******************************************/
/*    Screening the Market-Force Variables        */ 
/*******************************************/

*use "meta_market_only.dta", clear

*create the list of unique variables' descriptions

*preserve
*keep Variabledescr~s
*contract Variabledescr~s
*drop _freq

*export for manual tagging
*export excel using "variable_mapping.xlsx", firstrow(variables) replace
*restore

*evaluate every variable's description and put 1 in the "is_market" if it aligns with the definition of "market forces" used in the meta-analysis. out "0" if variable doesn't measure market influence

*for studies that use Structural Equation Modeling (SEM) pick only one variable (dummy) not to create redundancy 

*for study #6 that reports the same regression but for two different countries keep coefficients for both 

*save Excel and use "is_market" to select only market variables

import excel "variable_mapping.xlsx", firstrow clear
save "variable_mapping.dta", replace

use "meta_market_only.dta", clear
merge m:1 Variabledescr~s using "variable_mapping.dta"

tab _merge

list Variabledescr~s if _merge == 1
keep if _merge == 3 & is_market == 1
drop _merge

count
tab study_id
tab Variabledescr~s

save "meta_market_screened.dta", replace


/******************************************/
/*   Data Cleaning and Format Adjusting   */ 
/*****************************************/

use "meta_market_screened.dta", clear

foreach var in beta se m_eff {
    *if a cell contains both coefficient and the standard error in brackets, extract only the coefficent.
        
    gen `var'_clean = ustrregexs(0) if ustrregexm(`var', "[-–−]?[0-9]*[\.,][0-9]+")

    *if previous failed/missed some data format, this is the backup
    replace `var'_clean = `var' if missing(`var'_clean)

    *need to adjust formatting: minus, dot/coma
    replace `var'_clean = ustrregexra(`var'_clean, "[\u2013\u2014\u2212]", "-")
    replace `var'_clean = subinstr(`var'_clean, ",", ".", .)
    
	replace `var' = `var'_clean
    drop `var'_clean
    destring `var', replace force

    *fix the typo for huge coefficients (such as 1,639)
    replace `var' = `var' / 1000 if abs(`var') > 10 & abs(`var') < 10000
}

*drop only the close-to-impossible values (study #27 reports odds ratio in a case of perfect separation, which might create bias if included in meta-analysis)

drop if abs(beta) > 10 & !missing(beta)

*fix the format of other columns
capture destring t_stat, replace force
capture destring z_stat, replace force

capture destring n, replace force

capture destring p_value, replace force 

save "meta_market_clean.dta", replace

*to inspect what we got
*browse study_id beta m_eff se t_stat z_stat p_value 


/*******************************************/
/*	     Statistical Screening (data availability)   */ 
/*******************************************/

*check whether the selected variables have statistics needed to compute the effect sizes

use "meta_market_clean.dta", clear

*prepare one column combining marginal effects and betas
gen estimate_final = beta
replace estimate_final = m_eff if missing(estimate_final)

*prepare one column for t-statistic reported from the paper
gen t_reported = .

replace t_reported = t_stat if !missing(t_stat)
replace t_reported = z_stat if !missing(z_stat)

*inclusion criterion
*keep the row if we have the estimate AND (se or t-stat or p-value)
gen has_stats = 0

replace has_stats = 1 if !missing(estimate_final) & !missing(se)
replace has_stats = 1 if !missing(estimate_final) & !missing(t_reported)
replace has_stats = 1 if !missing(estimate_final) & !missing(p_value)

*drop those variables that don't have statistics
drop if has_stats == 0
drop has_stats

count
codebook study_id, compact
*show that we have 66 observations from 22 papers

tab study_id
save "meta_calc.dta", replace

/*******************************************/
/*	           Computing the effect size        */ 
/*******************************************/
use "meta_calc.dta", clear

*obtain t-statistic from different sources: calculate from standard errors, take reported one from paper, calculate from p-value
gen t_calc = estimate_final / se

gen t_final = t_calc
replace t_final = t_reported if missing(t_final) & !missing(t_reported)

gen t_from_p = .
replace t_from_p = invt(n-2, 1 - p_value / 2) * sign(estimate_final) if !missing(p_value) & !missing(n)

replace t_final = t_from_p if missing(t_final) & !missing(t_from_p)

*calculate degrees of freedom using approximation
generate df = n - 2 

*compute partial correlation
generate pcc = t_final / sqrt(t_final^2 + df)

*safety check as pcc shouldn't be bigger 1 and smaller -1
tab pcc

*use the Stata function to produce the effect size and its variance
generate fisher_z = atanh(pcc)
generate var_z = 1 / (n - 3)
generate se_z = sqrt(var_z)

*label
label variable t_final "Final T-Statistic (Calculated or Reported)"
label variable pcc "Partial Correlation Coefficient"
label variable fisher_z "Fisher's Z (Final Effect Size)"
label variable var_z "Variance of Fisher's Z"

save "meta_analysis_ready.dta", replace

*see the results 
browse study_id estimate_final se t_final pcc fisher_z var_z

/******************************************************/
/*	           Multi-Level Random-Effects Model       */ 
/******************************************************/

*as we have multiple effect sizes per paper that are correlated we need to use multilevel random effects model

use "meta_analysis_ready.dta", clear
meta set fisher_z se_z, studylabel(study_id)

meta multilevel fisher_z, relevels(study_id) essevariable(se_z) nolog

/***********************************************/
/*	     Prediction interval by Rule if Thumb   */ 
/**********************************************/
scalar mean_effect = _b[_cons]              
scalar tau         = exp(_b[lns1_1_1:_cons]) 

scalar pi_lower = mean_effect - (2 * tau)
scalar pi_upper= mean_effect + (2 * tau)

display "LOWER BOUND:   " pi_lower
display "UPPER BOUND:   " pi_upper 

/***********************************************/
/*	           Estimating Heterogeneity       */ 
/**********************************************/

estat heterogeneity

*Basic Forest Plot
*meta forestplot, sort(study_id) nullrefline


/***********************************************/
/*	           Subgroup Analysis: region     */ 
/**********************************************/

use "meta_analysis_ready.dta", clear
meta set fisher_z se_z, studylabel(study_id)

encode Area, gen(area_cat)
tab area_cat

*creating fewer categories not to have a categiry with only 1 or 2 studies
capture decode area_cat, gen(region_str)
replace region_str = "Europe" if region_str == "EU and Non-EU"
replace region_str = "Asia" if region_str == "East Asia "
replace region_str = "Americas" if region_str == "North-America"
replace region_str = "Americas" if region_str == "South-America"

encode region_str, gen(region_final)
tab region_final

meta multilevel fisher_z ib(freq).region_final, relevels(study_id) essevariable(se_z) nolog

*test significance 
testparm i.region_final

/***********************************************/
/*	           Subgroup Analysis: sector     */ 
/**********************************************/

use "meta_analysis_ready.dta", clear
meta set fisher_z se_z, studylabel(study_id)

encode Sector, gen(sector_cat)

tab sector_cat
capture decode sector_cat, gen(sector_str)

gen sector_final = ""

*group 1: studies mainly on heavy industries (manufacturing, inductrial)
replace sector_final = "Manufacturing" if strpos(sector_str, "Industrial")
replace sector_final = "Manufacturing" if strpos(sector_str, "Manufacturing")
replace sector_final = "Manufacturing" if strpos(sector_str, "Manufacturing ")
replace sector_final = "Manufacturing" if strpos(sector_str, "Construction")

*group 2: studies on mixed sectors or the whole economy
replace sector_final = "Mixed" if strpos(sector_str, "Service") 
replace sector_final = "Mixed" if strpos(sector_str, "Agriculture")
replace sector_final = "Mixed" if strpos(sector_str, "cross-sectoral")
replace sector_final = "Mixed" if strpos(sector_str, "all")

*create the group 2 after the 1st so it will be overwritten if the study is conducted on mixed sectors

tab sector_final
encode sector_final, gen(sector_encoded)

meta multilevel fisher_z i.sector_encoded, relevels(study_id) essevariable(se_z) nolog

/***********************************************/
/*	           Publication Bias     */ 
/**********************************************/
meta funnelplot, metric(se)
graph export "${outputs}Figure_Publication.png", as(png) width(3000) replace

*statistical Test (Egger's Test)
meta bias, egger