proc contents data=sandpit.cw_202210_ID;

proc sql;
    connect to odbc(dsn=IDI_Sandpit_srvprd);
	create table id_source as
	select *
    from connection to odbc(
	select a.snz_uid,a.apc_age_in_years_nbr,a.apc_ethnicity_grp1_nbr,a.apc_ethnicity_grp2_nbr,a.apc_ethnicity_grp3_nbr,a.apc_ethnicity_grp4_nbr,
			a.snz_sex_gender_code,case when b.snz_uid is not null then 1 else 0 end as idd_id,b.*
	from IDI_Sandpit."DL-MAA2022-54".population2018_census a left join IDI_Sandpit."DL-MAA2022-54".cw_202210_ID b
	on a.snz_uid=b.snz_uid
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc freq data=id_source;
	tables apc_age_in_years_nbr*(source_:)/nopercent nocol norow;
	where idd_id=1;
	format apc_age_in_years_nbr agethree.;
run;

** Main sources are ORS, PUB, PRIMHD, MHINC, INCP, and SOC;

proc summary data=id_source nway;
	class apc_age_in_years_nbr source_:;
	output out=id_source_N(rename=(_freq_=N));
	format apc_age_in_years_nbr agethree.;
run;

data id_source_N;
	set id_source_N;
	age=put(apc_age_in_years_nbr,agethree.)*1;
run;

data frame;
	do age=1 to 3;
	do source_ORS=0 to 1;
		do source_PUB=0 to 1;
			do source_PRIMHD=0 to 1;
				do source_PRI=0 to 1;	
					do source_CYF=0 to 1;
						do source_IRAI=0 to 1;
							do source_MHINC=0 to 1;
								do source_INCP=0 to 1;	
									do source_SOC=0 to 1;
										do source_NNP=0 to 1;
											output;
										end;
									end;
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;
	end;
run;

data analysis_data(drop=_type_);
	merge frame id_source_N;
	by age source_ORS	source_PUB	source_PRIMHD	source_PRI	source_CYF	source_IRAI	source_MHINC	source_INCP	source_SOC	source_NNP;
	if sum(source_ORS,source_PUB,source_PRIMHD,source_PRI,source_CYF,source_IRAI,source_MHINC,source_INCP,source_SOC,source_NNP)>0 and N=. then N=0;
run;

** Saturated model no covariates;
proc genmod data=analysis_data;
model n=age source_ORS source_PUB source_PRIMHD source_PRI source_CYF source_IRAI source_MHINC source_INCP source_SOC source_NNP/dist=poisson obstats;
output out=llmodel predicted=predicted;
run;

*AIC (smaller is better)
*  18174.6961  

** Now try a simpler model without some of the smaller sources;
proc summary data=id_source nway;
	class source_ORS	source_PUB	source_PRIMHD	source_MHINC	source_INCP	source_SOC;
	output out=id_source_N(rename=(_freq_=N));
run;

data frame;
	do source_ORS=0 to 1;
		do source_PUB=0 to 1;
			do source_PRIMHD=0 to 1;
							do source_MHINC=0 to 1;
								do source_INCP=0 to 1;	
									do source_SOC=0 to 1;
											output;
									end;
								end;
							end;
			end;
		end;
	end;
run;

data id_source_N;
	set id_source_N;
	if sum(of source:)>0;
run;

data analysis_data(drop=_type_);
	merge frame id_source_N;
	by source_ORS	source_PUB	source_PRIMHD	source_MHINC	source_INCP	source_SOC;
	if _N_ ne 1 and N=. then N=0;
run;

proc genmod data=analysis_data;
model n=source_ORS	source_PUB	source_PRIMHD	source_MHINC	source_INCP	source_SOC	/dist=poisson obstats;
output out=llmodel2 predicted=predicted;
run;