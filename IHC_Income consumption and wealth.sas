/**Creating Income, consumption and wealth measures

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 28/02/2023
Code location - I:\MAA2022-54\code

Core population from sandpit.apcpop_cen_idd_2018

We get income from the APC and household information from 2018 Census;
Disposable income is calculated by removing tax paid which is taken from EMS, IR3s and PTS;

Output datasets: sandpit.inc_cons_and_wealth

Measures:
ICW1 - Total personal income;
ICW2 - Total equivalised household disposable income;
ICW3 - Neighbourhood deprivation;
ICW4 - Access to internet;
*/ 

** ICW1 - Total personal income;
** ICW2 - Total equivalised household disposable income;

** Calculate the number of children and adults in each HH and sum incomes for all Census HHs;
proc sql;
	create table hh_comp as
	select snz_cen_hhld_uid,sum(case when input(cen_ind_age_code,3.)>=14 then 1 else 0 end) as adult14plus,
			sum(case when input(cen_ind_age_code,3.)<14 then 1 else 0 end) as childless14
	from census.census_individual_2018(where=(snz_cen_hhld_uid ne .))
	group by snz_cen_hhld_uid
	order by snz_cen_hhld_uid;
quit;

** Extract tax data for each individual for the 2018 tax year;
proc sql;
	create table ems_tax as 
	select distinct snz_uid,sum(-ir_ems_paye_deductions_amt) as ems_tax 
	from ir.ird_ems
	where year(ir_ems_return_period_date)=2018
	group by snz_uid
	order by snz_uid;
quit;

proc sql;
	create table ir3_tax as 
	select distinct snz_uid,sum(ir_ir3_tax_on_taxable_income_amt)+sum(ir_ir3_tot_rebate_amt) as ir3_tax 
	from ir.ird_rtns_keypoints_ir3
	where year(ir_ir3_return_period_date)=2018
	group by snz_uid
	order by snz_uid;
quit;

proc sql;
	create table pts_tax as 
	select distinct snz_uid,sum(ir_pts_tot_tax_on_inc_amt)-sum(ir_pts_tot_earner_premium_amt) as pts_tax 
	from ir.ird_pts
	where year(ir_pts_return_period_date)=2018
	group by snz_uid
	order by snz_uid;
quit;

proc sql;
	create table net_inc as
	select distinct a.snz_uid,a.snz_cen_hhld_uid,coalesce(a.apc_income_tot_amt,0) as income,coalesce(b.ems_tax,0) as ems_tax,
		case when c.ir3_tax>0 then sum(c.ir3_tax,-b.ems_tax) else 0 end as ir3_tax,
		case when d.pts_tax>0 then sum(d.pts_tax,-b.ems_tax) else 0 end as pts_tax,
		calculated ems_tax+calculated ir3_tax+calculated pts_tax as tot_tax,calculated income-calculated tot_tax as net_inc
	from sandpit.apcpop_cen_idd_2018 a
	left join ems_tax b
	on a.snz_uid=b.snz_uid
	left join ir3_tax c
	on a.snz_uid=c.snz_uid
	left join pts_tax d
	on a.snz_uid=d.snz_uid
	order by a.snz_uid;
quit;

** And add up to HH level;
proc sql;
	create table net_inc_hh as 
	select snz_cen_hhld_uid,sum(net_inc) as net_hh_inc
	from net_inc(where=(snz_cen_hhld_uid ne .))
	group by snz_cen_hhld_uid
	order by snz_cen_hhld_uid;
quit;

** And calculate equivalised hh disposable incomes;
proc sql;
	create table hh_disp_inc as
	select a.snz_cen_hhld_uid,a.net_hh_inc,b.adult14plus,b.childless14,
			a.net_hh_inc/(1+.5*(b.adult14plus-1)+.3*b.childless14) as icw2_equiv_hh_inc
	from net_inc_hh a left join hh_comp b
	on a.snz_cen_hhld_uid=b.snz_cen_hhld_uid
	order by snz_cen_hhld_uid;
quit;

** Now add this onto our individual data;
proc sql;
 	create table apcpop_cen_idd_2018_hhinc as
	select a.*,b.icw2_equiv_hh_inc
	from sandpit.apcpop_cen_idd_2018 a left join hh_disp_inc b
	on a.snz_cen_hhld_uid=b.snz_cen_hhld_uid
	order by a.idd_id,a.adult15plus,a.snz_uid;
quit;

proc means data=hh_disp_inc median;
	var icw2_equiv_hh_inc;
	output out=med_hh_equiv_inc median=med_hh_equiv_inc;
	where icw2_equiv_hh_inc not in (0,.);
run;

data apcpop_cen_idd_2018_hhincb;
	set apcpop_cen_idd_2018_hhinc;
	_type_=0;
run;

data apcpop_cen_idd_2018_hhincb;
	merge apcpop_cen_idd_2018_hhincb med_hh_equiv_inc;
	by _type_;
	if icw2_equiv_hh_inc not in (0,.) then do;
		if icw2_equiv_hh_inc<0.6*med_hh_equiv_inc then lowinc_60=1;
		else lowinc_60=0;
		if icw2_equiv_hh_inc<0.5*med_hh_equiv_inc then lowinc_50=1;
		else lowinc_50=0;
	end;
run;

proc tabulate data=apcpop_cen_idd_2018_hhincb;
	class idd_id adult18plus lowinc_50 lowinc_60;
	table (adult18plus*idd_id),(lowinc_50 lowinc_60)*ROWPCTN*ALL N;
run;

proc sql;
 	create table summ as
	select idd_id,count(apc_income_tot_amt) as n_inc,nmiss(apc_income_tot_amt) as n_miss_inc,median(apc_income_tot_amt) as med_income
 	from apcpop_cen_idd_2018_hhincb(where=(adult18plus=1))
	group by idd_id
	order by idd_id;
quit;

data inc_cons_and_wealth;
	set apcpop_cen_idd_2018_hhincb(keep=snz_uid snz_cen_uid idd_id apc_age_in_years_nbr adult15plus adult18plus apc_income_tot_amt icw2_equiv_hh_inc med_hh_equiv_inc icw2_lowinc_50 icw2_lowinc_60);
	rename apc_income_tot_amt=icw1_income lowinc_50=icw2_lowinc_50 lowinc_60=icw2_lowinc_60;
	label icw1_income='Total personal income' icw2_equiv_hh_inc='Equivalised disposable household income before housing costs' icw2_lowinc_50='Equiv disp BHC HH income < 50% of median'
		icw2_lowinc_60='Equiv disp BHC HH income < 60% of median';
run;

proc datasets lib=sandpit; delete inc_cons_and_wealth; run;
data sandpit.inc_cons_and_wealth; set inc_cons_and_wealth; run;

** ICW3 - Neighbourhood deprivation;
** ICW4 - Internet access;

proc freq data=sandpit.apcpop_cen_idd_2018;
	tables telecom_access;
run;

** Add on NZDEP;
** First meshblock - according to data dictionary, MB is 2021 version in APC;
proc sql;
	create table apc_pop_dep as
	select a.snz_uid,a.idd_id,a.telecom_access,a.apc_age_in_years_nbr,a.adult15plus,a.adult18plus,b.mb2018_code
	from sandpit.apcpop_cen_idd_2018 a left join metadata.meshblock_concordance b
	on a.meshblock_code = b.mb2021_code
	order by snz_uid;
quit;

** Then NZDep;
proc sql;
	create table apc_pop_dep2 as
	select a.*, input(b.NZDep2018,2.) as NZDEP18
	from apc_pop_dep a left join old_meta.DepIndex2018_MB2018 b
	on a.mb2018_code = b.mb2018_code
	order by snz_uid;
quit;

proc freq data=apc_pop_dep2;
	tables NZDEP18*idd_id/missing norow nopercent nofreq;
run;

data inc_cons_and_wealth;
	merge sandpit.inc_cons_and_wealth apc_pop_dep2(keep=snz_uid NZDEP18 telecom_access);
	by snz_uid;
	if NZDEP18=10 then highdep_dec=1;
	else if NZDEP18=. then highdep_dec=.;
	else highdep_dec=0;
	if NZDEP18 in (9,10) then highdep_quint=1;
	else if NZDEP18=. then highdep_quint=.;
	else highdep_quint=0;

	if index(telecom_access,'04')>0 then icw4_internet=1;
	else if telecom_access in ('','77','99') then icw4_internet=.;
	else icw4_internet=0;
	
	rename NZDEP18=icw3_nzdep18;
	label highdep_dec='Living in most deprived decile' highdep_quint='Living in most deprived quintile'
			icw3_nzdep18='NZ deprivation index (NZDEP) 2018 decile'
			icw4_internet='Access to internet';
run;

proc freq data=inc_cons_and_wealth;
table (icw3_nzdep18 icw4_internet)*idd_id / nofreq norow nopercent missing;
run;

proc datasets lib=sandpit; delete inc_cons_and_wealth; run;
data sandpit.inc_cons_and_wealth; set inc_cons_and_wealth; run;