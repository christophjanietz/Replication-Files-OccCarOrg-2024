/*=============================================================================* 
* DATA PREPARATIONS - EBB Sample & Polis
*==============================================================================*
 	Project: Occupations & Careers within Organizations
	Author: Christoph Janietz (University of Groningen)
	Last update: 17-03-2024
	
	Purpose: Preparation of the dataset for analysis.
	
* ---------------------------------------------------------------------------- *

	INDEX: 
		0.  Settings 
		1. 	Create EBB-CORE
		2. 	Create SPOLIS-CORE
		3.  Initial merge (Determine organization of focus)
		4.  Second merge (Match on identified pers-org combinations)
		5.  AKM firm fixed effects (Firm quality measure)
		6.  Auxiliary files
		7.  Close Log File
		
* --------------------------------------------------------------------------- */
* 0. SETTINGS 
* ---------------------------------------------------------------------------- * 

*** Settings - run config file
	global dir 			"H:/Christoph/art4"
	do 					"${dir}/06_dofiles/config"
	
*** Open log file
	log using 			"$logfiles/01_sample.log", replace

* --------------------------------------------------------------------------- */
* 1. CREATE EBB-CORE
* ---------------------------------------------------------------------------- *

* EBB-CORE are the pooled cross-sectional observations of workers between 2006-2013.
* These observations are the starting points for evaluating career progression
* within firms. 

*****************************
*** APPENDING EBBnw 2006-2013
*****************************
	foreach year of num 2006/2013 {
		use RINPERSOONS RINPERSOON SLEUTELEBB EBBSTKPEILINGNUMMER EBBAFLJAAR ///
		EBBAFLKWARTAAL EBBGEWJAARGEWICHTP1A EBBHHBGESLACHT ///
		EBBAFLLFT EBBAFLGENERATIE EBBPB2POSHH EBBAFLLFTJNGJR EBBAFLBBINT ///
		EBBPB2POSWRKFLEX1 EBBAFLPOSWRKFLEXZZP1 EBBAFLAANTWERK EBBAFLANCIENMND ///
		EBBTW1ISCO2008V ISCED2011LEVELHB _v1 ///
		using "${ebbnw`year'}"
		rename _v1 ISCEDF2013RICHTINGPUBLICATIEINDN
		rename RINPERSOONS RINPERSOON SLEUTELEBB EBBSTKPEILINGNUMMER EBBAFLJAAR ///
		EBBAFLKWARTAAL EBBHHBGESLACHT EBBAFLLFT EBBAFLGENERATIE ///
		EBBAFLLFTJNGJR EBBAFLBBINT EBBAFLAANTWERK ///
		EBBAFLANCIENMND, lower
		
		tempfile temp`year'
		save "`temp`year''"
	}
	*

	append using "`temp2006'" "`temp2007'" "`temp2008'" "`temp2009'" "`temp2010'" ///
		"`temp2011'" "`temp2012'" 
	sort ebbafljaar rinpersoons rinpersoon


************************
*** VARIABLE ADJUSTMENTS
************************

	*Create Combi-RINPERSOON
	gen RIN = rinpersoons+rinpersoon
	order RIN, before(rinpersoons)

	// Date variables
	*SURVEY
	gen SURVEY_YMD = date(sleutelebb, "YMD") 
	format SURVEY_YMD %d
	lab var SURVEY_YMD "Exact Date of Survey"
	
	gen SURVEY_Y = year(SURVEY_YMD)
	lab var SURVEY_Y "Year of Survey"
	
	order SURVEY_YMD SURVEY_Y, after(sleutelebb)

	*PUBLICATION
	destring ebbafljaar ebbaflkwartaal, replace
	gen PUB_YQ = yq(ebbafljaar, ebbaflkwartaal)
	format PUB_YQ %tq
	lab var PUB_YQ "Quarter / Year of Publication"
	order PUB_YQ, after(ebbaflkwartaal)


*****************************
*** CREATE SAMPLE
*****************************

*** Restrict to first peiling
	keep if ebbstkpeilingnummer=="1"

*** Restrict to working population & not self-employed
	keep if ebbaflbbint=="1" & EBBPB2POSWRKFLEX1=="1"
	
*** Restrict to respondents that are registered in GBA
	keep if rinpersoons=="R"
	
*** Restrict to age 21-58 (for first observation)
	rename ebbafllft age
	keep if age>=21 & age<=58
	
*** Restrict to non-military workers
	destring EBBTW1ISCO2008V, replace
	drop if EBBTW1ISCO2008V<1000
	
	drop ebbstkpeilingnummer ebbaflbbint EBBPB2POSWRKFLEX1
	
	
*****************************
*** CLEAN DUPLICATES
*****************************

*** RIN + Survey Year
* After core sample selection 34 duplicate pairs (68 tagged) remain in the data.
* I select one observation of each pair based on the earliest survey timing

	sort SURVEY_Y rinpersoons rinpersoon
	duplicates tag SURVEY_Y rinpersoons rinpersoon, gen (dupl)
	tab dupl
	
	sort SURVEY_Y rinpersoons rinpersoon SURVEY_YMD

	bys SURVEY_Y rinpersoons rinpersoon: gen n = _n
	gen select = 0
	replace select = 1 if n==1
	keep if select==1
	tab dupl
	drop select dupl n 
	
*** (only) RIN 
* Respondents can be sampled a second time between 2006 and 2013. 
* (1,673 ppl (2x); 2 ppl (3x))
* I restrict observations to one per person over the full period.

	sort rinpersoons rinpersoon
	duplicates tag RIN, gen (dupl)
	tab dupl
	
	sort RIN SURVEY_Y 

	bys RIN: gen n = _n
	gen select = 0
	replace select = 1 if n==1
	keep if select==1
	tab dupl
	drop select dupl n 

	
**********************************
*** Decoding & Labelling variables
**********************************
	
	* Gender
	rename ebbhhbgeslacht gender
	
	destring gender, replace
	
	lab def gndr_lbl 1 "Male" 2 " Female"
	lab val  gender gndr_lbl
	
	* Migback
	rename ebbaflgeneratie migback
	
	destring migback, replace
	
	recode migback (3 9 = .) (7 = 0)
	
	lab def mgbck_lbl 0 "no migback" 1 "1st gen" 2 "2nd gen"
	lab val migback mgbck_lbl
	
	* Household position
	rename EBBPB2POSHH hhpos
	
	destring hhpos, replace
	
	recode hhpos (9 = .)
	
	lab def hhpos_lbl 1"Eenpersonshuishouden" 2 "Alleenstaande ouder" ///
		3 "Lid van een ouderpaar" 4 "Lid van een paar (geen ouder)" ///
		5 "Overig"
	lab val hhpos hhpos_lbl
	
	* Child 
	rename ebbafllftjngjr hhchild
	
	destring hhchild, replace
	
	recode hhchild (0/18 = 1) (19/97 = 0)
	
	lab def hhchild_lbl 0 "No" 1 "Yes"
	lab val hhchild hhchild_lbl
	
	* Nr. of jobs
	rename ebbaflaantwerk nrjobs
	
	destring nrjobs, replace
	
	recode nrjobs (3 = 2)
	
	lab def nrj_lbl 1 " 1 job" 2 " 2+ jobs"
	lab val nrjobs nrj_lbl 
	
	* Tenure
	rename ebbaflancienmnd tenure_m
	
	destring tenure_m, replace
	
	recode tenure_m (9998 9999 = .)
	
	gen tenure_y = int(tenure_m/12)
	order tenure_y, after(tenure_m)
	
	// Set Tenure as missing if tenure > age-16
	* I assume that the earliest firm entry can be at the age of 16. All other
	* information is potential measurement error.
	gen tag= 1 if tenure_y>(age-16)
	replace tenure_m = . if tag==1
	replace tenure_y = . if tag==1
	drop tag
	
	* Job type (EBB)
	destring EBBAFLPOSWRKFLEXZZP1, replace
	rename EBBAFLPOSWRKFLEXZZP1 jobtype_EBB
	recode jobtype_EBB (1 2 3 4 7 8 = 0) (5 = 1) (6 = 2)
	lab var jobtype_EBB "Jobtype (EBB)"
	lab def jyebb_lbl 0 "Standard" 1 "Temp agency worker" 2 "On-call worker" 
	lab val jobtype_EBB jtebb_lbl
	
	* ISCO2008
	rename EBBTW1ISCO2008V ISCO
	
	recode ISCO (9997 9999 = .)
	
	* ISCED LEVEL
	rename ISCED2011LEVELHB ISCED_lvl 
	
	destring ISCED_lvl, replace
	
	recode ISCED_lvl (9 = .)
	
	lab def lvl_lbl 0 "less than primary" 1 "primary" 2 "lower secondary" ///
		3 "upper secondary" 4 "post-secondary non-tertiary" 5 "short cycle tertiary" ///
		6 "bachelor or equivalent" 7 "master or equivalent" 8 "doctoral or equivalent" 
	lab val ISCED_lvl lvl_lbl
	
	* ISCED FIELD
	rename ISCEDF2013RICHTINGPUBLICATIEINDN ISCED_fld
	
	destring ISCED_fld, replace
	
	recode ISCED_fld (9999 = .)
	
	lab def fld_lbl 0 "algemeen" 100 "onderwijs" 200 "vormgeving, kunst, taken, en geschiednis" ///
		300 "journalistik, gedrag en maatschappij" ///
		400 "recht, administratie, handel en zakelijke dienstverlening" ///
		500 "wiskunde, naturwetenschappen" 600 "informatica" ///
		700 "techniek, industrie, en bouwkunde" 800 "landbouw, diergeneeskunde en -verzorging" ///
		900 "gezondheidszorg en welzijn" 1000 "dienstverlening"
	lab val ISCED_fld fld_lbl
	
	* Generate Year Indicator for merge
	clonevar YEAR = SURVEY_Y
	order YEAR, before(rinpersoons)
	
	* Save
	save "${data}/EBB_core", replace
	

* --------------------------------------------------------------------------- */
* 2. CREATE SPOLIS-CORE
* ---------------------------------------------------------------------------- *

* The Yearly SPOLIS FILES have a threefold purpose:
* 1) Identify the BEID IDs of a person at the moment of the EBB survey
* 2) Generate Wage data (hourly wage during the whole calendar year)
* 3) Derive within-organization wage measures (distributional)

*** Exclude WSW-er, Directeur/Grooteandeelhouder

**********************************************************
*** Aggregate at BEID-Level 
**********************************************************

*** 2006-2009: POLIS
	foreach year of num 2006/2009 {
		use rinpersoons rinpersoon baanrugid aanvbus eindbus baandagen basisloon ///
			basisuren bijzonderebeloning extrsal incidentsal lningld lnowrk ///
			overwerkuren reisk vakbsl voltijddagen contractsoort polisdienstverband ///
			beid caosector datumaanvangikv datumeindeikv sect soortbaan ///
			using "${polis`year'}", replace
		
		*Harmonize variable names
		foreach var of var baandagen basisloon basisuren bijzonderebeloning extrsal ///
			incidentsal lningld lnowrk overwerkuren reisk vakbsl voltijddagen ///
			contractsoort polisdienstverband beid caosector datumaanvangikv ///
			datumeindeikv sect soortbaan {
			rename `var' s`var' 
		}
		*
		rename (aanvbus eindbus) (sdatumaanvangiko sdatumeindeiko)
		
		*Prepare date indicators
		gen job_start_exact = date(sdatumaanvangiko, "YMD")
		gen job_end_exact = date(sdatumeindeiko, "YMD")
		gen job_start_caly = date(sdatumaanvangikv, "YMD")
		gen job_end_caly = date(sdatumeindeikv, "YMD")
		format job_start_exact job_end_exact job_start_caly job_end_caly %d
		
		drop sdatumaanvangiko sdatumeindeiko sdatumaanvangikv sdatumeindeikv
	
		************************************************************************
		// SELECTION - Keep only pers-org IDs that existed on 31st of December
		************************************************************************
		bys rinpersoons rinpersoon sbeid: egen job_start_caly_beid = min(job_start_caly)
		bys rinpersoons rinpersoon sbeid: egen job_end_caly_beid = max(job_end_caly)
		format job_start_caly_beid job_end_caly_beid %d
		egen lastday_caly = max(job_end_caly)
		format lastday_caly %d
		keep if (job_end_caly_beid == lastday_caly)
		drop lastday_caly
		

		************************************************************************
		*JOB Summary statistics for whole calendar year within BEID (all obs per unique job ID)
		************************************************************************
		foreach var of var sbaandagen-svoltijddagen {
			bys rinpersoons rinpersoon sbeid: egen `var'_caly_beid = total(`var')
		}
		*
		
		*Drop non-aggregated variables
		drop sbaandagen-svoltijddagen
		
		************************************************************************
		// Consistency of categories in same job-year combination
		* Contract duration
		gen cntrct = 0
		replace cntrct = 1 if scontractsoort=="B"
		replace cntrct = 1 if scontractsoort=="b"
		drop scontractsoort
		bys rinpersoons rinpersoon sbeid: egen scontractsoort = min(cntrct)
		drop cntrct
		
		lab var scontractsoort "soort contract"
		lab def cntrct_lbl 0 "Non-temporary" 1 "Temporary"
		lab val scontractsoort cntrct_lbl
		
		* Full-time / Part-time
		gen dienstverband = real(spolisdienstverband)
		drop spolisdienstverband 
		bys rinpersoons rinpersoon sbeid: egen spolisdienstverband = min(dienstverband)
		drop dienstverband
		
		lab var spolisdienstverband "dienstverband"
		lab def dnst_lbl 1 "Full-time" 2 "Part-time"
		lab val spolisdienstverband dnst_lbl
		
		* Job type
		gen soortbaan = real(ssoortbaan)
		drop ssoortbaan
		recode soortbaan (1 = 10)
		bys rinpersoons rinpersoon sbeid: egen ssoortbaan = max(soortbaan)
		drop soortbaan
		
		lab var ssoortbaan "soort baan"
		lab def srt_lbl 2 "Stagiare" 3 "WSW-er" 4 "Uitzendkracht" ///
			5 "Oproepkracht" 9 "Rest" 10 "Directeur / Grot Aandeelhouder"
		lab val ssoortbaan srt_lbl
		************************************************************************
		
		* Select one observation per Person-BEID
		egen select = tag(rinpersoons rinpersoon sbeid)
		keep if select == 1
		drop select
		
		*Create full-time-factor on beid-level
		gen ft_factor = svoltijddagen_caly_beid / sbaandagen_caly_beid

		*Merge Geboortejaar
		merge m:1 rinpersoons rinpersoon using "${GBAPERSOON2009}", ///
			keepusing(gbageboortejaar gbageboortemaand) ///
			nogen keep(match master)
	
		save "${data}/fullpolis_`year'.dta", replace
	}
	*

*** 2010-2019: SPOLIS
	foreach year of num 2010/2019 {
		use rinpersoons rinpersoon ikvid sdatumaanvangiko sdatumeindeiko sbaandagen ///
			sbasisloon sbasisuren sbijzonderebeloning sextrsal sincidentsal ///
			slningld slnowrk soverwerkuren sreisk svakbsl svoltijddagen ///
			scontractsoort spolisdienstverband sbeid scaosector sdatumaanvangikv ///
			sdatumeindeikv ssect ssoortbaan using "${spolis`year'}", replace 
			
		*Prepare date indicators
		gen job_start_exact = date(sdatumaanvangiko, "YMD")
		gen job_end_exact = date(sdatumeindeiko, "YMD")
		gen job_start_caly = date(sdatumaanvangikv, "YMD")
		gen job_end_caly = date(sdatumeindeikv, "YMD")
		format job_start_exact job_end_exact job_start_caly job_end_caly %d
		
		drop sdatumaanvangiko sdatumeindeiko sdatumaanvangikv sdatumeindeikv
	
		************************************************************************
		// SELECTION - Keep only pers-org IDs that existed on 31st of December
		************************************************************************
		bys rinpersoons rinpersoon sbeid: egen job_start_caly_beid = min(job_start_caly)
		bys rinpersoons rinpersoon sbeid: egen job_end_caly_beid = max(job_end_caly)
		format job_start_caly_beid job_end_caly_beid %d
		egen lastday_caly = max(job_end_caly)
		format lastday_caly %d
		keep if (job_end_caly_beid == lastday_caly)
		drop lastday_caly
		
	
		************************************************************************
		*JOB Summary statistics for whole calendar year (all obs per unique job ID)
		************************************************************************
		foreach var of var sbaandagen- svoltijddagen {
			bys rinpersoons rinpersoon sbeid: egen `var'_caly_beid = total(`var')
		}
		*
		
		*Drop non-aggregated variables
		drop sbaandagen-svoltijddagen
		
		************************************************************************
		// Consistency of categories in same job-year combination
		* Contract duration
		gen cntrct = 0
		replace cntrct = 1 if scontractsoort=="B"
		replace cntrct = 1 if scontractsoort=="b"
		drop scontractsoort
		bys rinpersoons rinpersoon sbeid: egen scontractsoort = min(cntrct)
		drop cntrct
		
		lab var scontractsoort "soort contract"
		lab def cntrct_lbl 0 "Non-temporary" 1 "Temporary"
		lab val scontractsoort cntrct_lbl
		
		* Full-time / Part-time
		gen dienstverband = real(spolisdienstverband)
		drop spolisdienstverband 
		bys rinpersoons rinpersoon sbeid: egen spolisdienstverband = min(dienstverband)
		drop dienstverband
		
		lab var spolisdienstverband "dienstverband"
		lab def dnst_lbl 1 "Full-time" 2 "Part-time"
		lab val spolisdienstverband dnst_lbl
		
		* Job type
		gen soortbaan = real(ssoortbaan)
		drop ssoortbaan
		recode soortbaan (1 = 10)
		bys rinpersoons rinpersoon sbeid: egen ssoortbaan = max(soortbaan)
		drop soortbaan
		
		lab var ssoortbaan "soort baan"
		lab def srt_lbl 2 "Stagiare" 3 "WSW-er" 4 "Uitzendkracht" ///
			5 "Oproepkracht" 9 "Rest" 10 "Directeur / Grot Aandeelhouder"
		lab val ssoortbaan srt_lbl
		************************************************************************
		
		* Select one observation per Person-BEID
		egen select = tag(rinpersoons rinpersoon sbeid)
		keep if select == 1
		drop select
		
		*Create full-time-factor on beid-level
		gen ft_factor = svoltijddagen_caly_beid / sbaandagen_caly_beid
		
		*Merge Geboortejaar
		capture merge m:1 rinpersoons rinpersoon using "${GBAPERSOON2019}", ///
			keepusing(gbageboortejaar gbageboortemaand) ///
			nogen keep(match master)
	
		save "${data}/fullpolis_`year'.dta", replace
	}
	*
	
**********************************************************
*** Prepare for further analysis
**********************************************************
	
*** 
	foreach year of num 2006/2019 {
		use "${data}/CPI.dta", replace
		keep if YEAR==`year'
		tempfile temp
		save "`temp'" 
	
		use "${data}/fullpolis_`year'.dta", replace
		gen YEAR = `year'
		order YEAR, before(rinpersoons)
		merge m:1 YEAR using "`temp'", nogen
		
		* Generate two hourly wage measures
		* Basis
		gen hwage = sbasisloon_caly_beid / sbasisuren_caly_beid
		* With Boni
		gen hwage_bonus = (sbasisloon_caly_beid + sbijzonderebeloning_caly_beid) / ///
			sbasisuren_caly_beid

		* Adjust for inflation (2015 prices)
		gen real_hwage = hwage/CPI
		gen real_hwage_bonus = hwage_bonus/CPI
		
		*BOTTOM-code wage measures (before log transformation)
		foreach v of var hwage-real_hwage_bonus {
		    replace `v' = 1 if `v'<1
		}
		
		*TOP-code wage measures? (before log transformation)
		foreach v of var hwage-real_hwage_bonus {
		    replace `v' = 1000 if `v'>1000 & `v'!= .
		} 
		
		*Create log of hourly wages
		gen log_real_hwage = log(real_hwage)
		gen log_real_hwage_bonus = log(real_hwage_bonus)
		
		* Generate age variable
		gen byear = real(gbageboortejaar)
		gen age = `year'-byear
		
		*Create numeric beid variable
		egen org = group(sbeid)
		
		* Drop variables that are not used anymore
		drop job_start_exact job_end_exact job_start_caly job_end_caly ///
			sbaandagen_caly_beid sbasisloon_caly_beid sbijzonderebeloning_caly_beid ///
			sextrsal_caly_beid sincidentsal_caly_beid slningld_caly_beid ///
			slnowrk_caly_beid soverwerkuren_caly_beid sreisk_caly_beid ///
			svakbsl_caly_beid svoltijddagen_caly_beid byear gbageboortejaar ///
			gbageboortemaand
		
		************************************************************************
		* Set Population
		************************************************************************
		
		* Age
		keep if age>=21 & age<=65
		
		* Keep only regular employees
		keep if ssoortbaan==4 | ssoortbaan==5 | ssoortbaan==9
		
		/* Drop Uitzendbureaus (since Uitzendkrachten are removed)
		drop if ssect=="52"*/
		
		* Create variable that holds the number of jobs at 31st December 
		* of the calendar year in each organization
		bys org: gen N_org = _N 
		
		// I keep all for now, otherwise risk of artifical missings due to orgs
		// slipping under the 20 mark instead of respondent exit.
		
		************************************************************************
		* Create within-firm wage distribution measure
		************************************************************************
		by org: egen log_real_hwage_ORG = std(log_real_hwage)
		************************************************************************
		* Create overall wage distribution measure (org>20)
		************************************************************************
		egen log_real_hwage_ALL = std(log_real_hwage) if N_org>=20
		
		save "${data}/fullpolis_`year'_processed.dta", replace
	}
	*
	
*********************
*** Merge SBI & GEMHV
*********************

	*Changing variable names over time --> several loops
	
	foreach year of num 2006/2009 {
		use "${data}/fullpolis_`year'_processed.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (SBI2008V`year' GEMHV`year') ///
			keep(master match) nogen
		rename (SBI2008V`year' GEMHV`year') (SBI2008VJJJJ gemhvjjjj)
		order SBI2008VJJJJ gemhvjjjj, after(N_org)
		rename beid sbeid
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_`year'_processed.dta", replace
	}
	*
	foreach year of num 2010/2013 {
		use "${data}/fullpolis_`year'_processed.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (SBI2008V`year' GEMHV`year') ///
			keep(master match) nogen
		rename (SBI2008V`year' GEMHV`year') (SBI2008VJJJJ gemhvjjjj)
		order SBI2008VJJJJ gemhvjjjj, after(N_org)
		rename beid sbeid
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_`year'_processed.dta", replace
	}
	*
	foreach year of num 2014/2018 {
		use "${data}/fullpolis_`year'_processed.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (SBI2008VJJJJ gemhvjjjj) ///
			keep(master match) nogen
		order SBI2008VJJJJ gemhvjjjj, after(N_org)
		rename beid sbeid
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_`year'_processed.dta", replace
	}
	*
	foreach year of num 2019 {
		use "${data}/fullpolis_`year'_processed.dta", replace
		rename sbeid beid
		sort beid
	
		merge m:1 beid using "${betab`year'}", keepusing (sbi2008vjjjj gemhvjjjj) ///
			keep(master match) nogen
		order sbi2008vjjjj gemhvjjjj, after(beid)
		rename beid sbeid
		rename sbi2008vjjjj SBI2008VJJJJ 
	
		sort rinpersoons rinpersoon
	
		save "${data}/fullpolis_`year'_processed.dta", replace
	}
	*	
	
****************************************************************
*** Finalize and reduce variable set
****************************************************************

	foreach year of num 2006/2019 {
		use "${data}/fullpolis_`year'_processed.dta", replace
		keep YEAR rinpersoons rinpersoon sbeid SBI2008VJJJJ gemhvjjjj scaosector ///
			job_start_caly_beid job_end_caly_beid sbasisuren_caly_beid ///
			ssoortbaan scontractsoort spolisdienstverband ft_factor hwage ///
			hwage_bonus real_hwage real_hwage_bonus log_real_hwage ///
			log_real_hwage_bonus age N_org log_real_hwage_ORG ///
			log_real_hwage_ALL
			
		// Sector
		replace scaosector = substr(scaosector,1,1)
		gen sector = real(scaosector)
		drop scaosector
		
		lab def sector_lbl 1"Private" 2 "Subsidized" 3 "State"
		lab val sector sector_lbl
		
		// Industry
		gen SBI2008VJJJJ_sub = substr(SBI2008VJJJJ,1,2)
		gen industry = real(SBI2008VJJJJ_sub)
		drop SBI2008VJJJJ_sub
		recode industry (1/3 = 1) (6/9 = 2) (10/33 = 3) (35 = 4) (36/39 = 5) ///
			(41/43 = 6) (45/47 = 7) (49/53 = 8) (55/56 = 9) (58/63 = 10) ///
			(64/66 = 11) (68 = 12) (69/75 = 13) (77/82 = 14) (84=15) (85 = 16) ///
			(86/88 = 17) (90/93 = 18) (94/96 = 19) (97/98 = 20) (99 = 21)
			
		lab def industry_lbl 1"Agriculture, forestry, and fishing" 2"Mining and quarrying" ///
			3"Manufacturing" 4"Electricity, gas, steam, and air conditioning supply" ///
			5"Water supply; sewerage, waste management and remidiation activities" ///
			6"Construction" 7"Wholesale and retail trade; repair of motorvehicles and motorcycles" ///
			8"Transportation and storage" 9"Accomodation and food service activities" ///
			10"Information and communication" 11"Financial institutions" ///
			12"Renting, buying, and selling of real estate" ///
			13"Consultancy, research and other specialised business services" ///
			14"Renting and leasing of tangible goods and other business support services" ///
			15"Public administration, public services, and compulsory social security" ///
			16"Education" 17"Human health and social work activities" ///
			18"Culture, sports, and recreation" 19"Other service activities" ///
			20"Activities of households as employers" ///
			21"Extraterritorial organizations and bodies" 
		lab val industry industry_lbl	
		
		// Contract duration
		rename scontractsoort temp
		
		lab def temp_lbl 0 "Permanent contract" 1 "Temporary contract"
		lab val temp temp_lbl
		
		// Full-time / Part-time
		rename spolisdienstverband ft_cat
		
		lab def ft_lbl 1 "Full-time" 2 "Part-time"
		lab val ft_cat ft_lbl
		
		// Job type
		rename ssoortbaan jobtype_PLS
		recode jobtype_PLS (9=0) (4=1) (5=2)
		lab var jobtype_PLS "Job Type (SPOLIS)"
		lab def jt_lbl 0 "Standard" 1 "Temp agency worker" 2 "On-call worker" 
		lab val jobtype_PLS jt_lbl
		
		
		* Positioning
		order sector industry SBI2008VJJJJ, after(sbeid)
		order temp ft_cat, before(ft_factor)
		
		save "${data}/fullpolis_`year'_processed.dta", replace
	}
	*
	
*********************************************************
*** Pooling of all Observations
*********************************************************

	foreach year of num 2006/2019 {
		use "${data}/fullpolis_`year'_processed.dta", replace
		tempfile temp`year'
		save "`temp`year''"
	}
	*
	
	append using "`temp2006'" "`temp2007'" "`temp2008'" "`temp2009'" "`temp2010'" ///
		"`temp2011'" "`temp2012'" "`temp2013'" "`temp2014'" "`temp2015'" ///
		"`temp2016'" "`temp2017'" "`temp2018'"
		
	sort YEAR rinpersoons rinpersoon
		
	save "${data}/SPOLIS_core.dta", replace	
	
* --------------------------------------------------------------------------- */
* 3. INITIAL MERGE (DETERMINE ORGANIZATION OF FOCUS)
* ---------------------------------------------------------------------------- *
	
* Merge on YEAR and RIN. This will identify pers-org combis existing in that caly.
* --> Drop Org if survey date is outside of interview time.
* --> Then keep the org per pers with the most hours worked
* --> Then drop all org at N_org<20

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
	
	///////////////////////
	*Step 3: Drop if Orga size <20
	//////////////////////
	drop if N_org<20
	
	sort rinpersoons rinpersoon sbeid

	save "${data}/SAMPLE_init.dta", replace


* --------------------------------------------------------------------------- */
* 4. SECOND MERGE (MATCH ON IDENTIFIED PERS-ORG COMBINIATIONS)
* ---------------------------------------------------------------------------- *

* Merge on RIN and SBEID. This will identify pers-org combis deemed as focus
* --> Keep only exact matches. EBB variables will be continiously filled with 
* the init observation.

	use "${data}/SPOLIS_core.dta", replace
	
	* Merge
	merge m:1 rinpersoons rinpersoon sbeid using "${data}/SAMPLE_init", ///
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
	replace log_real_hwage_ORG=. if N_org<20
	
	sort rinpersoons rinpersoon YEAR
	
	save "${posted}/analysis", replace
	
* --------------------------------------------------------------------------- */
* 5. AKM FIRM FIXED EFFECTS (FIRM QUALITY MEASURE)
* ---------------------------------------------------------------------------- *

	use "${data}/SPOLIS_core.dta", replace
	
	// Reduce number of variables
	keep YEAR rinpersoons rinpersoon sbeid sbasisuren_caly_beid ///
		log_real_hwage age N_org
	
	// Selection 1: Estimation based only on main job
	*Select remaining main jobs based on max nr of hours worked
	duplicates tag YEAR rinpersoons rinpersoon, gen(dupl)
	bys YEAR rinpersoons rinpersoon: egen max_hours = max(sbasisuren_caly_beid)
	drop if sbasisuren_caly_beid!=max_hours & dupl!=0
	egen select = tag(YEAR rinpersoons rinpersoon)
	keep if select==1
	drop dupl max_hours select sbasisuren_caly_beid
	
	// Selection 2: Estimation based only on organizations with at least 10 workers
	// Reduce to organizations with at least 10 workers at one point during 2006-2019
	// This is the population for which Org FE are estimated.
	bys sbeid: egen max_N = max(N_org)
	keep if max_N>=10 & max_N!=.
	drop max_N N_org
	
	// Prepare variables
	egen rin = group(rinpersoons rinpersoon)
	egen beid = group(sbeid)
	
	drop rinpersoons rinpersoon
	
	// Within organization wage growth
	bys rin: gen n = _n
	bys rin: gen growth = log_real_hwage[_n]-log_real_hwage[_n-1]
	bys rin: replace growth = 0 if beid[_n]!=beid[_n-1] & n!=1
	drop n
	
	reghdfe, compile
	ftools, compile
	
	// AKM Decomposition (Wage levels)
	reghdfe log_real_hwage c.age##c.age i.YEAR, absorb(i_fe = i.rin j_fe = i.beid) ///
		groupvar(cs) residuals(res) 
	predict xb if e(sample)==1, xb
	
	// Save estimates
	putexcel set "${tables}/akm.xlsx", sheet("reghdfe 2006-2019") replace
	putexcel A1 = ("n") A2 = ("i") A3 = ("j") A4 = ("R2") A5 = ("sd_i") ///
		A6 = ("sd_j") A7 = ("sd_xb") A8 = ("sd_res") A9 = ("cov_ij") ///
		A10 = ("cov_ixb") A11 = ("cov_jxb")
	putexcel B1 = (e(N)) B4 = (e(r2))
	distinct rin if e(sample)==1
	putexcel B2 = (r(ndistinct))
	distinct beid if e(sample)==1
	putexcel B3 = (r(ndistinct))
	sum i_fe
	putexcel B5 = (r(sd))
	sum j_fe
	putexcel B6 = (r(sd))
	sum xb
	putexcel B7 = (r(sd))
	sum res
	putexcel B8 = (r(sd))
	corr i_fe j_fe, cov
	putexcel B9 = (r(cov_12))
	corr i_fe xb, cov
	putexcel B10 = (r(cov_12))
	corr j_fe xb, cov
	putexcel B11 = (r(cov_12))
	
	// AKM Decomposition (Wage growth)
	reghdfe growth c.age##c.age i.YEAR, absorb(i_g_fe = i.rin j_g_fe = i.beid) ///
		groupvar(cs_g) residuals(res_g) 
	predict xb_g if e(sample)==1, xb
	
	// Save estimates
	putexcel set "${tables}/akm_growth.xlsx", sheet("reghdfe 2007-2019") replace
	putexcel A1 = ("n") A2 = ("i") A3 = ("j") A4 = ("R2") A5 = ("sd_i") ///
		A6 = ("sd_j") A7 = ("sd_xb") A8 = ("sd_res") A9 = ("cov_ij") ///
		A10 = ("cov_ixb") A11 = ("cov_jxb")
	putexcel B1 = (e(N)) B4 = (e(r2))
	distinct rin if e(sample)==1
	putexcel B2 = (r(ndistinct))
	distinct beid if e(sample)==1
	putexcel B3 = (r(ndistinct))
	sum i_g_fe
	putexcel B5 = (r(sd))
	sum j_g_fe
	putexcel B6 = (r(sd))
	sum xb_g
	putexcel B7 = (r(sd))
	sum res_g
	putexcel B8 = (r(sd))
	corr i_g_fe j_g_fe, cov
	putexcel B9 = (r(cov_12))
	corr i_g_fe xb_g, cov
	putexcel B10 = (r(cov_12))
	corr j_g_fe xb_g, cov
	putexcel B11 = (r(cov_12))
	
	/////////////////////////
	// Saving organization FE
	/////////////////////////
	preserve
	
	egen tag = tag(sbeid) if e(sample)==1
	keep if tag==1
	keep sbeid j_fe j_g_fe
	
	// Unrestricted binning (across all organizations with N>=10)
	* Generate categorical firm quality measurement
	xtile firmqual = j_fe, n(5)
	lab var firmqual "Firm Pay Quality"
	lab def firmqual_lbl 1 "Very Low-paying" 2 "Low-paying" ///
		3 "Average Paying" 4 "High-paying" 5 "Very High-paying"
	lab val firmqual firmqual_lbl
	
	xtile firmqual_growth = j_g_fe, n(5)
	lab var firmqual_growth "Firm Pay Growth Quality"
	lab def firmqualg_lbl 1 "Very Low Growth" 2 "Low Growth" ///
		3 "Average Growth" 4 "High Growth" 5 "Very High Growth"
	lab val firmqual_growth firmqualg_lbl
	
	save "${posted}/j_fe.dta", replace
	
	restore
	
	*Merge org-level variables to Analyis File
	use "${posted}/analysis", replace
	
	merge m:1 sbeid using "${posted}/j_fe.dta", keepusing(j_fe firmqual ///
		j_g_fe firmqual_growth) nogen
	order j_fe firmqual j_g_fe firmqual_growth, after(sbeid)
	drop if counter==.
	sort rinpersoons rinpersoon YEAR
	
	save "${posted}/analysis", replace

* --------------------------------------------------------------------------- */
* 6. AUXILIARY FILES
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
	
	// Set sample file for robustness check (unrestricted wage growth)
	keep rinpersoons rinpersoon SURVEY_Y svyw gender migback hhchild oesch ///
		ed isco3 firmqual sbeid
	sort rinpersoons rinpersoon SURVEY_Y
	egen pickone = tag(rinpersoons rinpersoon)
	keep if pickone==1
	drop pickone
	
	save "${data}/analytic_sample.dta", replace
	
	* Reduce Full Polis file to analytic sample
	use "${data}/SPOLIS_core.dta", replace
	
	* Keep only workers of the analytical sample in unrestricted POLIS file
	merge m:1 rinpersoons rinpersoon using "${data}/analytic_sample", ///
		nogen keep(match) keepusing(SURVEY_Y svyw gender migback hhchild ///
		oesch ed isco3 firmqual)
	sort rinpersoons rinpersoon YEAR
	
	// Select main job based on max nr of hours worked
	duplicates tag YEAR rinpersoons rinpersoon, gen(dupl)
	bys YEAR rinpersoons rinpersoon: egen max_hours = max(sbasisuren_caly_beid)
	drop if sbasisuren_caly_beid!=max_hours & dupl!=0
	// 388 Duplicates remain (same number of hours at two different orgs)
	egen select = tag(YEAR rinpersoons rinpersoon)
	keep if select==1
	drop dupl max_hours select
	
	*Generate counter variable
	gen counter = YEAR-SURVEY_Y
	keep if counter>=0 & counter<=6
		
	sort rinpersoons rinpersoon counter
	
	save "${posted}/analysis_unrestricted.dta", replace
	
	// Create file for organization fixed effects diagnostics
	preserve
	use "${posted}/j_fe.dta", replace
	merge 1:m sbeid using "${data}/analytic_sample.dta", keepusing(SURVEY_Y)
	egen pickone=tag(sbeid)
	keep if pickone==1
	gen sample=0
	replace sample=1 if _merge==3
	drop pickone SURVEY_Y _merge
	
	save "${posted}/j_fe_detail.dta", replace
	restore


* --------------------------------------------------------------------------- */
* 7. CLOSE LOG FILE
* ---------------------------------------------------------------------------- *

	log close
