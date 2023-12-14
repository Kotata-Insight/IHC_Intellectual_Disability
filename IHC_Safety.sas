 /** Safety indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 17/03/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

Output datasets: sandpit.safety

** This indicator comes from police victims of crime data:
** S3 - Victims of crime;

** The following indicators come from Oranga Tamariki (CYF) data:
** S5 - Children in care;
** S6 - Children exposed to violence;
** S7 - Children of parents in care;
*/ 

proc datasets lib=work kill;run;

** S5 - Children in care;
** S6 - Children exposed to violence;
** S7 - Children of parents in care;
** First extract and categorise contact with OT - this comes from code by Rob Templeton at Treasury;
** Our population of interest is children aged under 18;
proc sql;
	create table study_pop as select snz_uid
	from sandpit.apcpop_cen_idd_2018
	where childunder18=1
	order by snz_uid;
quit;

proc freq data=cyf.cyf_contact_record_events;
	tables cyf_cli_caller_role_text;
run;

* create dataset of police family violence callouts (for more recent years);
* this dataset is in the IDI sandpit only;
* subset to callouts  that involve children in our study population;
proc sql;
	create table laterPFV_events as select *,
		snz_prsn_uid as snz_uid	
	from  cyf.cyf_contact_record_events  
	where snz_prsn_uid in (select distinct snz_uid from study_pop) and cyf_cli_caller_role_text='PFV' 
		and datepart(cyf_cli_cr_created_datetime)<='30jun2018'd
	order by snz_uid;
quit;

* create dataset of notifications to CYF;
* NOTE: police family violence events were in here in early years;
proc sql;
	create table all_notifications as select 
		a.*, b.cyf_ind_notifier_role_type_code
	from cyf.cyf_intakes_event a INNER join  cyf.cyf_intakes_details  b
		on a.snz_composite_event_uid=b.snz_composite_event_uid 
	where a.snz_uid in (select distinct snz_uid from study_pop)
		order by snz_uid;
quit;

data notifications other_pfv_events;
	set all_notifications;
	where cyf_ine_event_from_date_wid_date<='30jun2018'd;
	if cyf_ind_notifier_role_type_code = 'PFV' then
		output other_pfv_events;
	else output notifications;
run;

* now  look for family conferences involving these children;
proc sql;
	create table family_conf as select *
	from cyf.cyf_ev_cli_fgc_cys_f where snz_uid in (select distinct snz_uid from study_pop)
		and datepart(cyf_fge_event_from_datetime)<='30jun2018'd
		order by snz_uid;
quit;

* now look for whanau agreemnts involving these children;
proc sql;
	create table whanau_conf as select 	*
	from CYF.cyf_ev_cli_fwas_cys_f  where snz_uid in (select distinct snz_uid from study_pop)
		and cyf_fwe_event_from_date_wid_date<='30jun2018'd
		order by snz_uid;
quit;

* look for any placements involving these children;
proc sql;
	create table placements as select *
	from cyf.cyf_placements_event  where snz_uid in (select distinct snz_uid from study_pop)
		and cyf_ple_event_from_date_wid_date<='30jun2018'd
		order by snz_uid;
quit;

* Pull all of the event records together and create final indicators;
data cyf_study_pop;
	merge study_pop 
		notifications(in=in_cyf_notification)
		family_conf(IN=in_FGC)
		whanau_conf(IN=in_FWAS)
		placements (in=in_plaCe)
		other_PFV_events(in=in_PFV) 	
		laterPFV_events(in=in_PFV2);
	by snz_uid;
	retain any_not any_family any_pl any_pfv;

	if first.snz_uid then do;
		any_not=0;
		any_family=0;
		any_pl=0;
		any_pfv=0;
	end;

	if in_cyf_notification then any_not=1;
	if in_fgc or in_fwas then any_family=1;
	if in_place then any_pl=1;
	if IN_PFV or IN_PFV2 then any_pfv=1;

	if last.snz_uid then output;
	
	label any_not='Notified to Oranga Tamariki' any_family='Family conference or whanau agreement'
		any_pl='Placement by Oranga Tamariki' any_pfv='Police family violence callout';
run;

proc freq data=cyf_study_pop;
	tables any_:;
run;

** S5 - Children with an ID in care;
** S6 - Children exposed to violence;
proc sql;
	create table apcpop_cen_idd_2018_placements as 
	select distinct a.snz_uid, a.idd_id, a.apc_age_in_years_nbr, a.snz_sex_gender_code,
		case when b.any_pl=1 then 1 else 0 end as s5_placement,
		case when b.any_pfv=1 then 1 else 0 end as s6_fam_violence
		FROM sandpit.apcpop_cen_idd_2018(where=(childunder18=1)) a 
			left join cyf_study_pop(where=(any_pl=1 or any_pfv=1)) b 
			on a.snz_uid=b.snz_uid
	order by a.snz_uid;
quit;

proc freq data=apcpop_cen_idd_2018_placements;
	table s5_placement*idd_id s6_fam_violence*idd_id/ nofreq norow nopercent missing;
run;

** S7 - Children of parents in care;

** Firstly identify all birth parents associated with children who have been placed in care;
proc sql;
	create table parents_care1 as
	select distinct b.parent1_snz_uid as snz_uid,coalesce(max(a.any_pl),0) as place1
	from cyf_study_pop(where=(any_pl=1)) a 
			right join dia.births(where=(parent1_snz_uid ne .)) b 
			on a.snz_uid=b.snz_uid
	group by b.parent1_snz_uid
	order by b.parent1_snz_uid;
quit;

proc sql;
	create table parents_care2 as
	select distinct b.parent2_snz_uid as snz_uid,coalesce(max(a.any_pl),0) as place2
	from cyf_study_pop(where=(any_pl=1)) a 
			right join dia.births(where=(parent2_snz_uid ne .)) b 
			on a.snz_uid=b.snz_uid
	group by b.parent2_snz_uid
	order by b.parent2_snz_uid;
quit;

data parents_care;
	merge parents_care1 parents_care2;
	by snz_uid;
	where snz_uid ne .;
	if place1 or place2 then s7_childplacement=1;
	else s7_childplacement=0;
run;

data apcpop_cen_idd_2018_placements2;
	merge sandpit.apcpop_cen_idd_2018(keep=snz_uid idd_id adult15plus where=(adult15plus=1) in=a) parents_care;
	by snz_uid;
	if a;
run;

proc freq data=apcpop_cen_idd_2018_placements2;
	table s7_childplacement*idd_id/ nofreq norow nopercent missing;
run;

proc freq data=apcpop_cen_idd_2018_placements2;
	table s7_childplacement*idd_id/ nofreq norow nopercent;
run;

data safety(drop=place1 place2);
	merge sandpit.apcpop_cen_idd_2018(keep=snz_uid adult15plus childunder18 idd_id apc_age_in_years_nbr snz_sex_gender_code) apcpop_cen_idd_2018_placements apcpop_cen_idd_2018_placements2;
	by snz_uid;
	label s7_childplacement='Has had a birth child placed in care';
run;

proc datasets lib=sandpit; delete safety; run;
data sandpit.safety; set safety; run;

** S3 - Victims of crime;
data victims_1718;
	set pol.post_count_victimisations;
	where '01jul2017'd <= pol_pov_reported_date <= '30jun2018'd;
run;

** Note around a small percent do not have an SNZ_UID;
** And over half have an SNZ_UID but do not match to our population - possibly do not match to the spine either;

proc sql;
	create table victims as
	select distinct a.snz_uid, a.idd_id, a.apc_age_in_years_nbr, a.snz_sex_gender_code,
		max(case when b.snz_uid is not null then 1 else 0 end) as victim_ind,
		sum(case when b.snz_uid is not null then 1 else 0 end) as s3_victim
	from sandpit.apcpop_cen_idd_2018 a left join victims_1718 b
	on a.snz_uid=b.snz_uid
	group by a.snz_uid
	order by a.snz_uid;
quit;

data safety;
	merge sandpit.safety victims;
	by snz_uid;
run;

proc sql;
	create table victim_means as
	select idd_id,mean(victim_ind) as mean_victim_ind, mean(s3_victim) as mean_s3_victim,
			sum(victim_ind) as sum_victim_ind, sum(s3_victim) as sum_s3_victim,count(s3_victim) as n
	from safety
	group by idd_id
	order by idd_id;
quit;

proc datasets lib=sandpit; delete safety; run;
data sandpit.safety; set safety; run;
