/** Create Cultural Capability and belonging indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 08/08/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

Output datasets: sandpit.cultural_cap_belong

** CCB1 - Incarceration rate of the 18+ population (note: easier to use 15+ for age standardisation);
** CCB2 - Conviction rate of the 18+ population (note: easier to use 15+ for age standardisation);
** CCB3 - International travel

*/ 

** CCB1 - Incarceration rate of the 18+ population (note: easier to use 15+ for age standardisation);

** Now check if a person was serving a custodial sentence on 30 June 2018;
proc sql;
	create table apcpop_cen_idd_2018_incarc as select distinct a.snz_uid
		FROM sandpit.apcpop_cen_idd_2018 a inner join cor.ov_major_mgmt_periods_historic(where=(cor_mmp_mmc_code in ('PRISON','REMAND'))) b
		on a.snz_uid=b.snz_uid and b.cor_mmp_period_start_date<="30jun2018"d<b.cor_mmp_period_end_date
		ORDER BY a.snz_uid;
quit;

data cultural_cap_belong;
	merge sandpit.apcpop_cen_idd_2018(keep=snz_uid snz_cen_uid idd_id apc_age_in_years_nbr adult15plus adult18plus) apcpop_cen_idd_2018_incarc(in=b);
	by snz_uid;
	if b then ccb1_incarcerated=1;
	else ccb1_incarcerated=0;
	label ccb1_incarcerated='Incarceration indicator (sentenced or on remand)';
run;

proc datasets lib=sandpit; delete cultural_cap_belong; run;
data sandpit.cultural_cap_belong; set cultural_cap_belong; run;

proc freq data=sandpit.cultural_cap_belong; tables adult15plus*ccb1_incarcerated; run;
** Good - nobody in prison under 15!;

proc freq data=sandpit.cultural_cap_belong; 
	tables idd_id*ccb1_incarcerated/nocol nopercent;
	where adult15plus=1;
run;


/** Age standardisation;
** Standardise to the June 2018 NZ estimated resident population in 5 year age bands;
proc freq data=sandpit.cultural_cap_belong noprint;
	tables idd_id*ccb1_incarcerated*apc_age_in_years_nbr/out=age_by_incarc_rate(drop=percent);
	format apc_age_in_years_nbr age5yr.;
run;

proc freq data=sandpit.cultural_cap_belong noprint;
	tables idd_id*apc_age_in_years_nbr/out=age_totals(drop=percent);
	format apc_age_in_years_nbr age5yr.;
	where ccb1_incarcerated ne .;
run;

data age_by_incarc_rate(drop=ccb1_incarcerated);
	merge age_by_incarc_rate(where=(ccb1_incarcerated=1)) age_totals(rename=(count=total));
	by idd_id apc_age_in_years_nbr;
	age_5yr=put(apc_age_in_years_nbr,age5yr.);
	if count=. then count=0;
run;

ods graphics on;
proc stdrate data=age_by_incarc_rate 
				refdata=age5yrpop_jun2018
				method=direct
				stat=rate(mult=100000)
				effect
				plots(only)=(dist effect);
	population group=idd_id event=count total=total;
	reference total=popn;
	strata age_5yr/effect;
	ods output StdRate=stdrate_incarc_rate_child effect=effect_incarc_rate_child;
	where age_5yr not in ('00-04','05-09','10-14');
run;
ods graphics off;*/

** CCB2 - Conviction rate of the 18+ population (note: easier to use 15+ for age standardisation);

***********************************************************************************************************************
***********************************************************************************************************************
* COURTS DATASET INDICATORS 
* Nbr APPEARANCES IN YOUTH COURT, Nbr PROVEN OFFENCES (incl youth and adult courts), Nbr CONVICTIONS(youth and adult courts);
* The measure of proven offences is generated because Youth Courts generally don't convict offenders even when the charge is proven.
  Adult courts also discharge some offenders without conviction;
**Note that breaches (of a sentences for a prior offence) are excluded from the 'conviction' and 'proven offences' 
 indicators created here, following advice from Charles Sullivan;

**The conviction and proven offence measures count all charges that the person was convicted of - note that there
 can be multiple charges associated with one criminal act, and multiple charges and convictions on a single day;

***********************************************************************************************************************
***********************************************************************************************************************;

%let population=pop;
data pop;
	set sandpit.apcpop_cen_idd_2018;
	keep snz_uid snz_birth_month_nbr snz_birth_year_nbr;
run;

proc sql;
	create table base as
		select  z.snz_uid
			,z.snz_birth_month_nbr,z.snz_birth_year_nbr	
			,case 
			when moj_chg_charge_outcome_date is not null then moj_chg_charge_outcome_date
			else moj_chg_last_court_hearing_date 
		end as outcome_date
		,moj_chg_offence_code as code
		,b.outcome_6cat as outcome
		,moj_chg_last_court_id_code as court_id
	from &population z
		left join moj.charges a
			on z.snz_uid=a.snz_uid
		left join mojmeta.CHARGE_OUTCOME_CODE b
			on a.moj_chg_charge_outcome_type_code=b.charge_outcome_type_code  
		where b.outcome_6cat in ('1Convicted', '2YC proved', '3Discharge w/o conviction', '4adult diversion, YC discharge' ) 
			order by snz_uid, outcome_date;
quit;

**Drop records if age at the outcome date is <12 - there are a small percentage of cases with ages below this;
**Probably identity mismatch within IDI;
data court_outcomes(keep=snz_uid dob conviction proven_charge outcome_date year);
	set base;
	dob=mdy(snz_birth_month_nbr,15,snz_birth_year_nbr);
	age_at_decision=floor((intck('month',dob,outcome_date)- (day(outcome_date) < day(dob))) / 12);

	if outcome='1Convicted' then
		conviction=1;
	else conviction=0;
	proven_charge=1;
	year=year(outcome_date);

	** Only keep convictions in the 5 years to June 2018;
	if age_at_decision>=12 and '01jul2013'd <= outcome_date <= '30jun2018'd then
		output;
run;

proc summary data=court_outcomes nway;
	class snz_uid;
	var conviction proven_charge;
	output out=temp(keep=snz_uid convictions proven_charges) n=convictions proven_charges;
run;

proc sql;
	create table youth as
		select  z.snz_uid
			,z.snz_birth_month_nbr,z.snz_birth_year_nbr	
			,case 
			when moj_chg_charge_outcome_date is not null then moj_chg_charge_outcome_date
			else moj_chg_last_court_hearing_date end as outcome_date
		,moj_chg_offence_code as code
		,b.outcome_6cat as outcome
		,moj_chg_last_court_id_code as court_id
	from &population z
		left join moj.charges a
			on z.snz_uid=a.snz_uid
		left join mojmeta.CHARGE_OUTCOME_CODE b
			on a.moj_chg_charge_outcome_type_code=b.charge_outcome_type_code  
		order by snz_uid, outcome_date;
quit;

data youth2;
	set youth;
	court=court_id*1;

	if 201<=court<=296 then
		youth_court=1;
	dob=mdy(snz_birth_month_nbr,15,snz_birth_year_nbr);
	age_at_appearance=floor((intck('month',dob,outcome_date)- (day(outcome_date) < day(dob))) / 12);

	if outcome='1Convicted' then
		conviction=1;
	else conviction=0;
	year=year(outcome_date);

	if 12<=age_at_appearance<=17 and youth_court=1 and '01jul2013'd <= outcome_date <= '30jun2018'd then
		output;
run;

**Keep one record per Youth Court appearance date;
proc sort data=youth2;
	by snz_uid outcome_date;
run;

data YC_appearances(keep=snz_uid dob outcome_date year );
	set youth2;
	by snz_uid outcome_date;

	if last.outcome_date;
run;

proc summary data=YC_appearances nway;
	class snz_uid;
	var outcome_date;
	output out=stats(keep=snz_uid YC_appearances) n=YC_appearances;
run;

data cultural_cap_belong;
	merge sandpit.cultural_cap_belong temp stats;
	by snz_uid;
	if convictions=. then
		convictions=0;

	if proven_charges=. then
		proven_charges=0;

	if YC_appearances=. then
		YC_appearances=0;
	if convictions+proven_charges+YC_appearances>0 then CCB2_convictions=1;
	else if convictions+proven_charges+YC_appearances=0 then CCB2_convictions=0;
	else CCB2_convictions=.;
run;

proc freq data=cultural_cap_belong; 
	tables idd_id*CCB2_convictions/nocol nopercent;
	where adult15plus=1;
run;

proc datasets lib=sandpit; delete cultural_cap_belong; run;
data sandpit.cultural_cap_belong; set cultural_cap_belong; run;

** CCB3 - International travel;
proc sql;
	create table overseas as select distinct a.snz_uid
		FROM sandpit.apcpop_cen_idd_2018 a inner join snzdata.person_overseas_spell b
		on a.snz_uid=b.snz_uid and ("01jul2013"d<=b.pos_applied_date<="30jun2018"d or "01jul2013"d<=b.pos_ceased_date<="30jun2018"d)
		ORDER BY a.snz_uid;
quit;

data cultural_cap_belong;
	merge sandpit.cultural_cap_belong overseas(in=b);
	by snz_uid;
	if b then ccb3_travel=1;
	else ccb3_travel=0;
run;

proc freq data=cultural_cap_belong; 
	tables idd_id*ccb3_travel/nocol nopercent;
	where adult15plus=1;
run;

proc datasets lib=sandpit; delete cultural_cap_belong; run;
data sandpit.cultural_cap_belong; set cultural_cap_belong; run;