/*=============================================================================* 
* DATA Analysis - EBB Sample & Polis
*==============================================================================*
 	Project: Occupations & Careers within Organizations
	Author: Christoph Janietz (University of Groningen)
	Last update: 17-03-2024
	
	Purpose: Data preparation & data analysis (Organizations with n>=10).
	
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings 
		1. 	Setup sample
		2.  Analysis including smaller organizations
		3.  Close Log File
			
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art4"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"$logfiles/02_analysis_org10.log", replace

	
* --------------------------------------------------------------------------- */
* 1. SETUP SAMPLE
* ---------------------------------------------------------------------------- *
	
	
**********************************************************
*** Initial Merge (Determine Organization of Focus) 
**********************************************************	

* Merge on YEAR and RIN. This will identify pers-org combis existing in that caly.
* --> Drop Org if survey date is outside of interview time.
* --> Then keep the org per pers with the most hours worked
* --> Then drop all org at N_org<10
	
	use "${data}/SPOLIS_core.dta", replace
	
	* Match
	merge m:1  YEAR rinpersoons rinpersoon using "${data}/EBB_core", ///
		keep(match) nogen
		
	*Step 1: Drop if Survey outside range
	keep if SURVEY_YMD>=job_start_caly_beid & SURVEY_YMD<=job_end_caly_beid	
	
	*Step 2: Select remaining main jobs based on max nr of hours worked
	duplicates tag YEAR rinpersoons rinpersoon, gen(dupl)
	bys YEAR rinpersoons rinpersoon: egen max_hours = max(sbasisuren_caly_beid)
	drop if sbasisuren_caly_beid!=max_hours & dupl!=0
	// 388 Duplicates remain (same number of hours at two different orgs)
	egen select = tag(YEAR rinpersoons rinpersoon)
	keep if select==1
	drop dupl max_hours select
	
	///////////////////////////////
	*Step 3: Drop if Orga size <10
	///////////////////////////////
	drop if N_org<10
	
	sort rinpersoons rinpersoon sbeid

	save "${data}/SAMPLE_init10.dta", replace
	
**********************************************************
*** Second Merge (Match on identified Pers-Org combinations)
**********************************************************

* Merge on RIN and SBEID. This will identify pers-org combis deemed as focus
* --> Keep only exact matches. EBB variables will be continiously filled with 
* the init observation.
	
	use "${data}/SPOLIS_core.dta", replace
	
	* Merge
	merge m:1 rinpersoons rinpersoon sbeid using "${data}/SAMPLE_init10", ///
		keep(match) nogen
		
	sort rinpersoons rinpersoon sbeid YEAR
	
	* Drop variables that are not needed anymore 
	drop job_start_caly_beid job_end_caly_beid sbasisuren_caly_beid ebbafljaar ///
		ebbaflkwartaal PUB_YQ
		
	* Create counter variable
	gen counter = YEAR-SURVEY_Y
	
	* Adjust the time-varying variables tenure_m tenure_y (right now fixed at start)
	replace tenure_m = tenure_m + 12*(counter) if tenure_m!=.
	replace tenure_y = tenure_y + (counter) if tenure_y!=.
	
	* Make jobtype time-constant
	bys RIN: replace jobtype_PLS=jobtype_PLS[_n-1] if counter>0 & counter!=.
	
	// Split jobtype
	tab jobtype_PLS, gen (jt)
	drop jt1
	rename (jt2 jt3) (tempagency oncall)
	order tempagency oncall, after(jobtype_PLS)
	
	// Occupation variables
	* ISCO Major group
	iscogen isco1 = major(ISCO)
	iscogen isco3 = minor(ISCO)

	* Class schemes
	iscogen oesch16 = oesch(ISCO)
	iscogen oesch = oesch8(ISCO)
	
	recode oesch (3=1) (5=2) (7=3) (4=4) (6=5) (8=6)
	lab def oesch_lbl 1 "Technical (semi-)professionals" 2 "(Associate) Managers" ///
		3 "Socio-cultural (semi-)professionals" 4 "Production workers" ///
		5 "Office workers" 6 "Service workers"
	lab var oesch "Class scheme: Oesch"
	lab val oesch oesch_lbl
	
	// Education 
	gen ed = ISCED_lvl
	recode ed (0 1 2 = 1) (3 4 5 = 2) (6 7 8 = 3) 
	lab def ed_lbl 1 "ISCED 0-2" 2 "ISCED 3-5" 3 "ISCED 6-8" 
	lab var ed "Highest Attained Education"
	lab val ed ed_lbl
	
	// Rescale weights (all survey weights of a specific year sum up to 1)
	bys SURVEY_Y: egen sum_svyw = sum(EBBGEWJAARGEWICHTP1A)
	gen svyw = (EBBGEWJAARGEWICHTP1A/sum_svyw) if counter==0
	sort RIN YEAR
	bys RIN: replace svyw = svyw[_n-1] if counter!=0 & svyw==.
	
	* Order variables 
	order RIN-EBBGEWJAARGEWICHTP1A, after(rinpersoon)
	order svyw, after(EBBGEWJAARGEWICHTP1A)
	order N_org, after(sbeid)
	order gender-ISCED_fld, after(gemhvjjjj)
	order isco1-oesch, after(ISCO)
	order ed, after(ISCED_lvl)
	order counter, after(gemhvjjjj)
	order tenure_m tenure_y age, after(counter)
	
	* Set relational wage measure as missing if N_org<20 in that yearly
	* 21,178 cases (years in which an orga is below 20 despite being at least 20
	* in the EBB observation year)
	replace log_real_hwage_ORG=. if N_org<10
	
	sort rinpersoons rinpersoon YEAR
	
	save "${posted}/analysis10", replace
	
**********************************************************
*** AKM model 
**********************************************************
	
	*Merge org-level variables to Analyis File
	use "${posted}/analysis10", replace
	
	merge m:1 sbeid using "${posted}/j_fe.dta", keepusing(j_fe firmqual) nogen
	order j_fe firmqual, after(sbeid)
	drop if counter==.
	sort rinpersoons rinpersoon YEAR
	
	save "${posted}/analysis10", replace
	
**********************************************************
*** Final sample preparation
**********************************************************
	
	use "${posted}/analysis10", replace
	
	sort rinpersoons rinpersoon YEAR
	
	* Drop observations before EBB survey and 8+ years after EBB survey
	drop if counter<0 | counter>6
	
	* Fill inbetween missings time-constant variables
	* Industry
	by rinpersoons rinpersoon: replace industry=industry[_n-1] if industry==.
	
	// Sample Cuts
	* Drop workers with unidentified occupation code
	drop if ISCO==.
	* -> 297,280 remaining of 301,368
	* Drop missing observations in Oesch classification
	drop if oesch==.
	* -> 297,162 remaining of 301,368
	* Drop workers with unknown tenure
	drop if tenure_y==.
	* -> 287,054 remaining of 301,368
	* Drop workers with unknown education
	drop if ed==.
	* -> 285,819 remaining of 301,368
	* Drop workers with missing wage
	drop if hwage==.
	* -> 285,818 remaining of 301,368
	
	* Truncate trajectories after a gap of at least two years
	* (I treat these instances as the end of an employment relationship)
	bys RIN: gen n = _n-1
	gen x = n-counter
	
	drop if x<=-2
	
	drop n x
	
	// Set Panel
	egen id = group(RIN)
	order id, after(RIN)
	xtset id counter
	
* --------------------------------------------------------------------------- */
* 2. ANALYSIS INCLUDING SMALLER ORGANIZATIONS
* ---------------------------------------------------------------------------- *

	* Estimates the fixed effects growth curve models as in the main analysis but
	* with an expanded set of organizations (N>=10)

	preserve
	
	foreach y of var log_real_hwage_ORG log_real_hwage_ALL log_real_hwage ///
	log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/org10/growth_`y'_fe", sheet("Growth Margins") replace
	putexcel A1 = ("oesch") B1 = ("counter") C1 = ("growth") D1 = ("lb") ///
		E1 = ("ub") F1 = ("model") G1 = ("outcome") H1 = ("Growth"), colwise
		
	* Models
	// Baseline
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.YEAR [aw=svyw], fe vce(cluster id)
		
		local row=2
		foreach x of num 0/6 {
			lincom (_b[counter]*(`x'))+(_b[c.counter#c.counter]*(`x'*`x'))
			putexcel A`row' = 1
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Baseline")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		
		foreach class of num 2/6 {
		foreach x of num 0/6 {
			lincom ((_b[counter]+_b[`class'.oesch#c.counter])*(`x')) + ///
				((_b[c.counter#c.counter]+_b[`class'.oesch#c.counter#counter])*(`x'*`x'))
			putexcel A`row' = `class'
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Baseline")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		}
		*
		
		// Demographics	
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			i.YEAR [aw=svyw], fe vce(cluster id)
			
		foreach x of num 0/6 {
			lincom (_b[counter]*(`x'))+(_b[c.counter#c.counter]*(`x'*`x'))
			putexcel A`row' = 1
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Demographics")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		
		foreach class of num 2/6 {
		foreach x of num 0/6 {
			lincom ((_b[counter]+_b[`class'.oesch#c.counter])*(`x')) + ///
				((_b[c.counter#c.counter]+_b[`class'.oesch#c.counter#counter])*(`x'*`x'))
			putexcel A`row' = `class'
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Demographics")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		}
		*
		
		// Education	
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.ed##(c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			i.YEAR [aw=svyw], fe vce(cluster id)
			
		foreach x of num 0/6 {
			lincom (_b[counter]*(`x'))+(_b[c.counter#c.counter]*(`x'*`x'))
			putexcel A`row' = 1
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Education")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		
		foreach class of num 2/6 {
		foreach x of num 0/6 {
			lincom ((_b[counter]+_b[`class'.oesch#c.counter])*(`x')) + ///
				((_b[c.counter#c.counter]+_b[`class'.oesch#c.counter#counter])*(`x'*`x'))
			putexcel A`row' = `class'
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Education")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		}
		*

		// Firm Quality
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			ib3.firmqual##(c.counter##c.counter) ///
			i.YEAR [aw=svyw], fe vce(cluster id)
			
		foreach x of num 0/6 {
			lincom (_b[counter]*(`x'))+(_b[c.counter#c.counter]*(`x'*`x'))
			putexcel A`row' = 1
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Firm Quality")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		
		foreach class of num 2/6 {
		foreach x of num 0/6 {
			lincom ((_b[counter]+_b[`class'.oesch#c.counter])*(`x')) + ///
				((_b[c.counter#c.counter]+_b[`class'.oesch#c.counter#counter])*(`x'*`x'))
			putexcel A`row' = `class'
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Firm Quality")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Within Organization (10)")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/org10/reg_`y'_org10_fe.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/org10/growth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/org10/growth_log_real_hwage_fe", replace
	import excel "${tables}/margins/org10/growth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/org10/growth_log_real_hwage_bonus_fe", replace
	import excel "${tables}/margins/org10/growth_log_real_hwage_ORG_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/org10/growth_log_real_hwage_ORG_fe", replace
	import excel "${tables}/margins/org10/growth_log_real_hwage_ALL_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/org10/growth_log_real_hwage_ALL_fe", replace
	
	use "${tables}/margins/org10/growth_log_real_hwage_fe", replace
	append using "${tables}/margins/org10/growth_log_real_hwage_bonus_fe"
	append using "${tables}/margins/org10/growth_log_real_hwage_ORG_fe"
	append using "${tables}/margins/org10/growth_log_real_hwage_ALL_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	replace outcome = "3" if outcome=="log_real_hwage_ORG"
	replace outcome = "4" if outcome=="log_real_hwage_ALL"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth_org10", replace
	
	restore
	
	*****************************************
	// Reweighting by organizational size
	*****************************************
	
	preserve
	
	// Adjust weights to account for higher share of workers in larger companies
	gen svyw_N_org = svyw/N_org if counter==0
	bys RIN: replace svyw_N_org = svyw_N_org[_n-1] if svyw_N_org==.
	
	// Modelling
	
	foreach y of var log_real_hwage log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/org10_reweighted_size/growth_`y'_fe", ///
		sheet("Growth Margins") replace
	putexcel A1 = ("oesch") B1 = ("counter") C1 = ("growth") D1 = ("lb") ///
		E1 = ("ub") F1 = ("model") G1 = ("outcome") H1 = ("Growth"), colwise
	
	* Models (reweighted by organization size at t=0)
		// Demographics	
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			i.YEAR [aw=svyw_N_org], fe vce(cluster id)
		
		local row=2
		foreach x of num 0/6 {
			lincom (_b[counter]*(`x'))+(_b[c.counter#c.counter]*(`x'*`x'))
			putexcel A`row' = 1
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Demographics")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Reweighted by org. size (10)")
			local ++row
		}
		*
		
		foreach class of num 2/6 {
		foreach x of num 0/6 {
			lincom ((_b[counter]+_b[`class'.oesch#c.counter])*(`x')) + ///
				((_b[c.counter#c.counter]+_b[`class'.oesch#c.counter#counter])*(`x'*`x'))
			putexcel A`row' = `class'
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("Demographics")
			putexcel G`row' = ("`y'")
			putexcel H`row' = ("Reweighted by org. size (10)")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/org10_reweighted_size/reg_`y'_fe.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/org10_reweighted_size/growth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/org10_reweighted_size/growth_log_real_hwage_fe", replace
	import excel "${tables}/margins/org10_reweighted_size/growth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/org10_reweighted_size/growth_log_real_hwage_bonus_fe", replace
	
	use "${tables}/margins/org10_reweighted_size/growth_log_real_hwage_fe", replace
	append using "${tables}/margins/org10_reweighted_size/growth_log_real_hwage_bonus_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth_org10_reweighted_size", replace
	
	restore
	
* --------------------------------------------------------------------------- */
* 3. CLOSE LOG FILE
* ---------------------------------------------------------------------------- *

	log close
	