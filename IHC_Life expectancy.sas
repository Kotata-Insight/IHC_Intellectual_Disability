/**Creating Life expectancy estimates

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 24/02/2023
Code location - I:\MAA2022-54\code

Core population saved in project.apcpop_cen_idd_2018

We get deaths from death registrations and identify whether the person was identified as having an ID or not
from project.cw_202210_ID

We use the abridged Chiang II life table method (Chiang 1978, 1984)

*/ 

** First extract all deaths occurring from 2017 to 2019 - may want to move to a year, but
** three years will give us more reliable estimates. This also matched Stats NZ latest life expectancy estimates
** and we can compare our results against those.;

proc sql;
	create table deaths_17to19 as select distinct a.*,case when b.snz_uid is not null then 1 else 0 end as idd_id,
		c.apc_ethnicity_grp1_nbr,c.apc_ethnicity_grp2_nbr,c.apc_ethnicity_grp3_nbr,c.apc_ethnicity_grp4_nbr
	from dia.deaths(where=(dia_dth_death_year_nbr in (2017,2018,2019))) a 
	left join sandpit.cw_202210_ID b
	on a.snz_uid=b.snz_uid
	left join snzdata.apc_constants c
	on a.snz_uid=c.snz_uid
	order by a.snz_uid;
run;

proc freq data=deaths_17to19;
	tables idd_id apc_ethnicity_grp1_nbr apc_ethnicity_grp2_nbr apc_ethnicity_grp3_nbr apc_ethnicity_grp4_nbr;
run;

** Create a format for our age groups of interest;
proc format;
value agegrp_lifeexp
0='00'
1-4='01-04'
5-9='05-09'
10-14='10-14'
15-19='15-19'
20-24='20-24'
25-29='25-29'
30-34='30-34'
35-39='35-39'
40-44='40-44'
45-49='45-49'
50-54='50-54'
55-59='55-59'
60-64='60-64'
65-69='65-69'
70-74='70-74'
75-79='75-79'
80-84='80-84'
85-89='85-89'
90-high='90+'
;
run;

data deaths_17to19b missing;
	set deaths_17to19;
	keep snz_uid idd_id birthdate deathdate age_int dia_dth_sex_snz_code death_months apc_ethnicity_grp1_nbr apc_ethnicity_grp2_nbr apc_ethnicity_grp3_nbr apc_ethnicity_grp4_nbr;
	birthdate=mdy(dia_dth_birth_month_nbr,15,dia_dth_birth_year_nbr);
	deathdate=mdy(dia_dth_death_month_nbr,15,dia_dth_death_year_nbr);
	age_at_death=floor(yrdif(birthdate,deathdate,'age'));
	death_months=dia_dth_death_month_nbr-dia_dth_birth_month_nbr;
	age_int=put(age_at_death,agegrp_lifeexp.);
	if death_months<0 then death_months=12+death_months;
	if birthdate=. or deathdate=. or dia_dth_sex_snz_code=. then output missing;
	else output deaths_17to19b;
	format birthdate deathdate date9.;
run;

** Very few missing;

proc sort data=deaths_17to19b;
	by age_int dia_dth_sex_snz_code idd_id;
run;

%macro run_life(subset=,subpop=);
** Now sum up the number of deaths in each interval;
data deaths_17to19subpop;
set deaths_17to19b;
where age_int ne '' %if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
run;

proc freq data=deaths_17to19subpop noprint;
	tables age_int*dia_dth_sex_snz_code*idd_id/out=deaths_17to19_int0(drop=percent);
run;

proc freq data=deaths_17to19subpop noprint;
	tables age_int*dia_dth_sex_snz_code/out=deaths_17to19_int_tot(drop=percent);
run;

data deaths_17to19_int;
	set deaths_17to19_int0 deaths_17to19_int_tot;
run;

** Now calculate the APC population in each age band;
proc freq data=sandpit.apcpop_cen_idd_2018 noprint;
	tables apc_age_in_years_nbr*snz_sex_gender_code*idd_id/out=pop_17to19_int0(drop=percent);
	where snz_sex_gender_code in ('1','2') and apc_age_in_years_nbr ne .
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
	format apc_age_in_years_nbr agegrp_lifeexp.;
run;

** Now calculate the APC population in each age band;
proc freq data=sandpit.apcpop_cen_idd_2018 noprint;
	tables apc_age_in_years_nbr*snz_sex_gender_code/out=pop_17to19_int_tot(drop=percent);
	where snz_sex_gender_code in ('1','2') and apc_age_in_years_nbr ne .
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
	format apc_age_in_years_nbr agegrp_lifeexp.;
run;

data pop_17to19_int(drop=apc_age_in_years_nbr);
	set pop_17to19_int0 pop_17to19_int_tot;
	age_int=put(apc_age_in_years_nbr,agegrp_lifeexp.);
run;

** Calculate ai for each band;
proc means data=deaths_17to19subpop noprint;
	var death_months;
	by age_int;
	output out=death_month_mean mean=;
run;

data death_month_mean(drop=_freq_ _type_ death_months);
	set death_month_mean;
	** ai is the average distance through the year when deaths occur;
	ai=(death_months+0.5)/12;
run;

proc sort data=deaths_17to19_int;
	by age_int dia_dth_sex_snz_code idd_id;
run;

proc sort data=pop_17to19_int;
	by age_int snz_sex_gender_code idd_id;
run;

** And merge these together;
data life_exp_int;
	length age_int $ 5;
	merge deaths_17to19_int(rename=(count=count_deaths)) pop_17to19_int(rename=(snz_sex_gender_code=dia_dth_sex_snz_code count=count_pop));
	by age_int dia_dth_sex_snz_code idd_id;
	if count_deaths=. then count_deaths=0;
	** Deaths are over three years so multiply pop by 3 to get an average;
	count_pop=count_pop*3;
	** ni is the number of year in each interval i;
	if age_int='00' then ni=1;
	else if age_int='01-04' then ni=4;
	else if age_int='90+' then ni=.;
	else ni=5;
	** Di is the number of deaths in the year (this is our average over 2017-2019);
	Di=count_deaths;
	** Pi is the population in the middle of the period - June 2018;
	Pi=count_pop;
	** Mi is the death rate in the interval;
	Mi=Di/Pi;
run;

data life_exp_intb;
	merge life_exp_int death_month_mean;
	by age_int;
	** qi is the probability that someone will die in interval i;
	if age_int='90+' then qi=1;
	else qi=(ni*Mi)/(1+(1-ai)*ni*Mi);
run;

proc sort data=life_exp_intb;
	by dia_dth_sex_snz_code idd_id age_int;
run;

data life_exp_intc;
	set life_exp_intb;
	retain li;
	by dia_dth_sex_snz_code idd_id age_int;
	if first.idd_id then do;
		li=100000;
	end;
	di=li*qi;
	if age_int='90+' then L_i=li/Mi;
	else L_i=ni*(li-di)+ai*ni*di;
	li=li-di;
run;

proc sort data=life_exp_intc;
	by dia_dth_sex_snz_code idd_id descending age_int;
run;

data life_exp_intd;
	set life_exp_intc;
	by dia_dth_sex_snz_code idd_id;
	retain Ti eip;
	if first.idd_id then Ti=0;
	Ti=Ti+L_i;
	ei=(Ti/li);
	output;
	eip=ei;
run;

proc sort data=life_exp_intd;
	by dia_dth_sex_snz_code idd_id age_int;
run;

data life_exp_inte;
	set life_exp_intd;
	retain lix;
	by dia_dth_sex_snz_code idd_id age_int;
	if first.idd_id then do;
		lix=100000;
	end;
	spi2=(qi*qi*(1-qi))/Di;
	pai=li/lix;
	se2calc=pai**2*((1-ai)*ni+eip)**2*spi2;
	if se2calc=. then se2calc=0;
	output;
	lix=li;
run;

proc sort data=life_exp_inte;
	by dia_dth_sex_snz_code idd_id descending age_int;
run;

data life_exp_intf;
	set life_exp_inte;
	by dia_dth_sex_snz_code idd_id;
	retain se2;
	if first.idd_id then se2=0; 
	se2=se2+se2calc;
	se_e=sqrt(se2);
run;

proc sort data=life_exp_intf;
	by dia_dth_sex_snz_code idd_id age_int;
run;

data project.life_exp_birth_&subpop.(keep=subpop idd_id sex h1_life_exp_birth se_e);
	length subpop $ 30;
	set life_exp_intf;
	where age_int='00';
	rename ei=h1_life_exp_birth dia_dth_sex_snz_code=sex;
	subpop="&subpop.";
	label h1_life_exp_birth='Life expectancy at birth' se_e='Standard error life expectancy at birth';
run;
%mend run_life;

%run_life(subset=,subpop=);
%run_life(subset=apc_ethnicity_grp1_nbr=1,subpop=ethE);
%run_life(subset=apc_ethnicity_grp2_nbr=1,subpop=ethM);
%run_life(subset=apc_ethnicity_grp3_nbr=1,subpop=ethP);
%run_life(subset=apc_ethnicity_grp4_nbr=1,subpop=ethA);

data life_exp_birth_all;
	set project.life_exp_birth_ project.life_exp_birth_ethE project.life_exp_birth_ethM project.life_exp_birth_ethP project.life_exp_birth_ethA;
run;

proc export data=life_exp_birth_all dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes.xlsx' replace;
	sheet='Life expectancy';
run;