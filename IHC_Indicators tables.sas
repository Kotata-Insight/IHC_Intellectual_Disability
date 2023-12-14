** Run the age standardisation and produce output;
%macro temp_data(domain=);
proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table temp_&domain. as
	select *,put(apc_age_in_years_nbr,agegroups.) as age10 from connection to odbc
	(select a.*,b.*
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018_res a inner join idi_sandpit."DL-MAA2022-54".&domain. b
	on a.snz_uid=b.snz_uid)
	order by apc_age_in_years_nbr,idd_id;
	disconnect from odbc;
quit;
%mend temp_data;

%temp_data(domain=safety);
%temp_data(domain=inc_cons_and_wealth);
%temp_data(domain=cultural_cap_belong);
%temp_data(domain=work_care_volun);
%temp_data(domain=family_friends);
%temp_data(domain=know_and_skill);
%temp_data(domain=housing);
%temp_data(domain=health);

data temp_id;
	set temp_safety;
run;

%macro run_group(subset=,subpop=);
%macro run_indicator(domain=,measure=,binary=,minage=,maxage=);

/*%let domain=safety;
%let measure=s3_victim;
%let binary=Y;
%let minage=99;
%let maxage=99;
*/

** Standardise to the June 2018 NZ estimated resident population in 5 year age bands;
%if &measure. ne idd_id %then %do;
/*proc sort data=temp_&domain.;
	by idd_id apc_age_in_years_nbr;
run;*/
proc means data=temp_&domain. noprint;
	var &measure.;
	by apc_age_in_years_nbr idd_id;
	output out=&measure. sum=;
	format apc_age_in_years_nbr age5yr.;
	where (&minage.=99 or apc_age_in_years_nbr>=&minage.) and (&maxage.=99 or apc_age_in_years_nbr<=&maxage.) and &measure. ne .
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
run;
%end;

/*proc sort data=temp_&domain.;
	by apc_age_in_years_nbr;
run;*/

proc means data=temp_&domain. noprint;
	var &measure.;
	by apc_age_in_years_nbr;
	output out=&measure.2 sum=;
	format apc_age_in_years_nbr age5yr.;
	where (&minage.=99 or apc_age_in_years_nbr>=&minage.) and (&maxage.=99 or apc_age_in_years_nbr<=&maxage.) and &measure. ne .
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
run;

%if &measure. ne idd_id %then %do;
data &measure.b;
	set &measure.;
	drop _type_ apc_age_in_years_nbr;
	rename _freq_=count;
	age_5yr=put(apc_age_in_years_nbr,age5yr.);
run;
%end;

data &measure.2b;
	set &measure.2;
	drop _type_ apc_age_in_years_nbr;
	rename _freq_=count;
	age_5yr=put(apc_age_in_years_nbr,age5yr.);
	if _freq_=. then _freq_=0;
run;

%macro stdpop(std);
%if &std.=NZ %then %do; %let popdata=age5yrpop_jun2018; %end;
%else %if &std.=WHO %then %do; %let popdata=who_age5yrpop_jun2018; %end;
%put std=&std. pop=&popdata.;

ods results off;
%if &measure. ne idd_id %then %do;
proc stdrate data=&measure.b
				refdata=&popdata.
				method=direct
				stat=rate(mult=1)
				effect
				/*plots(only)=(dist effect)*/;
	population group=idd_id event=&measure. total=count;
	reference total=popn;
	strata age_5yr/effect;
	ods output StdRate=asr_&measure. effect=effect_&measure.;
run;
%end;

proc stdrate data=&measure.2b
				refdata=&popdata.
				method=direct
				stat=rate(mult=1)
				/*plots(only)=(dist effect)*/;
	population event=&measure. total=count;
	reference total=popn;
	strata age_5yr;
	ods output StdRate=asr_&measure.2;
run;
ods results on;

%if &measure. ne idd_id %then %do;
data asr_&measure.&std.;
	set asr_&measure.;
	drop Method RateMult ExpectedEvents RefPopTime type rate comprate;
	rename ObservedEvents=sum_ind PopTime=population cruderate=measure stdrate=ASR;
run;
%end;

data asr_&measure.2&std.;
	merge asr_&measure.2 %if &measure. ne idd_id %then %do; effect_&measure.; %end; ;
	drop Method RateMult ExpectedEvents RefPopTime type rate comprate logratio;
	rename ObservedEvents=sum_ind PopTime=population cruderate=measure stdrate=ASR;
run;
%mend stdpop;

%stdpop(NZ);
%stdpop(WHO);

%if &measure. ne idd_id %then %do;
data asr_&measure.;
	merge asr_&measure.NZ asr_&measure.WHO(rename=(ASR=ASR_WHO StdErr=StdErr_WHO LowerCL=LowerCL_WHO UpperCL=UpperCL_WHO));
run;
%end;

data asr_&measure.2;
	merge asr_&measure.2NZ asr_&measure.2WHO(rename=(ASR=ASR_WHO StdErr=StdErr_WHO LowerCL=LowerCL_WHO UpperCL=UpperCL_WHO %if &measure. ne idd_id %then %do; RateRatio=RateRatio_WHO Z=Z_WHO ProbZ=ProbZ_WHO %end;));
	RateRatio=1/RateRatio; RateRatio_WHO=1/RateRatio_WHO;
run;

data &measure._&minage.&maxage.;
	length domain ind_var $ 20 indicator $ 90 subpop $ 5 agerange $ 6;
	label id_ind='Intellectual disability';
	domain="&domain.";
	%if &measure.=ff5_soleparent %then %do;
		domain='family_friends';
	%end;
	ind_var="&measure.";
	subpop="&subpop.";
	agerange="&minage.-&maxage.";
	indicator=put(ind_var,$ind.);
	binary="&binary.";
	set %if &measure. ne idd_id %then %do; asr_&measure. %end; asr_&measure.2;
	drop idd_id;
	id_ind=put(idd_id,ynt.);
run;

** Need to random round denominator and random round numerator if it is binary;
data &measure._&minage.&maxage._con;
	set &measure._&minage.&maxage.;
	if population<6 then do;
		population=.;
	end;
	if sum_ind<6 and "&binary."='Y' then do;
		sum_ind=.;
		stderr=.;
		LowerCL=.;
		UpperCL=.;
	end;
run;

%rr3(&measure._&minage.&maxage._con,&measure._&minage.&maxage._con,population);
%if &binary.=Y %then %do;
%rr3(&measure._&minage.&maxage._con,&measure._&minage.&maxage._con,sum_ind);
%end;

data &measure._&minage.&maxage._con;
	set &measure._&minage.&maxage._con;
	measure=sum_ind/population;
run;

** Now do breakdowns by 10-year age band and ID;
%if &measure. ne idd_id %then %do;
%let measure=s3_victim;
proc summary data=temp_&domain. noprint nway;
	var &measure.;
	class age10 idd_id;
	output out=a_&measure.(drop=_type_) sum=sum_ind;
	format apc_age_in_years_nbr age5yr.;
	where (&minage.=99 or apc_age_in_years_nbr>=&minage.) and (&maxage.=99 or apc_age_in_years_nbr<=&maxage.) and &measure. ne .
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
run;

data a_&measure._&minage.&maxage.;
	length domain ind_var $ 20 indicator $ 90 subpop $ 5 agerange $ 6;
	label id_ind='Intellectual disability';
	domain="&domain.";
	%if &measure.=ff5_soleparent %then %do;
		domain='family_friends';
	%end;
	ind_var="&measure.";
	subpop="&subpop.";
	agerange="&minage.-&maxage.";
	indicator=put(ind_var,$ind.);
	binary="&binary.";
	set a_&measure.;
	drop idd_id;
	rename _freq_=population;
	id_ind=put(idd_id,ynt.);
run;

** Need to random round denominator and random round numerator if it is binary;
data a_&measure._&minage.&maxage._con;
	set a_&measure._&minage.&maxage.;
	if population<6 then do;
		population=.;
	end;
	if sum_ind<6 and "&binary."='Y' then do;
		sum_ind=.;
	end;
run;

%rr3(a_&measure._&minage.&maxage._con,a_&measure._&minage.&maxage._con,population);
%if &binary.=Y %then %do;
%rr3(a_&measure._&minage.&maxage._con,a_&measure._&minage.&maxage._con,sum_ind);
%end;

%end;

%mend run_indicator;

/******************** OVERALL ID RATE *****************************/

%run_indicator(domain=id,measure=idd_id,binary=Y,minage=00,maxage=99);

/******************** SAFETY *****************************/

%run_indicator(domain=safety,measure=s3_victim,binary=N,minage=00,maxage=14);
%run_indicator(domain=safety,measure=s3_victim,binary=N,minage=15,maxage=99);
%run_indicator(domain=safety,measure=victim_ind,binary=Y,minage=00,maxage=14);
%run_indicator(domain=safety,measure=victim_ind,binary=Y,minage=15,maxage=99);
%run_indicator(domain=safety,measure=s5_placement,binary=Y,minage=00,maxage=14);
%run_indicator(domain=safety,measure=s6_fam_violence,binary=Y,minage=00,maxage=14);
%run_indicator(domain=safety,measure=s7_childplacement,binary=Y,minage=15,maxage=64);

data safety_indicators;
	set s3_victim_0014 s3_victim_1599 victim_ind_0014 victim_ind_1599 
		s5_placement_0014 s6_fam_violence_0014 s7_childplacement_1564;
run;

data safety_indicators_con;
	set s3_victim_0014_con s3_victim_1599_con victim_ind_0014_con victim_ind_1599_con
		s5_placement_0014_con s6_fam_violence_0014_con s7_childplacement_1564_con;
run;

data safety_ageten;
	set a_s3_victim_0014 a_s3_victim_1599 a_victim_ind_0014 a_victim_ind_1599
		s5_placement_0014 a_s6_fam_violence_0014 a_s7_childplacement_1564;
run;

data safety_ageten_con;
	set a_s3_victim_0014_con a_s3_victim_1599_con a_victim_ind_0014_con a_victim_ind_1599_con
		s5_placement_0014_con a_s6_fam_violence_0014_con a_s7_childplacement_1564_con;
run;

/******************** INCOME CONSUMPTION AND WEALTH *****************************/

%run_indicator(domain=inc_cons_and_wealth,measure=icw1_income,binary=N,minage=18,maxage=64);
%run_indicator(domain=inc_cons_and_wealth,measure=icw2_equiv_hh_inc,binary=N,minage=00,maxage=14);
%run_indicator(domain=inc_cons_and_wealth,measure=icw2_equiv_hh_inc,binary=N,minage=15,maxage=99);
%run_indicator(domain=inc_cons_and_wealth,measure=icw3_nzdep18,binary=N,minage=00,maxage=14);
%run_indicator(domain=inc_cons_and_wealth,measure=icw3_nzdep18,binary=N,minage=15,maxage=99);
%run_indicator(domain=inc_cons_and_wealth,measure=icw4_internet,binary=Y,minage=00,maxage=99);
%run_indicator(domain=inc_cons_and_wealth,measure=lowinc_50,binary=Y,minage=00,maxage=14);
%run_indicator(domain=inc_cons_and_wealth,measure=lowinc_50,binary=Y,minage=15,maxage=99);
%run_indicator(domain=inc_cons_and_wealth,measure=lowinc_60,binary=Y,minage=00,maxage=14);
%run_indicator(domain=inc_cons_and_wealth,measure=lowinc_60,binary=Y,minage=15,maxage=99);
%run_indicator(domain=inc_cons_and_wealth,measure=highdep_dec,binary=Y,minage=00,maxage=14);
%run_indicator(domain=inc_cons_and_wealth,measure=highdep_quint,binary=Y,minage=00,maxage=14);
%run_indicator(domain=inc_cons_and_wealth,measure=highdep_dec,binary=Y,minage=15,maxage=99);
%run_indicator(domain=inc_cons_and_wealth,measure=highdep_quint,binary=Y,minage=15,maxage=99);

data icw_indicators;
	set icw1_income_1864 icw2_equiv_hh_inc_0014 icw2_equiv_hh_inc_1599 
		icw3_nzdep18_0014 icw3_nzdep18_1599 icw4_internet_0099
		lowinc_50_0014 lowinc_50_1599 lowinc_60_0014 lowinc_60_1599
		highdep_dec_0014 highdep_dec_1599 highdep_quint_0014 highdep_quint_1599;
run;

data icw_indicators_con;
	set icw1_income_1864_con icw2_equiv_hh_inc_0014_con icw2_equiv_hh_inc_1599_con 
		icw3_nzdep18_0014_con icw3_nzdep18_1599_con icw4_internet_0099_con 
		lowinc_50_0014_con lowinc_50_1599_con lowinc_60_0014_con lowinc_60_1599_con 
		highdep_dec_0014_con highdep_dec_1599_con highdep_quint_0014_con highdep_quint_1599_con ;
run;

data icw_ageten;
	set a_icw1_income_1864 a_icw2_equiv_hh_inc_0014 a_icw2_equiv_hh_inc_1599 
		a_icw3_nzdep18_0014 a_icw3_nzdep18_1599 a_icw4_internet_0099
		a_lowinc_50_0014 a_lowinc_50_1599 a_lowinc_60_0014 a_lowinc_60_1599
		a_highdep_dec_0014 a_highdep_dec_1599 a_highdep_quint_0014 a_highdep_quint_1599;
run;

data icw_ageten_con;
	set a_icw1_income_1864_con a_icw2_equiv_hh_inc_0014_con a_icw2_equiv_hh_inc_1599_con 
		a_icw3_nzdep18_0014_con a_icw3_nzdep18_1599_con a_icw4_internet_0099_con 
		a_lowinc_50_0014_con a_lowinc_50_1599_con a_lowinc_60_0014_con a_lowinc_60_1599_con 
		a_highdep_dec_0014_con a_highdep_dec_1599_con a_highdep_quint_0014_con a_highdep_quint_1599_con ;
run;


/******************** CULTURAL CAPABILITY AND BELONGING *****************************/

%run_indicator(domain=cultural_cap_belong,measure=ccb1_incarcerated,binary=Y,minage=18,maxage=99);
%run_indicator(domain=cultural_cap_belong,measure=ccb2_convictions,binary=Y,minage=18,maxage=99);
%run_indicator(domain=cultural_cap_belong,measure=ccb3_travel,binary=Y,minage=00,maxage=99);

data ccb_indicators;
	set ccb1_incarcerated_1899 ccb2_convictions_1899 ccb3_travel_0099;
run;

data ccb_indicators_con;
	set ccb1_incarcerated_1899_con ccb2_convictions_1899_con ccb3_travel_0099_con;
run;

data ccb_ageten;
	set a_ccb1_incarcerated_1899 a_ccb2_convictions_1899 a_ccb3_travel_0099;
run;

data ccb_ageten_con;
	set a_ccb1_incarcerated_1899_con a_ccb2_convictions_1899_con a_ccb3_travel_0099_con;
run;

/******************** HEALTH *****************************/

%run_indicator(domain=health,measure=h2_chd ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h2_cvd ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h3_copd1 ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h3_copd2 ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h4_diabetes2 ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h6_cancer2 ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h10_injury ,binary=N,minage=00,maxage=99);
%run_indicator(domain=health,measure=h11_dent_hosp ,binary=N,minage=00,maxage=99);
%run_indicator(domain=health,measure=h12_mooddisorder,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h13_psychosis ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h14_dementia ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h14_dementia2 ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h15_mentlhlth ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h16_pho_enrol ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h17_careplus ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h18_consult_3m,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h19_consult_1y ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h20_consult_2y ,binary=Y,minage=00,maxage=99);
%run_indicator(domain=health,measure=h21_countpharma,binary=N,minage=00,maxage=99);
%run_indicator(domain=health,measure=h27_emergency ,binary=N,minage=00,maxage=99);
%run_indicator(domain=health,measure=h28_pah ,binary=N,minage=00,maxage=99);
%run_indicator(domain=health,measure=h30_healthcosts ,binary=N,minage=00,maxage=99);

data health_indicators;
	set h2_chd_0099 h2_cvd_0099 h3_copd1_0099 h3_copd2_0099 h4_diabetes_0099 h4_diabetes2_0099 h6_cancer_0099 h6_cancer2_0099 h10_injury_0099 
	h11_dent_hosp_0099 h12_mooddisorder_0099 h13_psychosis_0099 h14_dementia_0099 h14_dementia2_0099 h15_mentlhlth_0099 h16_pho_enrol_0099 
	h17_careplus_0099 h18_consult_3m h19_consult_1y_0099 h20_consult_2y_0099 h27_emergency_0099 h28_pah_0099 h30_healthcosts_0099;
run;

data health_indicators_con;
	set h2_chd_0099_con h2_cvd_0099_con h3_copd1_0099_con h3_copd2_0099_con h4_diabetes_0099_con h4_diabetes2_0099_con h6_cancer_0099_con h6_cancer2_0099_con h10_injury_0099_con 
	h11_dent_hosp_0099_con h12_mooddisorder_0099_con h13_psychosis_0099_con h14_dementia_0099_con h14_dementia2_0099_con h15_mentlhlth_0099_con h16_pho_enrol_0099_con 
	h17_careplus_0099_con h18_consult_3m_con h19_consult_1y_0099_con h20_consult_2y_0099_con h27_emergency_0099_con h28_pah_0099_con h30_healthcosts_0099_con;
run;

data health_ageten;
	set a_h2_chd_0099 a_h2_cvd_0099 a_h3_copd1_0099 a_h3_copd2_0099 a_h4_diabetes_0099 a_h4_diabetes2_0099 a_h6_cancer_0099 a_h6_cancer2_0099 a_h10_injury_0099
		a_h11_dent_hosp_0099 a_h12_mooddisorder_0099 a_h13_psychosis_0099 a_h14_dementia_0099 a_h14_dementia2_0099 a_h15_mentlhlth_0099 a_h16_pho_enrol_0099
		a_h17_careplus_0099 a_h18_consult_3m a_h19_consult_1y_0099 a_h20_consult_2y_0099 a_h27_emergency_0099 a_h28_pah_0099 a_h30_healthcosts_0099;
run;

data health_ageten_con;
	set a_h2_chd_0099_con a_h2_cvd_0099_con a_h3_copd1_0099_con a_h3_copd2_0099_con a_h4_diabetes_0099_con a_h4_diabetes2_0099_con a_h6_cancer_0099_con a_h6_cancer2_0099_con a_h10_injury_0099_con
		a_h11_dent_hosp_0099_con a_h12_mooddisorder_0099_con a_h13_psychosis_0099_con a_h14_dementia_0099_con a_h14_dementia2_0099_con a_h15_mentlhlth_0099_con a_h16_pho_enrol_0099_con
		a_h17_careplus_0099_con a_h18_consult_3m_con a_h19_consult_1y_0099_con a_h20_consult_2y_0099_con a_h27_emergency_0099_con a_h28_pah_0099_con a_h30_healthcosts_0099_con;
run;

/******************** WORK CARE AND VOLUNTEERING *****************************/

%run_indicator(domain=work_care_volun,measure=wcv1_employed,binary=Y,minage=18,maxage=64);
%run_indicator(domain=work_care_volun,measure=wcv2_yneet,binary=Y,minage=15,maxage=24);
%run_indicator(domain=work_care_volun,measure=youth_study,binary=Y,minage=15,maxage=24);
%run_indicator(domain=work_care_volun,measure=youth_work,binary=Y,minage=15,maxage=24);
%run_indicator(domain=work_care_volun,measure=youth_wkstudy,binary=Y,minage=15,maxage=24);
%run_indicator(domain=work_care_volun,measure=wcv3_benefit,binary=Y,minage=18,maxage=64);
%run_indicator(domain=work_care_volun,measure=wcv4_parentemp,binary=Y,minage=00,maxage=14);
%run_indicator(domain=work_care_volun,measure=wcv5_parentcare,binary=Y,minage=00,maxage=14);
%run_indicator(domain=work_care_volun,measure=wcv6_volunteer,binary=Y,minage=15,maxage=99);
%run_indicator(domain=work_care_volun,measure=care_child,binary=Y,minage=15,maxage=99);
%run_indicator(domain=work_care_volun,measure=care_illdis,binary=Y,minage=15,maxage=99);
%run_indicator(domain=work_care_volun,measure=other_helpvol,binary=Y,minage=15,maxage=99);
%run_indicator(domain=work_care_volun,measure=ff5_soleparent,binary=Y,minage=00,maxage=14);

data wcv_indicators;
	set wcv1_employed_1864 wcv2_yneet_1524 youth_study_1524 youth_work_1524 youth_wkstudy_1524 wcv3_benefit_1864
		wcv4_parentemp_0014 wcv5_parentcare_0014 wcv6_volunteer_1599 care_child_1599 care_illdis_1599 other_helpvol_1599 ff5_soleparent_0014;
run;

data wcv_indicators_con;
	set wcv1_employed_1864_con wcv2_yneet_1524_con youth_study_1524_con youth_work_1524_con youth_wkstudy_1524_con wcv3_benefit_1864_con
		wcv4_parentemp_0014_con wcv5_parentcare_0014_con wcv6_volunteer_1599_con care_child_1599_con care_illdis_1599_con other_helpvol_1599_con ff5_soleparent_0014_con;
run;

data wcv_ageten;
	set a_wcv1_employed_1864 a_wcv2_yneet_1524 a_youth_study_1524 a_youth_work_1524 a_youth_wkstudy_1524 a_wcv3_benefit_1864
		a_wcv4_parentemp_0014 a_wcv5_parentcare_0014 a_wcv6_volunteer_1599 a_care_child_1599 a_care_illdis_1599 a_other_helpvol_1599 a_ff5_soleparent_0014;
run;

data wcv_ageten_con;
	set a_wcv1_employed_1864_con a_wcv2_yneet_1524_con a_youth_study_1524_con a_youth_work_1524_con a_youth_wkstudy_1524_con a_wcv3_benefit_1864_con
		a_wcv4_parentemp_0014_con a_wcv5_parentcare_0014_con a_wcv6_volunteer_1599_con a_care_child_1599_con a_care_illdis_1599_con a_other_helpvol_1599_con a_ff5_soleparent_0014_con;
run;

/*************************** FAMILY AND FRIENDS *********************************/

%run_indicator(domain=family_friends,measure=ff1_parent,binary=Y,minage=18,maxage=99);
%run_indicator(domain=family_friends,measure=ff2_marr_civil,binary=Y,minage=18,maxage=99);
%run_indicator(domain=family_friends,measure=ff3_divorce,binary=Y,minage=18,maxage=99);
%run_indicator(domain=family_friends,measure=ff4_living_parent,binary=Y,minage=00,maxage=17);
%run_indicator(domain=family_friends,measure=ff4_living_parent,binary=Y,minage=18,maxage=99);
%run_indicator(domain=family_friends,measure=ff6_teenparent,binary=Y,minage=00,maxage=44);

data ff_indicators;
	set ff1_parent_1899 ff2_marr_civil_1899 ff3_divorce_1899 ff4_living_parent_0017 ff4_living_parent_1899 ff6_teenparent_0044;
run;

data ff_indicators_con;
	set ff1_parent_1899_con ff2_marr_civil_1899_con ff3_divorce_1899_con ff4_living_parent_0017_con ff4_living_parent_1899_con ff6_teenparent_0044_con ;
run;

data ff_ageten;
	set a_ff1_parent_1899 a_ff2_marr_civil_1899 a_ff3_divorce_1899 a_ff4_living_parent_0017 a_ff4_living_parent_1899 a_ff6_teenparent_0044;
run;

data ff_ageten_con;
	set a_ff1_parent_1899_con a_ff2_marr_civil_1899_con a_ff3_divorce_1899_con a_ff4_living_parent_0017_con a_ff4_living_parent_1899_con a_ff6_teenparent_0044_con;
run;

/*************************** KNOWLEDGE AND SKILLS *********************************/

%run_indicator(domain=know_and_skill,measure=ks1_ece,binary=Y,minage=05,maxage=14);
%run_indicator(domain=know_and_skill,measure=ks1_ece2,binary=Y,minage=03,maxage=04);
%run_indicator(domain=know_and_skill,measure=ks2_school,binary=Y,minage=05,maxage=17);
%run_indicator(domain=know_and_skill,measure=special_school,binary=Y,minage=05,maxage=17);
%run_indicator(domain=know_and_skill,measure=ks3_high_qual2,binary=Y,minage=18,maxage=99);
%run_indicator(domain=know_and_skill,measure=high_qual4,binary=Y,minage=18,maxage=99);
%run_indicator(domain=know_and_skill,measure=high_qual7,binary=Y,minage=18,maxage=99);
%run_indicator(domain=know_and_skill,measure=noqual,binary=Y,minage=18,maxage=99);
%run_indicator(domain=know_and_skill,measure=ks4_licence,binary=Y,minage=18,maxage=99);

data ks_indicators;
	set ks1_ece_0514 ks1_ece2_0304 ks2_school_0517 special_school_0517 ks3_high_qual2_1899 high_qual4_1899 high_qual7_1899 noqual_1899 ks4_licence_1899;
run;

data ks_indicators_con;
	set ks1_ece_0514_con ks1_ece2_0304_con ks2_school_0517_con special_school_0517_con ks3_high_qual2_1899_con high_qual4_1899_con high_qual7_1899_con
		noqual_1899_con ks4_licence_1899_con;
run;

data ks_ageten;
	set a_ks1_ece_0514 a_ks1_ece2_0304 a_ks2_school_0517 a_special_school_0517 a_ks3_high_qual2_1899 a_high_qual4_1899 a_high_qual7_1899 a_noqual_1899 a_ks4_licence_1899;
run;

data ks_ageten_con;
	set a_ks1_ece_0514_con a_ks1_ece2_0304_con a_ks2_school_0517_con a_special_school_0517_con a_ks3_high_qual2_1899_con a_high_qual4_1899_con a_high_qual7_1899_con
		a_noqual_1899_con a_ks4_licence_1899_con;
run;

/****************************** HOUSING ****************************************/

data temp_housing;
set temp_housing;
rename h3_mouldy_damp=hs3_mouldy_damp h4_crowded=hs4_crowded;
run;

%run_indicator(domain=housing,measure=hs2_transience,binary=N,minage=00,maxage=99);
%run_indicator(domain=housing,measure=hs3_mouldy_damp,binary=Y,minage=00,maxage=99);
%run_indicator(domain=housing,measure=hs4_crowded,binary=Y,minage=00,maxage=99);

data hs_indicators;
	set hs2_transience_0099 hs3_mouldy_damp_0099 hs4_crowded_0099;
run;

data hs_indicators_con;
	set hs2_transience_0099_con hs3_mouldy_damp_0099_con hs4_crowded_0099_con;
run;

data hs_ageten;
	set a_hs2_transience_0099 a_hs3_mouldy_damp_0099 a_hs4_crowded_0099;
run;

data hs_ageten_con;
	set a_hs2_transience_0099_con a_hs3_mouldy_damp_0099_con a_hs4_crowded_0099_con;
run;

/**************************** BRING TOGETHER ****************************/
data project.all_indicators&subpop.;
	set idd_id_0099 health_indicators ccb_indicators icw_indicators safety_indicators wcv_indicators ff_indicators ks_indicators hs_indicators;
run;

data project.all_indicators_con&subpop.;
	set idd_id_0099_con health_indicators_con ccb_indicators_con icw_indicators_con safety_indicators_con wcv_indicators_con ff_indicators_con ks_indicators_con  hs_indicators;
run;

data project.all_ageten&subpop.;
	set health_ageten ccb_ageten icw_ageten safety_ageten wcv_ageten ff_ageten ks_ageten hs_ageten;
run;

data project.all_ageten_con&subpop.;
	set health_ageten_con ccb_ageten_con icw_ageten_con safety_ageten_con wcv_ageten_con ff_ageten_con ks_ageten_con  hs_ageten;
run;

proc datasets lib=work;
	delete effect: asr: ccb: icw: sy: ff: ks: hs: wcv: high: youth: low: no: oth: spec: health:;
run;
%mend run_group;

options nonotes;
%run_group(subset=,subpop=);
%run_group(subset=snz_sex_gender_code='1',subpop=sexM);
%run_group(subset=snz_sex_gender_code='2',subpop=sexF);
%run_group(subset=apc_ethnicity_grp1_nbr=1,subpop=ethE);
%run_group(subset=apc_ethnicity_grp2_nbr=1,subpop=ethM);
%run_group(subset=apc_ethnicity_grp3_nbr=1,subpop=ethP);
%run_group(subset=apc_ethnicity_grp4_nbr=1,subpop=ethA);
** Commented out Middle Eastern and other ethnicity as groups are too small to calculate ASRs etc;
/*%run_group(subset=apc_ethnicity_grp5_nbr=1,subpop=ethME);
%run_group(subset=apc_ethnicity_grp6_nbr=1,subpop=ethO);*/
%run_group(subset=idd_downs=1,subpop=downs);
%run_group(subset=idd_adhd=1,subpop=adhd);
%run_group(subset=idd_asd=1,subpop=asd);
%run_group(subset=rss_rcs=1,subpop=res);
%run_group(subset=rss_rcs=0,subpop=res0);
options notes;

data all_indicators(drop=Method RateMult ObservedEvents PopTime CrudeRate ExpectedEvents RefPopTime StdRate Type);
	set project.all_indicators project.all_indicatorssexM project.all_indicatorssexF project.all_indicatorsethE project.all_indicatorsethM 
		project.all_indicatorsethP project.all_indicatorsethA /*project.all_indicatorsethME project.all_indicatorsethO project.all_indicatorsdowns*/
		project.all_indicatorsadhd project.all_indicatorsasd project.all_indicatorsres project.all_indicatorsres0;
run;

data all_indicators_con(drop=Method RateMult ObservedEvents PopTime CrudeRate ExpectedEvents RefPopTime StdRate Type);
	set project.all_indicators_con project.all_indicators_consexM project.all_indicators_consexF project.all_indicators_conethE project.all_indicators_conethM 
		project.all_indicators_conethP project.all_indicators_conethA /*project.all_indicators_conethME project.all_indicators_conethO project.all_indicators_condowns*/
		project.all_indicators_conadhd project.all_indicators_conasd project.all_indicators_conres project.all_indicators_conres0;
run;

data all_ageten(drop=Method RateMult ObservedEvents PopTime CrudeRate ExpectedEvents RefPopTime StdRate Type);
	set project.all_ageten project.all_agetensexM project.all_agetensexF project.all_agetenethE project.all_agetenethM 
		project.all_agetenethP project.all_agetenethA /*project.all_agetenethME project.all_agetenethO project.all_agetendowns*/
		project.all_agetenadhd project.all_agetenasd project.all_agetenres project.all_agetenres0;
run;

data all_ageten_con(drop=Method RateMult ObservedEvents PopTime CrudeRate ExpectedEvents RefPopTime StdRate Type);
	set project.all_ageten_con project.all_ageten_consexM project.all_ageten_consexF project.all_ageten_conethE project.all_ageten_conethM 
		project.all_ageten_conethP project.all_ageten_conethA /*project.all_ageten_conethME project.all_ageten_conethO project.all_ageten_condowns*/
		project.all_ageten_conadhd project.all_ageten_conasd project.all_ageten_conres project.all_ageten_conres0;
run;


proc datasets lib=work;
	modify all_indicators;
	attrib _all_ label='';
run;

proc datasets lib=work;
	modify all_indicators_con;
	attrib _all_ label='';
run;


proc datasets lib=work;
	modify all_ageten;
	attrib _all_ label='';
run;

proc datasets lib=work;
	modify all_ageten_con;
	attrib _all_ label='';
run;

proc export data=all_indicators dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes NOT FOR RELEASE.xlsx' replace;
	sheet='Outcomes';
run;

proc export data=all_indicators_con dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes.xlsx' replace;
	sheet='Outcomes';
run;

proc export data=all_ageten dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes NOT FOR RELEASE.xlsx' replace;
	sheet='Age breakdown';
run;

proc export data=all_ageten_con dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes.xlsx' replace;
	sheet='Age breakdown';
run;