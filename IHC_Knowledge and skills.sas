/**Creating Knowledge and Skill domain indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Luisa Beltran-Castillon 
Start date - 24/02/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

apc_hst_qual_code - highest qualification (Only available for individuals aged 15 and over.)
Due to a bug in the code, a small number of individuals with zero highest qualifications have a field of study.
This should be filtered for, when using the data.

0 No qualification
1 Level 1 certificate
2 Level 2 certificate
3 Level 3 certificate
4 Level 4 certificate
5 Level 5 diploma
6 Level 6 diploma
7 Bachelor degree and Level 7 qualification
8 Post-graduate an
d honours degrees
9 Masters degree
10 Doctorate degree

** KS1 - ECE participation 
** KS2 - School participation
** KS3 - Highest qualification
** KS4 - Driver licensing

*/ 

data apcpop_cen_idd_2018; set sandpit.apcpop_cen_idd_2018; run;
proc sort data=apcpop_cen_idd_2018 nodupkey; by snz_uid; run;

*KS2 - Highest qualification (18+ population);
proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table highqual as
	select *
    from connection to odbc(
	select distinct a.snz_uid,b.apc_hst_qual_code
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".APC_education_ts_202210 b
	on a.snz_uid=b.snz_uid
	where b.apc_ref_year_nbr=2018
	order by a.snz_uid);
    disconnect from odbc;
quit;

data know_and_skill;
	merge apcpop_cen_idd_2018(keep=snz_uid snz_cen_uid idd_id apc_age_in_years_nbr census_link) highqual;
	by snz_uid;
	if apc_hst_qual_code ne . then do;
		if apc_hst_qual_code>=2 then KS3_high_qual2=1;
		else KS3_high_qual2=0;
		if apc_hst_qual_code>=4 then high_qual4=1;
		else high_qual4=0;
		if apc_hst_qual_code>=7 then high_qual7=1;
		else high_qual7=0;
		if apc_hst_qual_code=0 then noqual=1;
		else noqual=0;
	end;
run;

proc freq data=know_and_skill;
table (KS3_high_qual2 high_qual4 high_qual7 noqual)*idd_id / nofreq norow nopercent missing;
where apc_age_in_years_nbr>=18;
run;

** KS4 - Driver licensing;

** We use the licensing IDI code module;
** include it now;
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/nzta_driver_licences.sas';

%nzta_driver_licences(targetdb = IDI_UserCode
                         ,targetschema=[DL-MAA2022-54]
                         ,projprefix=ihci
                         ,idicleanversion=IDI_Clean_202210
                         ,populationdata=[IDI_sandpit].[DL-MAA2022-54].apcpop_cen_idd_2018
                         ,idcolumn=snz_uid
                         ,startdatecolumn=from_dt
                         ,enddatecolumn=to_dt
                         ,outfile=TRUE
                         );

** Identify if person holds a valid drivers licence - learners, restricted or full;
proc sql;
	create table licence as
	select distinct a.snz_uid,case when b.snz_uid is not null then 1 else 0 end as ks4_licence
	from apcpop_cen_idd_2018 a left join IHCI_NZTA_LICENCES b
	on a.snz_uid=b.snz_uid and licence_start_date<='30jun2018'd and licence_end_date>='30jun2018'd;
quit;

proc sort data=know_and_skill;
	by snz_uid;
run;

data know_and_skill2;
	merge know_and_skill licence;
	by snz_uid;
run;

proc freq data=know_and_skill2;
table ks4_licence*idd_id / nofreq norow nopercent missing;
where adult18plus=1;
run;

** KS1 - ECE participation - 5 to 14 year olds;

** The first indicator we look at comes from reporting to schools;
/*
Duration defined as follows:
ECEDurationID	ECEDuration
61052	Yes, for the last 6 months
61053	Yes, for the last year
61054	Yes, for the last 2 years
61055	Yes, for the last 3 years
61056	Yes, for the last 4 years
61057	Yes, for the last 5 or more years
61058	Not regularly, only occasionally with no on-going schedule

ECE classification defined as:
ECEClassificationID	ECEClassification	ExtractDate
20630	Did not attend	08AUG2022
20631	Kohanga Reo	08AUG2022
20632	Kindergarten or Education and Care Centre	08AUG2022
20633	Playcentre	08AUG2022
20634	Home based service	08AUG2022
20635	The Correspondence School - Te Aho o Te Kura Pounamu	08AUG2022
20636	Playgroup	08AUG2022
20637	Unable to establish if attended or not	08AUG2022
20638	Attended, but don't know what type of service	08AUG2022
61050	Attended, but only outside New Zealand	08AUG2022
*/

proc sql;
	create table ece as
	select distinct b.*,c.ececlassification,d.eceduration
	from sandpit.apcpop_cen_idd_2018(where=(5<=apc_age_in_years_nbr<=14)) a inner join moe.ece_duration b
	on a.snz_uid=b.snz_uid
	left join moemeta.ece_classif_code c
	on b.moe_sed_ece_classification_code=c.ececlassificationid
	left join moemeta.ece_duration_code d
	on b.moe_sed_ece_duration_code=d.ecedurationid
	order by snz_uid,moe_sed_snz_unique_nbr;
quit;

** Only keep 1 record per child - they may have attended multiple services;
data ece;
	set ece;
	by snz_uid;
	if first.snz_uid;
run;

proc freq data=ece;
	tables eceduration*ececlassification/missing nopercent nocol norow;
run;

** There is a lot of missing duration information, so we will not use that;
** Base attendance on the classification instead and include overseas ECE, unspecified ECE and home-based care;
** If unknown attendance set to missing;

data know_and_skill3;
	merge know_and_skill2 ece;
	by snz_uid;
	if ececlassification in ('','Unable to establish if attended or not') then ks1_ece=.;
	else if ececlassification='Did not attend' then ks1_ece=0;
	else ks1_ece=1;
run;

proc freq data=know_and_skill3;
table ks1_ece*(idd_id apc_age_in_years_nbr)/ nofreq norow nopercent;
run;


** The second indicator comes from the ELI (early learning information) system;
proc sql;
	create table ece2 as
	select distinct a.snz_uid,case when b.snz_moe_uid is not null then 1 else 0 end as moe_link,
			case when c.snz_moe_uid is not null then 1 else 0 end as ece_attend
	from apcpop_cen_idd_2018(where=(apc_age_in_years_nbr in (3,4))) a
		left join security.concordance b 
		on a.snz_uid=b.snz_uid
		left join moeadhoc.studentattendance(where=(eceattendancecode ne '' and year(attendancedate)=2018)) c 
		on b.snz_moe_uid=c.snz_moe_uid
	order by snz_uid;
quit;

data know_and_skill4;
	merge know_and_skill3 ece2;
	by snz_uid;
	if moe_link=. then ks1_ece2=.;
	else ks1_ece2=ece_attend; 
run;

proc freq data=know_and_skill4;
table ks1_ece2*(idd_id apc_age_in_years_nbr)/ nofreq norow nopercent;
run;

****************************************************************************************;
** KS2 - School participation;
proc sql;
	create table school as
	select distinct a.snz_uid,a.apc_age_in_years_nbr,a.idd_id,z.providernumber,z.studenttype,z.firstattendance,z.lastattendance,
			c.*,d.ProviderAffiliation,e.ProviderFundingType,f.ProviderType
	from apcpop_cen_idd_2018 a 
	inner join moe.student_enrol b
	on a.snz_uid=b.snz_uid 
	inner join moeadhoc.school_roll_return_2018(where=(month(input(strip(collectiondate),date9.))=7)) z
	on b.snz_moe_uid=z.snz_moe_uid
	left join moeadhoc.Provider_Profile c
	on z.providernumber=c.ProviderNumber
	left join moemeta.provider_affiliation_code d
	on c.ProviderAffiliationId=input(d.ProviderAffiliationID,z9.)
	left join moemeta.provider_funding_type_code e
	on c.SchoolFundingTypeID=input(e.ProviderFundingTypeID,z9.)
	left join moemeta.provider_type_code f
	on c.ProviderTypeId=input(f.ProviderTypeId,z9.)
	order by snz_uid;
quit;

** Look at people enrolled in multiple schools - many are dual enrolments with health school so we can deal with that below;
data know_and_skill5;
	merge know_and_skill4 school(in=b);
	retain special_school;
	by snz_uid;
	if first.snz_uid then special_school=0;
	if b then ks2_school=1;
	else ks2_school=0;
	if ProviderType='Special School' then special_school=1;
	if last.snz_uid then output;
run;

proc freq data=know_and_skill5;
table (idd_id apc_age_in_years_nbr)*(ks2_school special_school)/ nofreq nocol nopercent;
where 5<=apc_age_in_years_nbr<=17;
run;

proc datasets lib=sandpit; delete know_and_skill; run;
data sandpit.know_and_skill; set know_and_skill5; run;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table interventions as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,a.apc_age_in_years_nbr,b.*
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join IDI_Clean_202210.moe_clean.student_interventions b
	on a.snz_uid=b.snz_uid
	where b.moe_inv_start_date<='2018-12-31' and b.moe_inv_end_date>='2018-01-01'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc sql;
	create table interventions2 as
	select a.*,b.interventionname
	from 
	interventions a left join moemeta.intervention_type_code b
	on a.moe_inv_intrvtn_code=b.interventionid;
run;

proc freq data=interventions2;
table interventionname*(idd_id apc_age_in_years_nbr)/norow nocol nopercent;
run;

proc freq data=interventions2;
table interventionname*(idd_id apc_age_in_years_nbr)/norow nofreq nopercent;
run;