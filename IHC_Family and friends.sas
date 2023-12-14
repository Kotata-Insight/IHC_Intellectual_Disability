/** Family and friends indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 17/03/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

Output datasets: sandpit.family_friends

** FF1 - Parenting;
** FF2 - Marriages and civil unions;
** FF3 - Divorces/disolutions;
** FF4 - Living with parents;
** FF6 - Born to teenage parents;

** Note FF5 - sole parent household - is defined in the work care and volunteering code;

*/ 

proc datasets lib=work kill;run;

** FF1 - Parenting;
proc sql;
	create table apcpop_cen_idd_2018_parenting1 as 
	select distinct a.snz_uid, a.idd_id, a.apc_age_in_years_nbr, a.adult15plus, a.adult18plus, a.snz_sex_gender_code,
		case when b.parent1_snz_uid is not null then 1 else 0 end as birth1
		FROM sandpit.apcpop_cen_idd_2018 a 
			left join dia.births b 
			on a.snz_uid=b.parent1_snz_uid and (b.dia_bir_birth_year_nbr<2018 or b.dia_bir_birth_year_nbr=2018 and b.dia_bir_birth_month_nbr<=6)
	order by a.snz_uid;
quit;
proc sql;
	create table apcpop_cen_idd_2018_parenting2 as 
	select distinct a.snz_uid,case when b.parent2_snz_uid is not null then 1 else 0 end as birth2
		FROM sandpit.apcpop_cen_idd_2018 a 
			left join dia.births b
			on a.snz_uid=b.parent2_snz_uid and (b.dia_bir_birth_year_nbr<2018 or b.dia_bir_birth_year_nbr=2018 and b.dia_bir_birth_month_nbr<=6)
	order by a.snz_uid;
quit;

** FF2 - Marriages and civil unions;
** FF3 - Divorces/disolutions;
proc sql;
	create table apcpop_cen_idd_2018_marrciv1 as 
	select distinct a.snz_uid,
		max(case when b.partnr1_snz_uid is not null then 1 else 0 end) as marriage1, 
		max(case when b.dia_mar_disolv_order_date is not null then 1 else 0 end) as divorce1,
		max(case when c.partnr1_snz_uid is not null then 1 else 0 end) as civil_union1,
		max(case when c.dia_civ_disolv_order_date is not null then 1 else 0 end) as cu_dissolve1
		FROM sandpit.apcpop_cen_idd_2018 a 
			left join dia.marriages b 
			on a.snz_uid=b.partnr1_snz_uid and b.dia_mar_marriage_date<="30jun2018"d
			left join dia.civil_unions c
			on a.snz_uid=c.partnr1_snz_uid and c.dia_civ_civil_union_date<="30jun2018"d
	group by a.snz_uid
	order by a.snz_uid;
quit;
proc sql;
	create table apcpop_cen_idd_2018_marrciv2 as 
	select distinct a.snz_uid, 
		max(case when d.partnr2_snz_uid is not null then 1 else 0 end) as marriage2,
		max(case when d.dia_mar_disolv_order_date is not null then 1 else 0 end) as divorce2,
		max(case when e.partnr2_snz_uid is not null then 1 else 0 end) as civil_union2,
		max(case when e.dia_civ_disolv_order_date is not null then 1 else 0 end) as cu_dissolve2
		FROM sandpit.apcpop_cen_idd_2018 a 
			left join dia.marriages d
			on a.snz_uid=d.partnr2_snz_uid and d.dia_mar_marriage_date<="30jun2018"d
			left join dia.civil_unions e
			on a.snz_uid=e.partnr2_snz_uid and e.dia_civ_civil_union_date<="30jun2018"d
	group by a.snz_uid
	order by a.snz_uid;
quit;

data family_friends(drop=marriage1 marriage2 civil_union1 civil_union2 divorce1 divorce2 cu_dissolve1 cu_dissolve2);
	merge apcpop_cen_idd_2018_marrciv1 apcpop_cen_idd_2018_marrciv2 apcpop_cen_idd_2018_parenting1 apcpop_cen_idd_2018_parenting2;
	by snz_uid;
	if adult15plus then do;
		if marriage1 or marriage2 then marriage=1;
		else marriage=0;
		if civil_union1 or civil_union2 then civil_union=1;
		else civil_union=0;
		if divorce1 or divorce2 then divorce=1;
		else divorce=0;
		if cu_dissolve1 or cu_dissolve2 then cu_dissolve=1;
		else cu_dissolve=0;
		if marriage or civil_union then ff2_marr_civil=1;
		else ff2_marr_civil=0;
		if divorce or cu_dissolve then ff3_divorce=1;
		else ff3_divorce=0;
		if birth1 or birth2 then ff1_parent=1;
		else ff1_parent=0;
		if ff2_marr_civil=0 then ff3_divorce=.;
	end;
	label ff1_parent='Ever been a parent indicator' ff2_marr_civil='Ever been in a marriage or civil union indicator'
			ff3_divorce='If ever married or civil union then ever divorced or dissolved';
run;

proc freq data=family_friends;
	where adult15plus=1;
	tables idd_id*ff2_marr_civil idd_id*ff3_divorce snz_sex_gender_code*idd_id*ff1_parent
			/nopercent nocol missing; 
run;

** FF6 - Born to teenage parents;
proc sql;
	create table apcpop_cen_idd_2018_teenparent as 
	select distinct a.snz_uid, case when (yrdif(mdy(b.dia_bir_parent1_birth_month_nbr,15,b.dia_bir_parent1_birth_year_nbr),
										mdy(b.dia_bir_birth_month_nbr,15,b.dia_bir_birth_year_nbr),'AGE')<20)
				or (yrdif(mdy(b.dia_bir_parent2_birth_month_nbr,15,b.dia_bir_parent2_birth_year_nbr),
										mdy(b.dia_bir_birth_month_nbr,15,b.dia_bir_birth_year_nbr),'AGE')<20 and dia_bir_parent2_birth_year_nbr is not null)
				then 1 else 0 end as ff6_teenparent
		FROM sandpit.apcpop_cen_idd_2018 a 
			inner join dia.births(where=(dia_bir_parent1_birth_month_nbr is not null and dia_bir_parent1_birth_year_nbr is not null)) b 
			on a.snz_uid=b.snz_uid
	order by a.snz_uid;
quit;

proc freq data=apcpop_cen_idd_2018_teenparent;
	tables ff6_teenparent;
run;

data family_friends;
	merge family_friends apcpop_cen_idd_2018_teenparent;
	by snz_uid;
run;

proc freq data=family_friends;
	tables idd_id*ff6_teenparent/nopercent nocol missing; 
run;

** FF4 - Living with parents;
** We identify this as someone living in the same household according to Census who is identified as a parent on the birth certificate;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table parents as
	select *
    from connection to odbc(
	select a.snz_uid,a.idd_id,a.apc_age_in_years_nbr,a.snz_cen_hhld_uid,b.parent1_snz_uid,b.parent2_snz_uid
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a 
		inner join IDI_Clean_202210.dia_clean.births b 
	on a.snz_uid=b.snz_uid
	order by a.snz_uid);
    disconnect from odbc;
quit;

** Now identify if either of the parents is living with the person at the Census date;
proc sql;
	create table living_parents1 as 
	select distinct a.snz_uid,max(case when b.snz_cen_hhld_uid is not null then 1 else 0 end) as living_parent1
	from parents a left join census.census_individual_2018 b
	on a.parent1_snz_uid=b.snz_uid and a.snz_cen_hhld_uid=b.snz_cen_hhld_uid
	where a.snz_cen_hhld_uid is not null
	group by a.snz_uid
	order by a.snz_uid;
run;

proc sql;
	create table living_parents2 as 
	select distinct a.snz_uid,max(case when b.snz_cen_hhld_uid is not null then 1 else 0 end) as living_parent2
	from parents a left join census.census_individual_2018 b
	on a.parent2_snz_uid=b.snz_uid and a.snz_cen_hhld_uid=b.snz_cen_hhld_uid
	where a.snz_cen_hhld_uid is not null
	group by a.snz_uid
	order by a.snz_uid;
run;

data family_friends;
	merge family_friends(in=a) living_parents1 living_parents2;
	by snz_uid;
	if a;
	if living_parent1=1 or living_parent2=1 then ff4_living_parent=1;
	else if living_parent1=0 or living_parent2=0 then ff4_living_parent=0;
run;

proc freq data=family_friends;
	tables apc_age_in_years_nbr*ff4_living_parent/nopercent nocol missing; 
run;

proc freq data=family_friends;
	tables idd_id*ff4_living_parent/nopercent nocol; 
	where apc_age_in_years_nbr<=14;
run;

proc freq data=family_friends;
	tables idd_id*ff4_living_parent/nopercent nocol; 
	where apc_age_in_years_nbr>=15;
run;

proc datasets lib=sandpit; delete family_friends; run;
data sandpit.family_friends; set family_friends; run;