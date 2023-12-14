**********************************************************************************************************;
**
** 4_IHC_Identify intellectually disabled sub-population
**
**********************************************************************************************************;
**
** Create 
**
** Input datasets:
**		- 
**
** Output datasets:
**		- 
**
** Keith McLeod, January 2023
**
**********************************************************************************************************;

** Note - before running this code, need to run SQL code from SWA which create tables in the sandpit.
** This has nbe
** Specifically:
** 		- SWA_downs_syndromme_v1.sql creates: cw_202210_nzbd_downs_syndromme
**		- SWA_ADHD_v2.sql: cw_202210_ADHD
**		- : cw_202210_nzbd_autism_spectrum_disorder
**		- 
**;

proc contents data=sandpit.cw_202210_ID;
proc contents data=sandpit.cw_202210_nzbd_downs_syndromme;
proc contents data=sandpit.cw_202210_ADHD2;
proc contents data=sandpit.cw_202210_nzbd_asd;
proc contents data=sandpit.cw_202210_nzbd_fetal_alcohol;
proc contents data=sandpit.cw_202210_nzbd_dev_delay;
proc contents data=sandpit.cw_202210_nzbd_fragile_x;
proc contents data=sandpit.cw_202210_nzbd_klinefelters;
proc contents data=sandpit.cw_202210_nzbd_spina_bifida;
proc contents data=sandpit.cw_202210_nzbd_cerebral_palsy;
run;

** Check how many people we are identifying in the APC;
proc datasets lib=sandpit;
	delete apcpop_cen_idd_2018;
run;
proc sql;
    connect to odbc(dsn=IDI_Clean_&extractdate._srvprd);
	create table sandpit.apcpop_cen_idd_2018 as
	select *, idd_id+idd_downs+idd_adhd+idd_asd+idd_fas+idd_dd+idd_fx+idd_ks+idd_sb+idd_cp as count
    from connection to odbc(
	select z.*,
		case when a.snz_uid is not null then 1 else 0 end as idd_id,
		case when b.snz_uid is not null then 1 else 0 end as idd_downs,
		case when c.snz_uid is not null then 1 else 0 end as idd_adhd,
		case when d.snz_uid is not null then 1 else 0 end as idd_asd,
		case when e.snz_uid is not null then 1 else 0 end as idd_fas,
		case when f.snz_uid is not null then 1 else 0 end as idd_dd,
		case when g.snz_uid is not null then 1 else 0 end as idd_fx,
		case when h.snz_uid is not null then 1 else 0 end as idd_ks,
		case when i.snz_uid is not null then 1 else 0 end as idd_sb,
		case when j.snz_uid is not null then 1 else 0 end as idd_cp
	from IDI_Sandpit."DL-MAA2022-54".population2018_census z 
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_ID a
	on z.snz_uid=a.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_downs_syndromme b
	on z.snz_uid=b.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_ADHD2 c
	on z.snz_uid=c.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_asd d
	on z.snz_uid=d.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_fetal_alcohol e
	on z.snz_uid=e.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_dev_delay f
	on z.snz_uid=f.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_fragile_x g
	on z.snz_uid=g.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_klinefelters h
	on z.snz_uid=h.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_spina_bifida i
	on z.snz_uid=i.snz_uid
	left join IDI_Sandpit."DL-MAA2022-54".cw_202210_nzbd_cerebral_palsy j
	on z.snz_uid=j.snz_uid
	order by z.snz_uid);
    disconnect from odbc;
quit;

proc sql; create table t as select distinct snz_uid from sandpit.apcpop_cen_idd_2018;quit;

proc tabulate data=sandpit.apcpop_cen_idd_2018;
	class apc_age_in_years_nbr count idd_id idd_downs idd_adhd idd_asd idd_fas idd_dd idd_fx idd_ks idd_sb idd_cp;
	tables apc_age_in_years_nbr ALL,(count idd_id idd_downs idd_adhd idd_asd idd_fas idd_dd idd_fx idd_ks idd_sb idd_cp);
	format apc_age_in_years_nbr agegroups.;
run;

proc tabulate data=sandpit.apcpop_cen_idd_2018;
	class idd_id idd_downs idd_adhd idd_asd idd_fas idd_dd idd_fx idd_ks idd_sb idd_cp;
	tables (idd_downs idd_adhd idd_asd idd_fas idd_dd idd_fx idd_ks idd_sb idd_cp),idd_id ALL;
	tables (idd_id idd_downs idd_adhd idd_asd idd_fas idd_fx idd_ks idd_sb idd_cp),idd_dd ALL;
run;

** Check ID against some other vars;
proc tabulate data=sandpit.apcpop_cen_idd_2018 missing;
	class idd_id apc_employed_ind apc_ethnicity_grp1_nbr apc_ethnicity_grp2_nbr apc_ethnicity_grp3_nbr apc_ethnicity_grp4_nbr apc_ethnicity_grp5_nbr apc_ethnicity_grp6_nbr
		apc_fertility_code apc_hst_qual_code snz_sex_gender_code;
	tables (apc_employed_ind apc_ethnicity_grp1_nbr apc_ethnicity_grp2_nbr apc_ethnicity_grp3_nbr apc_ethnicity_grp4_nbr apc_ethnicity_grp5_nbr apc_ethnicity_grp6_nbr
		apc_fertility_code apc_hst_qual_code snz_sex_gender_code),idd_id*COLPCTN ALL;
run;

** Now add an indicator of whether they are receiving a residential care subsidy or residential support subsidy;
** Now we want to identify RSS;
data apcpop_cen_idd_2018; set sandpit.apcpop_cen_idd_2018;run;

proc sql;
	create table supps as
	select distinct a.snz_uid,a.idd_id,c.beg_date,c.end_date,c.caretype
	from apcpop_cen_idd_2018 a
	inner join security.concordance b
	on a.snz_uid=b.snz_uid
	inner join msdadhoc.msd_prntsupo_202212(where=(supp='830')) c
	on b.snz_msd_uid=c.snz_msd_uid
	order by a.snz_uid;
quit;

proc freq data=supps;
	table caretype;
run;

data supps2;
	set supps;
	by snz_uid;
	where beg_date<='30jun2018'd and end_date>='01apr2018'd;
	rcs=0; rss=0;
	if caretype='1' then rcs=1;
	else rss=1;
	if last.snz_uid;
run;

proc sort data=apcpop_cen_idd_2018;by snz_uid;run;
data apcpop_cen_idd_2018;
	merge apcpop_cen_idd_2018 supps2;
	by snz_uid;
	if rss=. then rss=0;
	if rcs=. then rcs=0;
	if rss or rcs then rss_rcs=1;
	else rss_rcs=0;
	if apc_age_in_years_nbr>64 then adult65plus=1;
	else adult65plus=0;
run;

proc freq data=apcpop_cen_idd_2018;
	tables (rss rcs rss_rcs)*idd_id/nopercent norow nofreq;
	where adult18to64=1;
run;

proc freq data=apcpop_cen_idd_2018;
	tables (rss rcs rss_rcs)*idd_id/nopercent norow nofreq;
	where adult65plus=1;
run;

proc datasets lib=sandpit;
	delete apcpop_cen_idd_2018_res;
run;
data sandpit.apcpop_cen_idd_2018_res; set apcpop_cen_idd_2018;run;