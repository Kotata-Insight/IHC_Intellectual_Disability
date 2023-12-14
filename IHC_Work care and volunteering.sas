/**Creating Work, care and volunteering domain indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Luisa Beltran-Castillon / Keith McLeod
Start date - 24/02/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

WCV1 - Employment participation (18-64 years old)
WCV2 - Youth not in employment, education or training (NEET) - 15-24 years old;
WCV3 - Benefit receipt
WCV4 - Parental employment participation (0-15 years old)
WCV5 - Parents as carers (0-15 years old)
WCV6 - Volunteering

We also define FF5 - being in a sole parent household - here.

snz_uid								Unique identifier
snz_cen_uid							Individual ID
snz_cen_fam_uid						Family ID
snz_cen_dwell_uid					Dwelling ID
snz_cen_extfam_uid					Extended Family ID
snz_cen_hhld_uid					Household ID
cen_fml_family_type_code			Family type  
cen_fml_chld_dpnd_fmly_type_code	Family type by child dependency status  
cen_fml_chld_cnt_fmly_type_code		Family type by number of children
cen_fml_couple_family_type_code		Family type with type of couple
cen_fml_couple_type_code			Type of couple  
cen_fml_sole_parent_sex_code		Sex of sole parent 
cen_ind_family_role_code			Individual's role in family nucleus


apc_employed_ind - Employment indicator - 	An individual's inclusion in or exclusion	from the labour force.
											Binary indicator set to "1", when an individual's work and labour fource status is "Employed",
											NULL otherwise

*/ 

data apcpop_cen_idd_2018; set sandpit.apcpop_cen_idd_2018; run;
proc contents data=apcpop_cen_idd_2018; run;

**********************************************************************************************************;
* WCV1_employed
* WCV2 - Youth not in employment, education or training (NEET) - 15-24 years old;
/*proc freq data=sandpit.apcpop_cen_idd_2018;
	tables apc_age_in_years_nbr*apc_study_prtpcn_code/nocol nopercent nofreq missing;
run;*/

** Add study indicator from updated Stats NZ code;
proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table youthneet as
	select *
    from connection to odbc(
	select a.snz_uid,a.idd_id,a.apc_age_in_years_nbr,a.adult15plus,a.adult18plus,a.apc_employed_ind,b.apc_study_prtpcn_code
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".APC_education_ts_202210 b
	on a.snz_uid=b.snz_uid
	where b.apc_ref_year_nbr=2018 and a.apc_age_in_years_nbr <= 24 and a.apc_age_in_years_nbr >= 15
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc freq data=youthneet;
	tables apc_age_in_years_nbr*apc_study_prtpcn_code/nocol nopercent nofreq missing;
run;

proc sql;
	create table youthneet2 as
	select distinct a.*,
		case when b.snz_uid is not null then 1 else apc_employed_ind end as apc_employed_ind2,
		case when (apc_age_in_years_nbr>24 or apc_age_in_years_nbr<15) then . 
			when (calculated apc_employed_ind2=1 or apc_study_prtpcn_code in ('F','S','P')) then 0
			else 1 end as wcv2_yneet,
		case when (apc_age_in_years_nbr>24 or apc_age_in_years_nbr<15) then ''
			when (calculated apc_employed_ind2=1 and apc_study_prtpcn_code in ('F','S','P')) then 'Work+Study'
			when calculated apc_employed_ind2=1 then 'Work only'
			when apc_study_prtpcn_code in ('F','S','P') then 'Study only'
			else 'NEET' end as wcv2_status
	from youthneet a left join ir.ird_ems(where=(ir_ems_return_period_date='31jul2018'd and ir_ems_income_source_code in ('W&S','WHP'))) b
	on a.snz_uid=b.snz_uid
	order by a.snz_uid;
quit;

proc freq data=youthneet2;
	tables apc_employed_ind*apc_employed_ind2/missing;
run;

** Identify youth with employment income in July 2018 and include these as employed also;

proc sort data=apcpop_cen_idd_2018;
	by snz_uid;
run;

data work_care_volun;
	merge apcpop_cen_idd_2018(keep=snz_uid idd_id apc_age_in_years_nbr youth15to24 apc_employed_ind)
		youthneet2(keep=snz_uid wcv2_status wcv2_yneet);
	by snz_uid;
	WCV1_employed=apc_employed_ind;
	if WCV1_employed=. then WCV1_employed=0;
	if wcv2_status='Study only' then youth_study=1;
	else if wcv2_status='' then youth_study=.;
	else youth_study=0;
	if wcv2_status='Work only' then youth_work=1;
	else if wcv2_status='' then youth_work=.;
	else youth_work=0;
	if wcv2_status='Work+Study' then youth_wkstudy=1;
	else if wcv2_status='' then youth_wkstudy=.;
	else youth_wkstudy=0;
	label wcv2_yneet='Youth NEET indicator';
	drop wcv2_status;
run;

proc freq data=work_care_volun;
table (WCV1_employed youth_study youth_work youth_wkstudy wcv2_yneet)*idd_id / norow nofreq nopercent missing;
where youth15to24=1;
run;

** WCV4 - Parental employment participation (0-15 years old)
**    Currently defined as all parents being in some type of employment;
** WCV5 - Parents as carers (0-15 years old);
**    Currently defined as one or more parents not being in fulltime employment;
** FF5 - Sole parent household;

** Check the labour force status of parents from Census;
proc sql;
	create table parent_emp as
	select a.snz_uid,count(b.snz_uid) as n_parents,sum(case when b.cen_ind_wklfs_code='1' then 1 else 0 end) as n_parentsftemp,
			sum(case when b.cen_ind_wklfs_code='2' then 1 else 0 end) as n_parentsptemp,sum(case when b.cen_ind_wklfs_code in ('3','4') then 1 else 0 end) as n_parentsnoemp
	from sandpit.children_0to17_par a left join census.census_individual_2018 b
	on a.parent_snz_uid=b.snz_uid
	group by a.snz_uid
	order by a.snz_uid;
quit;

proc freq data=parent_emp;
	tables (n_parentsftemp n_parentsptemp n_parentsnoemp)*n_parents/nopercent norow nofreq;
run;

data work_care_volun;
	merge work_care_volun parent_emp;
	by snz_uid;
	if n_parents in (0,.) then wcv4_parentemp=.;
	else if n_parentsftemp+n_parentsptemp=n_parents then wcv4_parentemp=1;
	else wcv4_parentemp=0;
	if n_parents in (0,.) then wcv5_parentcare=.;
	else if n_parentsptemp+n_parentsnoemp>0 then wcv5_parentcare=1;
	else wcv5_parentcare=0;
	if n_parents=1 then ff5_soleparent=1;
	else if n_parents=2 then ff5_soleparent=0;
	else ff5_soleparent=.;
run;

proc freq data=work_care_volun;
	tables n_parents*(wcv4_parentemp wcv5_parentcare)*idd_id ff5_soleparent*idd_id/nopercent norow nofreq;
	where apc_age_in_years_nbr<=14;
run;

*** WCV3 - Benefit receipt;
** Use Marcs msd adult ben spells module to identify benefit receipt, then look at any second tier payments;
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/frmtdatatight.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/spellhistoryinverter.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/spellcombine.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/use_fmt.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/subset_ididataset2.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/hashtbldynajoin.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/spellcondense.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/hashtblfulljoin.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/adultmainbenspl_202210.sas';

%adultmainbenspl_202210(
   AMBSinfile=apcpop_cen_idd_2018
  ,AMBS_BenSpl=apcpop_ben
  ,AMBS_IDIxt = 202210
  ,AMBS_sandpitschema = DL-MAA-2022-54
  ,AMBS_dropduplicates = Y
  );

** Now restrict to benefit at some stage between April and June 2018;
proc sort data=apcpop_ben;
	by snz_uid EntitlementSD;
run;

data apcpop_ben2;
	set apcpop_ben;
	by snz_uid;
	where EntitlementSD<='30jun2018'd and EntitlementED>='01apr2018'd and BenefitType not in ('Not On Main Benefit','Off Benefit','New Zealand Superannuation',
																								'Pension','Veterans Pension');
	if last.snz_uid;
run;

proc freq data=apcpop_ben2;
	tables benefittype;
run;

data work_care_volun;
	merge work_care_volun(in=a) apcpop_ben2(in=b);
	by snz_uid;
	if a;
	if b then wcv3_benefit=1;
	else wcv3_benefit=0;
run;

proc freq data=work_care_volun;
	tables (wcv3_benefit benefittype)*idd_id/nopercent norow nofreq;
	where 18<=apc_age_in_years_nbr<=64;
run;

*** WCV6 - Volunteering;
proc freq data=apcpop_cen_idd_2018;
	tables unpaid_acts;
run;

data work_care_volun;
	merge work_care_volun apcpop_cen_idd_2018(keep=snz_uid unpaid_acts);
	by snz_uid;
	if find(unpaid_acts,'04')>1 then care_child=1;
	else if unpaid_acts ne '' then care_child=0;
	if find(unpaid_acts,'05')>1 then care_illdis=1;
	else if unpaid_acts ne '' then care_illdis=0;
	if find(unpaid_acts,'06')>1 then other_helpvol=1;
	else if unpaid_acts ne '' then other_helpvol=0;
	if care_child or care_illdis or other_helpvol then wcv6_volunteer=1;
	else if unpaid_acts='' then wcv6_volunteer=.;
	else wcv6_volunteer=0;
run;

proc freq data=work_care_volun;
	tables idd_id*(care_child care_illdis other_helpvol wcv6_volunteer)/nopercent nocol nofreq;
	where adult15plus=1;
run;

proc datasets lib=sandpit; delete work_care_volun; run;
data sandpit.work_care_volun; set work_care_volun; run;
