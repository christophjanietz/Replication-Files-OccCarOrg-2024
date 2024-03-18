/*=============================================================================* 
* DATA Analysis - EBB Sample & Polis
*==============================================================================*
 	Project: Occupations & Careers within Organizations
	Author: Christoph Janietz (University of Groningen)
	Last update: 17-03-2024
	
	Purpose: Main data analysis (Organizations with n>=20).
	
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings 
		1. 	Setup sample
		2.  Descriptives
		3.  Analysis of organizational exit
		4.  Fixed effects growth curves by occupational class
		5. 	Analysis of between-group variance in growth
		6.  Robustness analyses
		7.  Close log file
			
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art4"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"$logfiles/02_analysis.log", replace

	
* --------------------------------------------------------------------------- */
* 1. SETUP SAMPLE
* ---------------------------------------------------------------------------- *

	use "${posted}/analysis", replace
	
	sort rinpersoons rinpersoon YEAR
	
	* Drop observations before EBB survey and 8+ years after EBB survey
	drop if counter<0 | counter>6
	
	* Fill inbetween missings time-constant variables
	* Industry
	by rinpersoons rinpersoon: replace industry=industry[_n-1] if industry==.
	
	// Sample Cuts
	* Drop workers with unidentified occupation code
	drop if ISCO==.
	* -> 276,387 remaining of 280,293
	* Drop missing observations in Oesch classification
	drop if oesch==.
	* -> 276,269 remaining of 280,293
	* Drop workers with unknown tenure
	drop if tenure_y==.
	* -> 267,181 remaining of 280,293
	* Drop workers with unknown education
	drop if ed==.
	* -> 266,045 remaining of 280,293
	* Drop workers with missing wage
	drop if hwage==.
	* -> 266,044 remaining of 280,293
	
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
* 2. DESCRIPTIVES
* ---------------------------------------------------------------------------- *

	* Descriptives: Survival Rates
	preserve
	egen tag = tag(RIN counter)
	collapse (count) n=tag [aw=svyw], by(counter)
	gen oesch = 99
	order oesch, after(counter)
	
	gen tot = n if counter==0
	replace tot = tot[_n-1] if tot==. & counter!=0
	gen share = n/tot
	
	save "${posted}/descr_counter_all.dta", replace
	restore
	
	preserve
	egen tag = tag(RIN counter)
	collapse (count) n=tag [aw=svyw], by(oesch counter)
	
	gen tot = n if counter==0
	by oesch: replace tot = tot[_n-1] if tot==. & counter!=0
	gen share = n/tot
	
	append using "${posted}/descr_counter_all.dta"
	erase "${posted}/descr_counter_all.dta"
	
	save "${posted}/descr_counter.dta", replace
	restore
	
	*  Descriptives: all
	preserve
	tab oesch, gen(oe)
	tab firmqual, gen(fq)
	tab jobtype_PLS, gen(jt)
	tab ed, gen(ed)
	tab gender, gen(g)
	tab migback, gen(m)
	tab hhchild, gen(ch)
	tab SURVEY_Y, gen(y)
	collapse (mean) techp=oe1 ///
					manager=oe2 ///
					sociop=oe3 ///
					prodw=oe4 ///
					officew=oe5 ///
					servicew=oe6 ///
					hw=real_hwage ///
					hw_bonus=real_hwage_bonus ///
					relpos_org=log_real_hwage_ORG ///
					relpos_all=log_real_hwage_ALL ///
					vlpfirm=fq1 ///
					lpfirm=fq2 ///
					mpfirm=fq3 ///
					hpfirm=fq4 ///
					vhpfirm=fq5 ///
					standard=jt1 ///
					tempagency=jt2 ///
					oncall=jt3 ///
					tenure=tenure_y ///
					isced02=ed1 ///
					isced35=ed2 ///
					isced68=ed3 ///
					men=g1 ///
					women=g2 ///
					nomig=m1 ///
					fsrt=m2 ///
					scnd=m3 ///
					ch_no=ch1 ///
					ch_yes=ch2 ///
					age=age ///
					y2006=y1 ///
					y2007=y2 ///
					y2008=y3 ///
					y2009=y4 ///
					y2010=y5 ///
					y2011=y6 ///
					y2012=y7 ///
					y2013=y8 ///
			  (sd)  sd_hw=real_hwage ///
					sd_hw_bonus=real_hwage_bonus ///
					sd_relpos_org=log_real_hwage_ORG ///
					sd_relpos_all=log_real_hwage_ALL ///
					sd_tenure=tenure_y ///
					sd_age=age ///
			  [aw=svyw], ///
			  by(counter)
	save "${posted}/descr_all.dta", replace
	restore
	
	*  Descriptives: by class
	preserve
	tab firmqual, gen(fq)
	tab jobtype_PLS, gen(jt)
	tab ed, gen(ed)
	tab gender, gen(g)
	tab migback, gen(m)
	tab hhchild, gen(ch)
	tab SURVEY_Y, gen(y)
	collapse (mean) hw=real_hwage ///
					hw_bonus=real_hwage_bonus ///
					relpos_org=log_real_hwage_ORG ///
					relpos_all=log_real_hwage_ALL ///
					vlpfirm=fq1 ///
					lpfirm=fq2 ///
					mpfirm=fq3 ///
					hpfirm=fq4 ///
					vhpfirm=fq5 ///
					standard=jt1 ///
					tempagency=jt2 ///
					oncall=jt3 ///
					tenure=tenure_y ///
					isced02=ed1 ///
					isced35=ed2 ///
					isced68=ed3 ///
					men=g1 ///
					women=g2 ///
					nomig=m1 ///
					fsrt=m2 ///
					scnd=m3 ///
					ch_no=ch1 ///
					ch_yes=ch2 ///
					age=age ///
					y2006=y1 ///
					y2007=y2 ///
					y2008=y3 ///
					y2009=y4 ///
					y2010=y5 ///
					y2011=y6 ///
					y2012=y7 ///
					y2013=y8 ///
			  (sd)  sd_hw=real_hwage ///
					sd_hw_bonus=real_hwage_bonus ///
					sd_relpos_org=log_real_hwage_ORG ///
					sd_relpos_all=log_real_hwage_ALL ///
					sd_tenure=tenure_y ///
					sd_age=age ///
			  [aw=svyw], ///
			  by(oesch counter)
	save "${posted}/descr_byclass.dta", replace
	restore	
	
	*Density Plots: Relative Wage Position / Hourly Wage
	
	preserve
	
	bys RIN: egen max = max(counter)
	keep if max==6 & (counter==0 | counter==6)
	drop max
	
	by RIN: egen count = count(log_real_hwage_ORG)
	keep if count==2
	
	keep log_real_hwage_ORG log_real_hwage_ALL real_hwage real_hwage_bonus ///
		counter oesch svyw
	
	save "${posted}/descriptives_density", replace
	
	restore


* --------------------------------------------------------------------------- */
* 3. ANALYSIS OF ORGANIZATIONAL EXIT
* ---------------------------------------------------------------------------- *

	*Time-to-Exit data 
	
	preserve
	
	bys RIN: egen time = max(counter)
	gen event = .
	bys RIN: replace event = 0 if time==6
	bys RIN: replace event = 1 if time!=6
	
	egen tag = tag(RIN)
	keep if tag==1
	
	keep id time event oesch svyw
	gen cat = oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/time_to_exit", replace
	
	restore
			
* --------------------------------------------------------------------------- */
* 4. FIXED EFFECTS GROWTH CURVES BY OCCUPATIONAL CLASS
* ---------------------------------------------------------------------------- *
	
	preserve
	
	foreach y of var log_real_hwage_ORG log_real_hwage_ALL log_real_hwage ///
	log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/fe/growth_`y'_fe", sheet("Growth Margins") replace
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
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
			putexcel H`row' = ("Within Organization")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/fe/reg_`y'_fe.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/fe/growth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/fe/growth_log_real_hwage_fe", replace
	import excel "${tables}/margins/fe/growth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/fe/growth_log_real_hwage_bonus_fe", replace
	import excel "${tables}/margins/fe/growth_log_real_hwage_ORG_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/fe/growth_log_real_hwage_ORG_fe", replace
	import excel "${tables}/margins/fe/growth_log_real_hwage_ALL_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/fe/growth_log_real_hwage_ALL_fe", replace
	
	use "${tables}/margins/fe/growth_log_real_hwage_fe", replace
	append using "${tables}/margins/fe/growth_log_real_hwage_bonus_fe"
	append using "${tables}/margins/fe/growth_log_real_hwage_ORG_fe"
	append using "${tables}/margins/fe/growth_log_real_hwage_ALL_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	replace outcome = "3" if outcome=="log_real_hwage_ORG"
	replace outcome = "4" if outcome=="log_real_hwage_ALL"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth", replace
	
	restore
	
	
* --------------------------------------------------------------------------- */
* 5. ANALYSIS OF BETWEEN-GROUP VARIANCE IN GROWTH 
* ---------------------------------------------------------------------------- *
	
	preserve
	
	foreach y of var log_real_hwage_ORG log_real_hwage_ALL log_real_hwage ///
	log_real_hwage_bonus {
		import excel "${tables}/margins/fe/growth_`y'_fe", ///
			sheet("Growth Margins") firstrow clear
		
		replace lb=0 if counter==0
		replace ub=0 if counter==0
	
		merge m:1 oesch counter using "${posted}/p", keepusing(p) nogen
	
		*Calculating grand mean
		gen coeff = growth*p
		bys model counter: egen grandmean = total(coeff)
		*Subtracting
		gen comp = (growth-grandmean)^2
		*Weight
		gen coeff2 = comp*p
		*Sum for final between-class variance
		bys model counter: egen variance = total(coeff2)
	
		drop coeff-coeff2
	
		*Reduce to single observation per model & counter##c
		egen tag = tag(model counter)
		keep if tag==1
		drop oesch growth lb ub p tag
	
		* Global variable for baseline 
		gen var_base = variance if model=="Demographics"
	
		sort counter var_base
		by counter: replace var_base = var_base[_n-1] if var_base==. 

		sort model counter
		
		* Relative proportion explained
		gen expl = 1-(variance/var_base)
		
		*Standardize variance (Demographics @ counter==1 = 1)
		gen VAR = variance if model=="Demographics" & counter==1
		egen var = max(VAR)
		
		gen var_std = variance/var
		drop VAR
	
		gen y = "`y'"
	
		save "${posted}/var_`y'", replace
		
	}
	*
	
	use "${posted}/var_log_real_hwage", replace
	
	append using "${posted}/var_log_real_hwage_bonus"
	append using "${posted}/var_log_real_hwage_ORG"
	append using "${posted}/var_log_real_hwage_ALL"
	
	save "${posted}/var_analysis", replace
	
	erase "${posted}/var_log_real_hwage.dta"
	erase "${posted}/var_log_real_hwage_bonus.dta"
	erase "${posted}/var_log_real_hwage_ORG.dta"
	erase "${posted}/var_log_real_hwage_ALL.dta"
	
	restore

* --------------------------------------------------------------------------- */
* 6. ROBUSTNESS ANALYSES
* ---------------------------------------------------------------------------- *

	**************************
	// A. Education as control
	**************************
	
	* Is implemented in the preceeding section. Results can be found in the
	* regression tables.
	
	**************************
	// B. Detailed Occupations
	**************************
	
	preserve
	
	* Drop Singletons
	bys RIN: gen N = _N
	drop if N==1
	
	* Count unique persons per occupations
	gen tag = 1 if counter==0
	bys isco3: egen N_unique = count(tag)
	
	* Drop occupations <10 unique workers
	drop if N_unique<10
	drop N tag N_unique
	
	levelsof isco3 if isco3!=100, local(occ_code)
	
	foreach y of var log_real_hwage_ORG log_real_hwage_ALL log_real_hwage ///
	log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/isco/growth_`y'_fe", sheet("Growth Margins") replace
	putexcel A1 = ("isco3") B1 = ("counter") C1 = ("growth") D1 = ("lb") ///
		E1 = ("ub") F1 = ("outcome"), colwise
		
	* Models
	// Demographics
		eststo: xtreg `y' i.isco3#(c.counter##c.counter) (c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			i.YEAR [aw=svyw], fe vce(cluster id)
		
		local row=2
		foreach x of num 0/6 {
			lincom (_b[counter]*(`x'))+(_b[c.counter#c.counter]*(`x'*`x'))
			putexcel A`row' = 100
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("`y'")
			local ++row
		}
		*
		
		foreach occ of num 110 111 112 121 122 131 132 133 134 141 142 143 210 ///
		211 212 213 214 215 216 221 222 223 225 226 230 231 232 233 234 235 241 ///
		242 243 250 251 252 261 262 263 264 265 311 312 313 314 315 321 322 324 ///
		325 331 332 333 334 335 341 342 343 350 351 352 400 410 411 412 413 421 ///
		422 431 432 441 511 512 513 514 515 516 521 522 523 524 531 532 541 611 ///
		612 613 621 622 700 711 712 713 720 721 722 723 731 732 741 742 750 751 ///
		752 753 754 810 811 812 813 814 815 816 817 818 821 830 831 832 833 834 ///
		835 911 912 921 931 932 933 941 961 962 {
		foreach x of num 0/6 {
			lincom ((_b[counter]+_b[`occ'.isco3#c.counter])*(`x')) + ///
				((_b[c.counter#c.counter]+_b[`occ'.isco3#c.counter#counter])*(`x'*`x'))
			putexcel A`row' = `occ'
			putexcel B`row' = `x'
			putexcel C`row' = (r(estimate))
			putexcel D`row' = (r(lb))
			putexcel E`row' = (r(ub))
			putexcel F`row' = ("`y'")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/isco/reg_`y'.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/isco/growth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/isco/growth_log_real_hwage_fe", replace
	import excel "${tables}/margins/isco/growth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/isco/growth_log_real_hwage_bonus_fe", replace
	import excel "${tables}/margins/isco/growth_log_real_hwage_ORG_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/isco/growth_log_real_hwage_ORG_fe", replace
	import excel "${tables}/margins/isco/growth_log_real_hwage_ALL_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/isco/growth_log_real_hwage_ALL_fe", replace
	
	use "${tables}/margins/isco/growth_log_real_hwage_fe", replace
	append using "${tables}/margins/isco/growth_log_real_hwage_bonus_fe"
	append using "${tables}/margins/isco/growth_log_real_hwage_ORG_fe"
	append using "${tables}/margins/isco/growth_log_real_hwage_ALL_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	replace outcome = "3" if outcome=="log_real_hwage_ORG"
	replace outcome = "4" if outcome=="log_real_hwage_ALL"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	sort isco3
	merge m:1 isco3 using "${posted}/oesch_isco3", nogen keep(match)
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth_occdetail", replace
	
	
	restore
	
	// Merge case numbers to growth_occdetail
	
	preserve
	
	* Drop singletons
	bys RIN: gen N = _N
	drop if N==1
	drop N
	* Count unique persons per occupations
	gen tag = 1 if counter==0
	bys isco3: egen N = count(tag)
	* Drop occupations <10 unique workers
	drop if N<10
	keep isco3 N
	egen tag = tag(isco3)
	keep if tag==1
	drop tag
	sort isco3
	
	save "${posted}/occ_N", replace
	
	restore
	
	preserve
	
	use "${posted}/growth_occdetail", replace
	sort isco3
	merge m:1 isco3 using "${posted}/occ_N", keepusing(N) nogen
	order N, after(isco3)
	save "${posted}/growth_occdetail", replace
	
	erase "${posted}/occ_N.dta"
	
	restore
	
	****************************************************
	// C. Occuption-level correlation baseline & growth
	****************************************************
	preserve
	
	* Drop Singletons
	bys RIN: gen N = _N
	drop if N==1
	
	* Count unique persons per occupations
	gen tag = 1 if counter==0
	bys isco3: egen N_unique = count(tag)
	
	* Drop occupations <10 unique workers
	drop if N_unique<10
	drop N tag N_unique
	
	* Collapse to derive average wage / wage position at the group-level
	collapse (mean) hw=real_hwage ///
					hw_bonus=real_hwage_bonus ///
					relpos_org=log_real_hwage_ORG ///
					relpos_all=log_real_hwage_ALL ///
			  [aw=svyw], ///
			  by(isco3 counter)
	keep if counter==0
	drop counter
	
	merge 1:m isco3 using "${posted}/growth_occdetail", nogen
	keep if counter==6 & outcome==1
	drop counter lb ub outcome
	
	save "${posted}/corr_occ", replace
	
	restore
	
	**************************
	// D. Unrestricted Growth
	**************************
	
	preserve
	
	use "${posted}/analysis_unrestricted.dta", replace
	
	// Set Panel
	gen RIN = rinpersoons+rinpersoon
	order RIN, before(rinpersoons)
	egen id = group(RIN)
	order id, after(RIN)
	xtset id counter
	
	// Modelling
	
	foreach y of var log_real_hwage log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/unrestricted/unrestrictedgrowth_`y'_fe", ///
		sheet("Growth Margins") replace
	putexcel A1 = ("oesch") B1 = ("counter") C1 = ("growth") D1 = ("lb") ///
		E1 = ("ub") F1 = ("model") G1 = ("outcome") H1 = ("Growth"), colwise
	
	* Models
		// Demographics	
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			i.YEAR [aw=svyw], fe vce(cluster id)
		
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
			putexcel H`row' = ("Unrestricted")
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
			putexcel H`row' = ("Unrestricted")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/unrestricted/reg_`y'_fe.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/unrestricted/unrestrictedgrowth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/unrestricted/unrestrictedgrowth_log_real_hwage_fe", replace
	import excel "${tables}/margins/unrestricted/unrestrictedgrowth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/unrestricted/unrestrictedgrowth_log_real_hwage_bonus_fe", replace
	
	use "${tables}/margins/unrestricted/unrestrictedgrowth_log_real_hwage_fe", replace
	append using "${tables}/margins/unrestricted/unrestrictedgrowth_log_real_hwage_bonus_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth_unrestricted", replace
	
	restore
	
	*****************************************
	// E. Reweighting by organizational size
	*****************************************
	
	preserve
	
	// Adjust weights to account for higher share of workers in larger companies
	gen svyw_N_org = svyw/N_org if counter==0
	bys RIN: replace svyw_N_org = svyw_N_org[_n-1] if svyw_N_org==.
	
	// Modelling
	foreach y of var log_real_hwage log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/reweighted_size/growth_`y'_fe", ///
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
			putexcel H`row' = ("Reweighted by org. size")
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
			putexcel H`row' = ("Reweighted by org. size")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/reweighted_size/reg_`y'_fe.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/reweighted_size/growth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/reweighted_size/growth_log_real_hwage_fe", replace
	import excel "${tables}/margins/reweighted_size/growth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/reweighted_size/growth_log_real_hwage_bonus_fe", replace
	
	use "${tables}/margins/reweighted_size/growth_log_real_hwage_fe", replace
	append using "${tables}/margins/reweighted_size/growth_log_real_hwage_bonus_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth_reweighted_size", replace
	
	restore
	
	
	*****************************************
	// F. Tenure = 0
	*****************************************
	
	preserve
	
	// Select only workers who are observed in the first year
	bys id: egen ten0 = min(tenure_y)
	keep if ten0==0
	drop ten0
	

	// Modelling
	foreach y of var log_real_hwage_ORG log_real_hwage_ALL log_real_hwage log_real_hwage_bonus {
	    
	putexcel set "${tables}/margins/tenure/growth_`y'_fe", ///
		sheet("Growth Margins") replace
	putexcel A1 = ("oesch") B1 = ("counter") C1 = ("growth") D1 = ("lb") ///
		E1 = ("ub") F1 = ("model") G1 = ("outcome") H1 = ("Growth"), colwise
	
	* Models (reweighted by organization size at t=0)
		// Demographics	
		eststo: xtreg `y' i.oesch##(c.counter##c.counter) ///
			i.gender##i.migback##(c.counter##c.counter) ///
			i.gender##i.hhchild##(c.counter##c.counter)  ///
			i.YEAR [aw=svyw], fe vce(cluster id)
		
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
			putexcel H`row' = ("Tenure = 0")
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
			putexcel H`row' = ("Tenure = 0")
			local ++row
		}
		*
		}
		*

	* Save model estimates
		esttab using "${tables}/regression/tenure/reg_`y'_fe.csv", ///
			replace se r2 ar2 nobaselevels 
		est clear
		
	}
	*
	
	* Create dataset for Figure
	import excel "${tables}/margins/tenure/growth_log_real_hwage_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/tenure/growth_log_real_hwage_fe", replace
	import excel "${tables}/margins/tenure/growth_log_real_hwage_bonus_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/tenure/growth_log_real_hwage_bonus_fe", replace
	import excel "${tables}/margins/tenure/growth_log_real_hwage_ORG_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/tenure/growth_log_real_hwage_ORG_fe", replace
	import excel "${tables}/margins/tenure/growth_log_real_hwage_ALL_fe", ///
		sheet("Growth Margins") firstrow clear
	save "${tables}/margins/tenure/growth_log_real_hwage_ALL_fe", replace
	
	use "${tables}/margins/tenure/growth_log_real_hwage_fe", replace
	append using "${tables}/margins/tenure/growth_log_real_hwage_bonus_fe"
	append using "${tables}/margins/tenure/growth_log_real_hwage_ORG_fe"
	append using "${tables}/margins/tenure/growth_log_real_hwage_ALL_fe"
	
	replace outcome = "1" if outcome=="log_real_hwage"
	replace outcome = "2" if outcome=="log_real_hwage_bonus"
	replace outcome = "3" if outcome=="log_real_hwage_ORG"
	replace outcome = "4" if outcome=="log_real_hwage_ALL"
	
	destring outcome, replace
	
	replace lb=0 if lb==.
	replace ub=0 if ub==.
	
	gen cat=oesch
	recode cat (1=1) (2=3) (3=5) (4=2) (5=4) (6=6)
	
	save "${posted}/growth_tenure", replace
	
	restore
	
	
* --------------------------------------------------------------------------- */
* 7. CLOSE LOG FILE
* ---------------------------------------------------------------------------- *

	log close	
