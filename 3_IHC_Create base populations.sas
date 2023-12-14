**********************************************************************************************************;
**
** 3_IHC_Create base populations
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
** Keith McLeod, January 2022
**
**********************************************************************************************************;

** Create a dataset of the 2018 and 2021 administrative resident populations;
proc datasets lib=sandpit; delete population2018; run;
proc sql;
    connect to odbc(dsn=IDI_Clean_&extractdate._srvprd);
	create table sandpit.population2018 as
	select *
    from connection to odbc(
	select a.*,b.*
	from IDI_Clean_&extractdate..data.apc_time_series a left join IDI_Clean_&extractdate..data.apc_constants b
	on a.snz_uid=b.snz_uid
	where a.apc_ref_year_nbr=2018
	order by a.snz_uid);
    disconnect from odbc;
quit;

** Link to 2018 popn Census;
proc freq data=census.census_individual_2018;
	tables cen_ind_record_type_code;
run;

proc datasets lib=sandpit; delete population2018_census; run;
/* Also keep Census variables which we want for our indicators */
proc sql;
    connect to odbc(dsn=IDI_Clean_&extractdate._srvprd);
	create table sandpit.population2018_census as
	select *
    from connection to odbc(
	select 
		a.snz_uid,
		a.apc_age_in_years_nbr,
		case when a.apc_age_in_years_nbr>=15 then 1 else 0 end as adult15plus,
		case when a.apc_age_in_years_nbr>=18 then 1 else 0 end as adult18plus,
		case when a.apc_age_in_years_nbr between 15 and 64 then 1 else 0 end as adult15to64,
		case when a.apc_age_in_years_nbr between 18 and 64 then 1 else 0 end as adult18to64,
		case when a.apc_age_in_years_nbr >64 then 1 else 0 end as adult65plus,
		case when a.apc_age_in_years_nbr<15 then 1 else 0 end as childunder15,
		case when a.apc_age_in_years_nbr<18 then 1 else 0 end as childunder18,
		case when a.apc_age_in_years_nbr between 15 and 24 then 1 else 0 end as youth15to24,
		a.apc_arrv_nz_month_nbr,a.apc_arrv_nz_year_nbr,a.apc_birth_country_code,a.apc_employed_ind,a.apc_study_prtpcn_code,
		a.apc_ethnicity_grp1_nbr,a.apc_ethnicity_grp2_nbr,a.apc_ethnicity_grp3_nbr,a.apc_ethnicity_grp4_nbr,a.apc_ethnicity_grp5_nbr,a.apc_ethnicity_grp6_nbr,
		a.apc_fertility_code,a.apc_hst_qual_code,a.apc_income_tot_amt,a.apc_overseas_born_ind,a.meshblock_code,a.region_code,
		a.snz_birth_month_nbr,a.snz_birth_year_nbr,a.snz_deceased_month_nbr,a.snz_deceased_year_nbr,a.snz_sex_gender_code,a.talb_code,a.years_since_arrival_in_nz,
		b.snz_cen_uid,c.snz_cen_dwell_uid,d.snz_cen_fam_uid,e.snz_cen_extfam_uid,f.snz_cen_hhld_uid,
		case when b.snz_uid is not null then 1 else 0 end as census_link,
		b.cen_ind_record_type_code as record_type,
		b.cen_ind_child_depend_code as child_depend_code, 
		b.cen_ind_hst_qual_code as highest_qual,
		b.cen_ind_emplnt_stus_code as emp_status, 
		b.cen_ind_wklfs_code as lf_status,
		b.cen_ind_unpaid_activities_code as unpaid_acts,
		b.cen_ind_ttl_inc_code as personal_income,
		c.cen_dwl_telecomm_access_code as telecom_access,
		c.cen_dwl_damp_code as house_damp,
		c.cen_dwl_mould_code as house_mould,
		d.cen_fml_total_income_family_code as income_fam,
		e.cen_exf_ttl_income_ext_fml_code as income_extfam,
		f.cen_hhd_total_hhld_income_code as income_hhld,
		f.cen_hhd_can_crowding_code as house_crowd
	from IDI_Sandpit."DL-MAA2022-54".population2018 a 
	left join IDI_Clean_&extractdate..cen_clean.census_individual_2018 b
	on a.snz_uid=b.snz_uid 
	left join IDI_Clean_&extractdate..cen_clean.census_dwelling_2018 c
	on b.ur_snz_cen_dwell_uid=c.snz_cen_dwell_uid
	left join IDI_Clean_&extractdate..cen_clean.census_family_2018 d
	on b.snz_cen_fam_uid=d.snz_cen_fam_uid
	left join IDI_Clean_&extractdate..cen_clean.census_ext_family_2018 e
	on b.snz_cen_extfam_uid=e.snz_cen_extfam_uid
	left join IDI_Clean_&extractdate..cen_clean.census_household_2018 f
	on b.snz_cen_hhld_uid=f.snz_cen_hhld_uid
	where b.cen_ind_record_type_code is NULL or b.cen_ind_record_type_code in (3,4)
	order by snz_uid);
    disconnect from odbc;
quit;

** How many on the APC do we have Census data for?;
proc freq data=sandpit.population2018_census;
	tables census_link;
run;