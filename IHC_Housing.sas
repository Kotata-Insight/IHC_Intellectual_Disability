/**Creating Knowledge and Skill domain indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Luisa Beltran-Castillon 
Start date - 24/02/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

** HS1 - Social housing
** HS2 - Transience
** HS3 - Housing quality (cold/mouldy/damp)
** HS4 - Household crowding

*/ 

data apcpop_cen_idd_2018; set sandpit.apcpop_cen_idd_2018; run;

** HS3 - Housing quality (cold/mouldy/damp)
** HS4 - Household crowding;
proc freq data=apcpop_cen_idd_2018;
table (house_damp house_mould house_crowd)*idd_id / nofreq norow nopercent missing;
run;

data housing;
	set apcpop_cen_idd_2018(keep=snz_uid snz_cen_uid idd_id apc_age_in_years_nbr census_link adult18plus adult15plus
			house_mould house_damp house_crowd);
	if house_damp in (1,2) or house_mould in (1,2) then hs3_mouldy_damp=1;
	else if house_damp in (.,4,7,9) and house_mould in (.,4,7,9) then hs3_mouldy_damp=.;
	else hs3_mouldy_damp=0;
	if house_crowd in (1,2) then hs4_crowded=1;
	else if house_crowd=. then hs4_crowded=.;
	else hs4_crowded=0;
run;

proc freq data=housing;
table (hs3_mouldy_damp hs4_crowded)*idd_id / nofreq norow nopercent missing;
run;

proc datasets lib=sandpit; delete housing;run;
data sandpit.housing; set housing; run;

***************************************************************************************************;
** HS2 Transience;

** Number of address changes in past 5 years;
** Firstly select all addresses in past 5 years;
proc sql;
	create table apcpop_cen_idd_2018_address as 
	select distinct a.snz_uid, a.idd_id, count(b.snz_idi_address_register_uid) as num_address
	FROM apcpop_cen_idd_2018 a 
			inner join snzdata.address_notification(where=(snz_idi_address_register_uid is not null)) b 
			on a.snz_uid=b.snz_uid and ('01jul2013'd <= b.ant_notification_date <= '30jun2018'd or
					'01jul2013'd <= b.ant_replacement_date <= '30jun2018'd)
	group by a.snz_uid
	order by a.snz_uid;
quit;

data housing;
	merge sandpit.housing apcpop_cen_idd_2018_address;
	by snz_uid;
	rename num_address=hs2_transience;
run;

proc summary data=housing nway mean median print;
	class idd_id;
	var hs2_transience;
run;

proc datasets lib=sandpit; delete housing;run;
data sandpit.housing; set housing; run;

***************************************************************************************************;
** HS1 Social housing;

** Firstly run the SIAL SQL code HNZ_register_events.sql in I:\MAA2022-54\code\definitions from social investment analytical layer;
** This creates a view in the sandpit called [IDI_UserCode].[DL-MAA2022-54].[sial_HNZ_register_events];

proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table social_housing as
	select * from connection to odbc
	(select distinct a.snz_cen_hhld_uid,b.*
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a inner join IDI_UserCode."DL-MAA2022-54".sial_HNZ_register_events b
	on a.snz_uid=b.snz_uid and start_date<'2018-07-01' and end_date>'2018-03-31'
	order by a.snz_cen_hhld_uid);
	disconnect from odbc;
quit;

proc sort data=social_housing nodupkey;
	by snz_cen_hhld_uid;
	where snz_cen_hhld_uid ne .;
run;

** We have too few households;

****** THINK ABOUT LOOKING AT THIS AGAIN LATER;