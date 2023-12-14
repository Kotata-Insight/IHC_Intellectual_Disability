/**Creating Life expectancy estimates

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 24/02/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

Produce a basic demographic profile of the ID and non-ID populations - by age, sex, ethnicity etc.;

*/ 

proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table apcpop_cen_idd_2018_desc as
	select * from connection to odbc
	(select a.*,b.icw3_nzdep18,c.region_name_text as region_name,c.ta_name_text as ta_name,d.IUR2022_V1_00_NAME as urban_rural,d.DHB2015_V1_00_NAME as dhb_name,
			e.cen_fml_family_type_code as fam_type,e.cen_fml_chld_dpnd_fmly_type_code as fam_dep_type,
			f.cen_exf_fam_type_code as exfam_type,g.cen_hhd_composn_code as hh_comp,
			g.cen_hhd_dpnd_chd_hhld_compn_code as hh_dep_chd_comp,g.cen_hhd_usual_resdnt_count_code as hh_usualres,
			g.cen_hhd_usl_resdnt_adlt_cnt_code as hh_usualres_adult,g.cen_hhd_usl_resdnt_u15_cnt_code as hh_usualres_child
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018_res a left join idi_sandpit."DL-MAA2022-54".inc_cons_and_wealth b
	on a.snz_uid=b.snz_uid
	left join idi_clean_&extractdate..metadata.meshblock_current c
	on a.meshblock_code=c.meshblock_code
	left join idi_metadata_&extractdate..data.mb22_higher_geo_v1 d
	on a.meshblock_code=d.MB2022_V1_00
	left join IDI_Clean_&extractdate..cen_clean.census_family_2018 e
	on a.snz_cen_fam_uid=e.snz_cen_fam_uid
	left join IDI_Clean_&extractdate..cen_clean.census_ext_family_2018 f
	on a.snz_cen_extfam_uid=f.snz_cen_extfam_uid
	left join IDI_Clean_&extractdate..cen_clean.census_household_2018 g
	on a.snz_cen_hhld_uid=g.snz_cen_hhld_uid
	)
	order by idd_id,snz_uid;
	disconnect from odbc;
quit;

%let desc_vars=apc_age_in_years_nbr age5 sexbyage apc_ethnicity_grp1_nbr apc_ethnicity_grp2_nbr apc_ethnicity_grp3_nbr apc_ethnicity_grp4_nbr 
				apc_ethnicity_grp5_nbr apc_ethnicity_grp6_nbr snz_sex_gender_code rss rcs rss_rcs icw3_nzdep18 region_name ta_name urban_rural dhb_name
				fam_type fam_dep_type hh_comb hh_usualres_adult hh_usualres_child census_link 
				idd_downs idd_adhd idd_asd idd_fas idd_dd idd_fx idd_ks idd_sb idd_cp;

data apcpop_cen_idd_2018_desc;
	length sexbyage hh_comb $ 40;
	set apcpop_cen_idd_2018_desc;
	age5=apc_age_in_years_nbr;
	sexbyage=left(put(snz_sex_gender_code,$sex.))||' '||put(apc_age_in_years_nbr,agegroups.);
	if fam_dep_type in ('24','25','26','27','34','35','36','37') then fam_dep_type='99';
	else if snz_cen_uid ne '' and fam_dep_type='' then fam_dep_type='00';
	if snz_cen_uid ne '' and fam_type='' then fam_type='00';
	if hh_usualres_adult in ('00','') or hh_usualres_child='' then hh_comb='';
	else hh_comb=trim(put(hh_usualres_adult,$num_people.))||' adults,'||trim(put(hh_usualres_child,$num_people.))||' children';
run;

%macro run_desc(subset=,subpop=);
ods results off;
proc surveymeans data=apcpop_cen_idd_2018_desc missing;
	class &desc_vars.;
	var &desc_vars.;
	ods output Statistics=descrip_id2(drop=mean stderr lowerclmean upperclmean);
	format apc_age_in_years_nbr agegroups. age5 age5yr. snz_sex_gender_code $sex. fam_type $fam_type. fam_dep_type $fam_dep_type.
		hh_usualres_adult hh_usualres_child $num_people.;
	where idd_id in (0,1)
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
run;

proc surveymeans data=apcpop_cen_idd_2018_desc missing;
	by idd_id;
	class &desc_vars.;
	var &desc_vars.;
	ods output Statistics=descrip_id(drop=mean stderr lowerclmean upperclmean);
	format apc_age_in_years_nbr agegroups. age5 age5yr. snz_sex_gender_code $sex. fam_type $fam_type. fam_dep_type $fam_dep_type.
		hh_usualres_adult hh_usualres_child $num_people.;
	where idd_id in (0,1)
		%if %sysevalf(%superq(subset)~=,boolean) %then %do; and &subset. %end; ;
run;
ods results on;

data desc_all_&subpop.(drop=VarLabel);
	length subpop $ 80;
	set descrip_id descrip_id2;
	subpop="&subpop.";
run;

** Apply RR3 etc;
data desc_all_&subpop._confid;
	set desc_all_&subpop.;
	if N<6 then N=.;
run;

%rr3(desc_all_&subpop._confid,desc_all_&subpop._confid,N);

data desc_all_&subpop._confid;
	set desc_all_&subpop._confid;
	if N=0 then N=.;
run;
%mend run_desc;

%run_desc(subset=,subpop=);
%run_desc(subset=apc_age_in_years_nbr<=14,subpop=child);
%run_desc(subset=apc_age_in_years_nbr>=15,subpop=adult);
%run_desc(subset=snz_sex_gender_code='1',subpop=sexM);
%run_desc(subset=snz_sex_gender_code='2',subpop=sexF);
%run_desc(subset=apc_ethnicity_grp1_nbr=1,subpop=ethE);
%run_desc(subset=apc_ethnicity_grp2_nbr=1,subpop=ethM);
%run_desc(subset=apc_ethnicity_grp3_nbr=1,subpop=ethP);
%run_desc(subset=apc_ethnicity_grp4_nbr=1,subpop=ethA);
%run_desc(subset=apc_ethnicity_grp5_nbr=1,subpop=ethME);
%run_desc(subset=apc_ethnicity_grp6_nbr=1,subpop=ethO);
%run_desc(subset=idd_downs=1,subpop=downs);
%run_desc(subset=idd_adhd=1,subpop=adhd);
%run_desc(subset=idd_asd=1,subpop=asd);
%run_desc(subset=rss_rcs=1,subpop=res);
%run_desc(subset=rss_rcs=0,subpop=res0);

data project.desc_all;
	set desc_all_ desc_all_child desc_all_adult desc_all_sexM desc_all_sexF desc_all_ethE desc_all_ethM desc_all_ethP desc_all_ethA desc_all_ethME desc_all_ethO 
		desc_all_downs desc_all_adhd desc_all_asd desc_all_res desc_all_res0;
run;

data project.desc_all_confid;
	set desc_all__confid desc_all_child_confid desc_all_adult_confid desc_all_sexM_confid desc_all_sexF_confid desc_all_ethE_confid desc_all_ethM_confid desc_all_ethP_confid desc_all_ethA_confid desc_all_ethME_confid desc_all_ethO_confid 
		desc_all_downs_confid desc_all_adhd_confid desc_all_asd_confid desc_all_res_confid desc_all_res0_confid;
run;

proc export data=project.desc_all dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes NOT FOR RELEASE.xlsx' replace;
	sheet='Descriptive analysis';
run;

proc export data=project.desc_all_confid dbms=xlsx label
	outfile='/nas/DataLab/MAA/MAA2022-54/excel/ID and non-ID description and outcomes.xlsx' replace;
	sheet='Descriptive analysis';
run;