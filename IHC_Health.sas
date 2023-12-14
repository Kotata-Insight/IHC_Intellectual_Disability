 /** Health indicators

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Keith McLeod
Start date - 17/03/2023
Code location - I:\MAA2022-54\code

Core population saved in sandpit.apcpop_cen_idd_2018

Output datasets: sandpit.health

** H2 - Coronary Heart Disease or treatment
** H10 - Injury-related public hospital discharges;
** H11 - Dental treatment public hospital discharges;
** H27 - Emergency department visits
** H28 - Potentially avoidable hospitalisations;
** H29 - Primary health care costs per person;

** Some indicators require SQL code from SWA to be run first;
** These are:
**  - 

** Note: H1 life expectancy at birth is in a separate code file - IHC_Life expectancy.
*/ 

*** Firstly hospitalisations
** H10 - Injury-related public hospital discharges;
** H11 - Dental treatment public hospital discharges;
** H28 - Potentially avoidable hospitalisations;

/*	Avoidable hospitalisations
	PAH = Preventable by population level intervention /health programs/immunisation etc

PAH code was provided by Steven Johnston at MOH*/

PROC SQL;
	CONNECT TO odbc(dsn="idi_clean_&extractdate._srvprd" );
 	CREATE TABLE nmds0 AS 
	SELECT  
		SNZ_UID
		,MOH_DIA_CLINICAL_CODE
		,MOH_EVT_EVENT_ID_NBR
		,MOH_EVT_EVST_DATE as startdate_hosp
		,MOH_EVT_EVEN_DATE as enddate_hosp
		,MOH_EVT_ADM_TYPE_CODE
		,MOH_EVT_BIRTH_YEAR_NBR
		,MOH_EVT_BIRTH_MONTH_NBR
		,MOH_EVT_PUR_UNIT_TEXT
		,MOH_EVT_PURCHASER_CODE
		,MOH_EVT_HLTH_SPEC_CODE	
		,MOH_EVT_END_TYPE_CODE as end_typ 
	FROM CONNECTION TO ODBC(
		SELECT
			A.MOH_DIA_EVENT_ID_NBR
			,A.MOH_DIA_CLINICAL_CODE
		,B.SNZ_UID
		,B.MOH_EVT_EVENT_ID_NBR
		,B.MOH_EVT_EVST_DATE
		,B.MOH_EVT_EVEN_DATE
		,B.MOH_EVT_ADM_TYPE_CODE
		,B.MOH_EVT_BIRTH_YEAR_NBR
		,B.MOH_EVT_BIRTH_MONTH_NBR
		,B.MOH_EVT_PUR_UNIT_TEXT
		,B.MOH_EVT_PURCHASER_CODE
		,B.MOH_EVT_HLTH_SPEC_CODE
		,B.MOH_EVT_END_TYPE_CODE
		from moh_clean.pub_fund_hosp_discharges_diag as A
	left join
		moh_clean.pub_fund_hosp_discharges_event as B
	on A.moh_dia_event_id_nbr= B.moh_evt_event_id_nbr
	where a.moh_dia_clinical_sys_code in ('10','11','12','13','14','15') and a.moh_dia_diagnosis_type_code='A'
	order by b.snz_uid,b.moh_evt_event_id_nbr
);
DISCONNECT FROM ODBC;
QUIT;

** Add external cause codes;
PROC SQL;
 	CREATE TABLE nmds0b AS 
		SELECT
			A.snz_uid,a.MOH_EVT_EVENT_ID_NBR,B.MOH_DIA_CLINICAL_CODE as ecode
		from nmds0 as A
			inner join
			moh.pub_fund_hosp_discharges_diag as B
	on A.MOH_EVT_EVENT_ID_NBR= B.moh_dia_event_id_nbr and b.moh_dia_diagnosis_type_code='E'
	order by a.snz_uid,a.moh_evt_event_id_nbr;
QUIT;

proc format;
  value $Ecode 
	'V010' - 'V899','V910' - 'V919','V930' - 'V978','V98','V99','Y850','Y859' = 'Transport accidents'
	'W00' - 'W19' = 'Falls'
	'X00' - 'X19' = 'Fires and thermal causes'
	'W65' - 'W74','V900' - 'V909','V920' - 'V929' = 'Drowning'
	'X40' - 'X49' = 'Poisoning'
	'W20' - 'W490' = 'Mechanical force (inanimate)'
	'W53' - 'W598','W610' - 'W619','X20' - 'X278','X29' = 'Animal-related injuries'
	'X50' ='Overexertion and strenuous or repetitive movements'
	'X58','X59','Y86','Y899' ='Unspecified external causes'

	'X60' - 'X84','Y870' = 'Intentional self-harm'
	'X85' - 'X99','Y0000' - 'Y0909','Y871','X9900' - 'X9999','Y3501' - 'Y369','Y890','Y891' = 'Assault'

	'Y400' - 'Y849','Y880' - 'Y883','Y95','U900' = 'Adverse effects of treatment'

	'Y10' - 'Y34','Y872'='Undetermined intent'
	other = 'Other unintentional injuries';

run;

data nmds0c;
	set nmds0b;
	ecause = put(ecode, $ecode.);
	if ecause in ('Adverse effects of treatment','Unspecified external causes','Undetermined intent') then output;
run;

proc sort data=nmds0c nodupkey;
	by snz_uid moh_evt_event_id_nbr;
run;

proc freq data=nmds0; tables startdate_hosp;run;

%let indat=sandpit.apcpop_cen_idd_2018;

** Injury diagnosis codes;
proc format;
  value $pcodeN 
	'S020','S021','S027','S029','T902', 
	'S022','S023','S024','S025','S026','S028',
	'S120','S121','S122','S127','S220','S221','S320','S327','T911','T08','T080','T081',
	'S222','S223','S224','S225',
	'S321','S322','S323','S324','S325','S328','T912',
	'S420','S421','S422','S423','S424','S427','S428','S429','S42',
	'S520','S521','S522','S523','S524','S525','S526','S527','S528',
	'S529','S52','T10','T100','T101','T921',
	'S620','S621','S622','S623','S624','S625','S626','S627','S628','S62','T922',
	'S72','S720','S721','S722','S723','S724','S727','S728','S729','T931',
	'S820','S821','S822','S823','S824','S827','S829','T12','T120','T121','T932',
	'S825','S826','S828',
	'S92','S920','S921','S922','S923','S924','S925','S927','S929',
	'S128','S129','T024'= 'Fracture'

	'S430','S431','S432','S433','S730','S530','S531',
	'S030','S031','S032','S033','S131','S132','S133',
	'S231','S232','S331','S332','S333','S630','S631',
	'S632','S830','S831','S930','S931','S933','T03',
	'T030','T031','T032','T033','T034','T038','T039',
	'T112','T132','T143','T923','T933','T092' = 'Dislocation'

	'S060','S062','S063','S064','S065','S066','S068','S069','T905' = 'TBI'

	'S141','S241','S341','T060','T061','T913','S147','S247','S347','T093' = 'SCI'

	'S040' - 'S049','S440' - 'S449','S540' - 'S549',
	'S640' - 'S649','S740' - 'S749','S840' - 'S849',
	'S940' - 'S949','T062','T113','T133','T144','S142',
	'S143','S144','S145','S146','S243','S244','S245',
	'S246','S346','T903','T924','T934','S342' - 'S345','S348','T094'  = 'Peripheral nerver injury'

	'S250' - 'S279','S350' - 'S379','S396','T063','T065',
	'T914','T915' = 'Internal injury'

	'S434','S435','S436','S46','S460','S461','S462',
	'S463','S467','S468','S469','S437',
	'S832','S833','S834','S835','S836',
	'S860','S934','S932','S960' - 'S969',
	'S16','S034','S035','S134','S136','S233','S234','S235','S335' - 'S337',
	'S390','S532' - 'S534','S560' - 'S568','S633' - 'S637','S660' - 'S669',
	'S731','S760' - 'S767','S861' - 'S869','S935','S936','T095','T115','T135',
	'T145','T146' = 'Soft tissue injury'

	'S05','S050','S051','S052','S053','S054','S055',
	'S056','S057','S058','S059','T904' = 'Eye injury'

	'T15','T150','T151','T158','T159','T16',
	'T170' - 'T199' ='Foreign body related injuries'

	'T200' - 'T303',
	'T310','T311',
	'T312','T313','T314','T315',
	'T316','T317','T318','T319' = 'Burn'

	'T520' - 'T659','T97',
	'T51','T510','T511','T512','T513','T518','T519',
	'T360' - 'T509','T96' = 'Poisoning'

	'T751' = 'Drowning'

	'S680',
	'S681','S682',
	'S480','S481','S489','S580','S581','S589','S683',
	'S684','S688','S689','T050','T051','T052','T116',
	'S780','S781','S789','S880','S881','S889','T054',
	'T055','T136',
	'S980','S983','S984','T053',
	'S981','S982',
	'T059','S382','T058' = 'Amputation'

	'S010' - 'S019','S080' - 'S089','S110' - 'S119','S150' - 'S159',
	'S210' - 'S219','S310' - 'S318','S410' - 'S418','S450' - 'S459',
	'S510' - 'S519','S550' - 'S559','S610' - 'S619','S650' - 'S659',
	'S710' - 'S717','S750' - 'S759','S810' - 'S819','S850' - 'S859',
	'S910' - 'S917','S950' - 'S959','T010' - 'T019','T111','T114','T131',
	'T141','T901','S718' = 'Open wound'

	'S070' - 'S079','S170' - 'S179','S280','S380','S381','S47','S570' - 'S579',
	'S670','S678','S770' - 'S772','S870','S878','S970' - 'S978','T040' - 'T049',
	'T147','T926','T936','S597' = 'Crush injury'

	'S000' - 'S009','S100' - 'S109','S200' - 'S208','S300' - 'S309','S400' - 'S409',
	'S500' - 'S509','S600' - 'S609','S700' - 'S709','S800' - 'S809','S900' - 'S909',
	'T001' - 'T009','T090','T110','T130','T140' = 'Superficial injury'

	'T800' - 'T889','T983' = 'Treatment injury'

	'T780' - 'T789' ='Adverse effects, NEC'

	other = 'Other injuries';
run;

data nmds_injury nmds_noninjury;
	merge &indat.(in=a) nmds0;
	by snz_uid;
	if a;
	** We do not have actual birth dates, only month, so can not properly exclude injuries among neo-nates.
	** Instead we take a conservative approach where we exclude any injuries occurring in the month of the birth or the month following the birth;
	** This will include some neo-nate injuries and exclude some non-neo-nate injuries but overall our comparison between treatment and 
	** control groups will be unbiassed;
	birth_date=mdy(snz_birth_month_nbr,snz_birth_year_nbr,15);
	age_days = startdate_hosp-birth_date;
	age_years =  floor(yrdif(birth_date, startdate_hosp, 'age'));
	length_of_stay = enddate_hosp - startdate_hosp;

	if startdate_hosp<=intnx('month',birth_date,1,'E') then delete;

	code3 = substr(moh_dia_clinical_code,1,3);
	code4 = substr(moh_dia_clinical_code,1,4);

	/* exclude injuries from this dataset */
	if substr(moh_dia_clinical_code,1,1) in ('S','T') then do;
		N_cause = put(code4,$PcodeN.);
		if N_cause in ('Treatment injury','Adverse effects, NEC') then delete;
		else output nmds_injury;
	end;
	else do;
		/* Apply age-based exclusions */
		if age_years>=15 and (code3 in ('J21','L22','A33') or code4='M833') then delete;
		if age_years<15 and code3 in ('K25','K26','K27','K28') then delete;		
		if age_years<5 and (code3 in ('N10','N12') or code4 in ('N136','N300','N309','N390')) then delete;		
		output nmds_noninjury;
	end;
run;

/* 3. Identify events which are considered PAH
/*	a. Join for codes where we need the first 3 letters only */
/*	b. Join for codes where we need the first 4 letters */

proc sql;
create table nmds_noninjury_pah1 as
	select
		a.*
		,b.category
		,b.subcategory
	from nmds_noninjury a
	inner join pah_noninjury_lookup (where=(code4='')) b
	on a.code3 = b.code3
;

create table nmds_noninjury_pah2 as
	select
		a.*
		,b.category
		,b.subcategory
	from nmds_noninjury a
	inner join pah_noninjury_lookup (where=(code4 ne '')) b
	on a.code4 = b.code4
;
quit;

** Exclude injuries with specific external cause codes;
proc sort data=nmds_injury; by snz_uid moh_evt_event_id_nbr; run;
data nmds_injuryb;
	merge nmds_injury nmds0c(in=b);
	by snz_uid moh_evt_event_id_nbr;
	if b then delete;
run;

** Now deal with transfers;
data nmds_pah;
	set nmds_noninjury_pah1(where=(code4 ne 'A080')) /* hard code a fix to only include code A080 once - as vaccine avoidable 
														other A08 codes are classified as gastrointestinal */
		nmds_noninjury_pah2
		nmds_injuryb(in=z);
	by snz_uid;
	if z then category='Injuries/poisoning';
run;

proc sort data=nmds_pah;
	by snz_uid startdate_hosp enddate_hosp;
run;

data nmds_pah2;
	set nmds_pah;
	by snz_uid startdate_hosp enddate_hosp;
	/*Event ended in transferred;*/
	if end_typ in ('DA', 'DF', 'DO', 'DP', 'DT', 'DW', 'ET') then trans_out ='Y';
	else trans_out = 'N';

	snz_uid_pre=lag(snz_uid);
	startdate_pre=lag(startdate_hosp);
	enddate_pre=lag(enddate_hosp);

	length category_pre $ 45 subcategory_pre $ 80;
	category_pre=lag(category);
	subcategory_pre=lag(subcategory);

	trans_out_pre=lag(trans_out);

	** Delete transfers - less than a day between leaving one hospital and entering the next where end_typ is correct;
	** NB: we can not apply the full MoH rule as we do not have a timestamp. Also if they are on the same day we do not know which is first;
	if snz_uid = snz_uid_pre and trans_out_pre = 'Y' and startdate_hosp-enddate_pre<=1 then delete;
run;

proc sort data=nmds_pah2;
	by snz_uid moh_evt_event_id_nbr;
run;
data dupes;
	set nmds_pah2;
	by snz_uid moh_evt_event_id_nbr;
	if first.moh_evt_event_id_nbr=0 or last.moh_evt_event_id_nbr=0;
run;
** Should be no dupes;

data pah_dent(drop=age_days);
	set nmds_pah2;
	retain h28_pah h11_dent_hosp h10_injury pah_ind dent_hosp_ind injury_ind;
	by snz_uid;
	if first.snz_uid then do; pah_ind=0; dent_hosp_ind=0; h28_pah=0; h11_dent_hosp=0; h10_injury=0; injury_ind=0; end;

	** Identify whether the hospitalisation occurred in our period of interest - from 1 July 2017 to 30 June 2018;
	** Also identify dental hospitalisations;
	if '1jul2017'd<=enddate_hosp<='30jun2018'd then do; 
		h28_pah+1;
		pah_ind=1;
		if category='Dental conditions' then do;
			h11_dent_hosp+1;
			dent_hosp_ind=1;
		end;
		else if category='Injuries/poisoning' then do;
			h10_injury+1;
			injury_ind=1;
		end;
	end;
	if last.snz_uid and h28_pah>0 then output;
run;

data health;
	merge sandpit.apcpop_cen_idd_2018(keep=snz_uid adult15plus childunder18 idd_id apc_age_in_years_nbr snz_sex_gender_code) 
		pah_dent(keep=snz_uid h28_pah h11_dent_hosp h10_injury pah_ind dent_hosp_ind injury_ind);
	by snz_uid;
	if h28_pah=. then h28_pah=0;
	if h11_dent_hosp=. then h11_dent_hosp=0;
	if pah_ind=. then pah_ind=0;
	if dent_hosp_ind=. then dent_hosp_ind=0;
	if h10_injury=. then h10_injury=0;
	if injury_ind=. then injury_ind=0;
	label	h28_pah='Number of potentially avoidable hospitalisations in the previous year'
			h10_injury='Number of injury-related hospitalisations in the previous year' 
			h11_dent_hosp='Number of public dental hospitalisations in the previous year' 
			pah_ind='Had a potentially avoidable hospitalisation in the previous year'
			injury_ind='Had an injury-related hospitalisation in the previous year'
			dent_hosp_ind='Had a public dental hospitalisation in the previous year';
run;

proc sql;
	create table hosp_means as
	select idd_id,mean(pah_ind) as mean_pah_ind, mean(h28_pah) as mean_h28_pah,mean(dent_hosp_ind) as mean_dent_hosp_ind,mean(h11_dent_hosp) as mean_h11_dent_hosp,
		mean(injury_ind) as mean_injury_ind,mean(h10_injury) as mean_h10_injury,count(pah_ind) as n
	from health
	group by idd_id
	order by idd_id;
quit;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

***********************************************************************************;
** Now look at treatment for chronic health conditions;
** H4 and H6 - Diabetes and cancer;
proc freq data=moh.chronic_condition;
	tables moh_chr_condition_text;
run;

** moh_chr_condition_text 
AMI = Acute myocardial infarction - in MOH paper as part of coronary heart disease indicator
CAN = Cancer - yes
DIA = Diabetes - yes
GOUT = Gout - not in MOH paper
STR = Stroke - not in MOH paper
TBI = Traumatic brain injury - not in MOH paper
;
proc sql;
	create table chronic as
	select distinct a.snz_uid,max(case when b.moh_chr_condition_text='CAN' then 1 else 0 end) as h6_cancer,
			max(case when b.moh_chr_condition_text='DIA' then 1 else 0 end) as h4_diabetes
	from sandpit.apcpop_cen_idd_2018 a left join moh.chronic_condition b
	on a.snz_uid=b.snz_uid and moh_chr_fir_incidnt_date<='30jun2018'd
	group by a.snz_uid;
quit;

proc freq data=chronic; tables h4_diabetes h6_cancer;
run;

data health;
	merge sandpit.health chronic;
	by snz_uid;
run;

proc freq data=health;
table (h4_diabetes h6_cancer)*idd_id / nofreq norow nopercent missing;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

***********************************************************************************************************************
** Now look at PHO enrolment - and consultations;

proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table pho_enrol as
	select * from connection to odbc
	(select distinct a.snz_uid,max(case when b.snz_uid is not null then 1 else 0 end) as h16_pho_enrol,
		max(case when moh_pho_last_consul_date>'2018-03-31' then 1 else 0 end) as h18_consult_3m,
		max(case when moh_pho_last_consul_date>'2017-06-30' then 1 else 0 end) as h19_consult_1y,
		max(case when moh_pho_last_consul_date>'2016-06-30' then 1 else 0 end) as h20_consult_2y,
		max(case when moh_pho_careplus_enrol_status_code='Y' then 1 else 0 end) as h17_careplus
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a inner join IDI_Clean_202210.moh_clean.pho_enrolment b
	on a.snz_uid=b.snz_uid and b.moh_pho_enrolment_date<='2018-06-30' and b.moh_pho_enrol_status_code='Y'
	group by a.snz_uid
	order by a.snz_uid);
	disconnect from odbc;
quit;

proc freq data=pho_enrol; tables h16_pho_enrol h17_careplus h18_consult_3m h19_consult_1y h20_consult_2y;
run;

data health(drop=i);
	merge sandpit.health pho_enrol;
	by snz_uid;
	array inds{*} h16_pho_enrol h17_careplus h18_consult_3m h19_consult_1y h20_consult_2y;
	do i=1 to dim(inds);
		if inds{i}=. then inds{i}=0;
	end;
run;

proc freq data=health;
table (h16_pho_enrol h17_careplus h18_consult_3m h19_consult_1y h20_consult_2y)*idd_id / nofreq norow nopercent missing;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

***************************************************************************************;
** H27 - Emergency department visits;
proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table nnpac_ed as
	select * from connection to odbc
	(select a.snz_uid,count(b.moh_nnp_service_date) as h27_emergency
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a inner join IDI_Clean_202210.moh_clean.nnpac b
	on a.snz_uid=b.snz_uid and '2017-07-01' <= b.moh_nnp_service_date and b.moh_nnp_service_date <= '2018-06-30' 
	and b.moh_nnp_purchase_unit_code>='ED02001' and b.moh_nnp_purchase_unit_code<='ED06001A'
	group by a.snz_uid
	order by a.snz_uid);
	disconnect from odbc;
quit;

data health;
	merge sandpit.health nnpac_ed;
	by snz_uid;
	if h27_emergency=. then h27_emergency=0;
run;

proc summary data=health nway mean print;
class idd_id;
var h27_emergency;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

**********************************************************************************;
** H2 - Coronary Heart Disease or treatment
** This code comes from Sheree Gibb;
*First, extract datasets that will be used to identify CVD events, we need those data back to 2001;

*NMDS events;
proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table work.nmds_event_raw as 
	select * from connection to odbc
	(select moh_evt_even_date as visit_date, moh_evt_evst_date as evstdate, moh_evt_event_id_nbr as event_id, *
	from IDI_Clean_&extractdate..moh_clean.pub_fund_hosp_discharges_event 
	WHERE moh_evt_even_date <= '30JUN2018'
	order by event_id);
	disconnect from odbc;
quit;

** From 1988 onwards;
proc freq data=nmds_event_raw;
	tables moh_evt_even_date;
	format moh_evt_even_date monyy7.;
run;

*NMDS diagnosis;
*Can't use user-defined formats in the passthrough, so need to extract all diagnoses and then restrict to the ones that match the CVD codes;
proc sql;
	connect to odbc(dsn=idi_sandpit_srvprd);
	create table work.nmds_diag_all as 
	select * from connection to odbc
	(select moh_dia_event_id_nbr as event_id, CAST(moh_dia_diag_sequence_code as INT) as moh_dia_diag_sequence_code, moh_dia_clinical_sys_code, moh_dia_submitted_system_code,
	moh_dia_diagnosis_type_code, moh_dia_clinical_code
	from IDI_Clean_&extractdate..moh_clean.pub_fund_hosp_discharges_diag 
	where moh_dia_diagnosis_type_code='A' 
	order by event_id);
	disconnect from odbc;
quit;

*these formats are from June Atkinsons code, 20th April 2016;
proc format;
invalue $iAnyCVD
'I00'-'I00XX',  'I010'-'I012X', 'I018'-'I020X', 'I029'-'I029X', 
'I050'-'I052X', 'I058'-'I062X', 'I068'-'I072X', 'I078'-'I083X', 
'I088'-'I092X', 'I098'-'I099X', 'I10'-'I10XX',  'I110'-'I110X', 
'I119'-'I120X', 'I129'-'I132X', 'I139'-'I139X', 'I150'-'I152X', 
'I158'-'I159X', 'I200'-'I201X', 'I208'-'I214X', 'I219'-'I221X', 
'I228'-'I236X', 'I238'-'I238X', 'I240'-'I241X', 'I248'-'I250X', 
'I2510'-'I2513','I252'-'I256X', 'I258'-'I260X', 'I268'-'I272X', 
'I278'-'I281X', 'I288'-'I289X', 'I300'-'I301X', 'I308'-'I313X', 
'I318'-'I321X', 'I328'-'I328X', 'I330'-'I330X', 'I339'-'I342X', 
'I348'-'I352X', 'I358'-'I362X', 'I368'-'I372X', 'I378'-'I379X', 
'I38'-'I38XX',  'I390'-'I394X', 'I398'-'I398X', 'I400'-'I401X', 
'I408'-'I412X', 'I418'-'I418X', 'I420'-'I432X', 'I438'-'I438X', 
'I440'-'I447X', 'I450'-'I456X', 'I458'-'I461X', 'I469'-'I472X', 
'I479'-'I479X', 'I48'-'I48XX',  'I490'-'I495X', 'I498'-'I501X', 
'I509'-'I521X', 'I528'-'I528X', 'I600'-'I616X', 'I618'-'I621X', 
'I629'-'I636X', 'I638'-'I639X', 'I64'-'I64XX',  'I650'-'I653X', 
'I658'-'I664X', 'I668'-'I682X', 'I688'-'I688X', 'I690'-'I694X',
'I698'-'I698X', 'I700'-'I701X', 'I7020'-'I7024','I708'-'I709X',
'I7100'-'I7103','I711'-'I716X', 'I718'-'I724X', 'I728'-'I729X',
'I738'-'I739X', 'I790'-'I790X', 'I980'-'I981X' ='ACVD'  /*AnyCVD*/  
other='???';

/*Multiple CVD codes (all ICD10 4 characters)*/  
invalue $i4CVD
'G453','G460'-'G465','G467','G468','I650'-'I653','I658'-'I664',
'I668'-'I682','I688','I690'-'I694','I698'='CERE'  /*CEREBVAS ICD10 (4 characters)*/
'I110','I130','I132','I420'-'I422','I426'-'I432','I438','I500',
'I501','I509'='HF__'  /*HF (Heart Failure) ICD10 (4 characters)*/
'I600'-'I616','I618'-'I621','I629'='HStr'  /*HStroke ICD10 (4 characters)*/
'I630'-'I636','I638','I639'='IStr'  /*IStroke ICD10 (4 characters)*/
'I210'-'I214','I219','I220','I221','I228','I229'='MI__'  /*MI ICD10 (4 characters)*/
'I201','I208','I209','I248','I249','I252'-'I256','I258','I259'='OAng'  /*OthAng ICD10 (4 characters)*/
'I64'-'I64X'='OStr'  /*OthStroke ICD10 (4 characters)*/
'G450'-'G452','G454','G458'-'G459'='TIA_'  /*TIA ICD10 (4 characters)*/
'I200'='UA__'  /*UA ICD10 (4 characters)*/
other='???';

/*OthCVD ICD10 (5 characters*/  
invalue $iOthCVD
'I00'-'I00XX',  'I010'-'I012X',  'I018'-'I020X', 'I029'-'I029X',
'I050'-'I052X', 'I058'-'I062X',  'I068'-'I072X', 'I078'-'I083X',
'I088'-'I092X', 'I098'-'I099X',  'I10'-'I10XX',  'I119'-'I120X', 
'I129'-'I129X', 'I131'-'I131X',  'I139'-'I139X', 'I150'-'I152X',
'I158'-'I159X', 'I230'-'I236X',  'I238'-'I238X', 'I240'-'I241X',
'I250'-'I250X', 'I2510'-'I2513', 'I260'-'I260X', 'I268'-'I272X',
'I278'-'I281X', 'I288'-'I289X',  'I300'-'I301X', 'I308'-'I313X',
'I318'-'I321X', 'I328'-'I328X',  'I330'-'I330X', 'I339'-'I342X',    
'I348'-'I352X', 'I358'-'I362X',  'I368'-'I372X', 'I378'-'I379X',
'I38'-'I38XX',  'I390'-'I394X',  'I398'-'I398X', 'I400'-'I401X',    
'I408'-'I412X', 'I418'-'I418X',  'I423'-'I425X', 'I440'-'I447X', 
'I450'-'I456X', 'I458'-'I461X',  'I469'-'I472X', 'I479'-'I479X',
'I48'-'I48XX',  'I490'-'I495X',  'I498'-'I499X', 'I510'-'I521X',
'I528'-'I528X', 'I700'-'I701X',  'I7020'-'I7024','I708'-'I709X',
'I7100'-'I7103','I711'-'I716X',  'I718'-'I724X', 'I728'-'I729X',
'I738'-'I739X', 'I790'-'I790X',  'I980'-'I981X' ='OCVD'  /*OthCVD*/ 
other='???';
run;

*Restrict to diagnoses that match a CVD code. We aren't interested in the others;
data nmds_diag_raw;
	set nmds_diag_all;
	cvd_code_any=input(substr(moh_dia_clinical_code,1,5),$ianycvd.);
	cvd_code_4=input(substr(moh_dia_clinical_code,1,4),$i4cvd.);
	if strip(cvd_code_4) eq '???' then cvd_code_4=input(substr(moh_dia_clinical_code,1,5),$iothcvd.);
	if cvd_code_any='???' and cvd_code_4='???' then delete;
run;

****************************************
*     Identify and flag CVD events     ;
****************************************

*Transfer diagnoses to main NMDS event file;
proc sql;
	create table cvd_events as
	select evstdate as diagnosis_date format ddmmyy10., *
	from nmds_event_raw as a inner join nmds_diag_raw as b on a.event_id=b.event_id;
quit;


*Angina medications;

*Get a list of all dim_form_pack_subsidy_code values for Glyceryl trinitrate (chemical ID 1577), Isosorbide dinitrate (2377),
Isosorbide mononitrate (2836), Nicorandil (1272), Perhexiline maleate (1949);

data angina_codes;
	set old_meta.moh_dim_form_pack_subsidy_code (where=(chemical_id in(1577 2377 2836 1272 1949)));
	*There are two preparations that are not for cardiovascular disease, drop them;
	if dim_form_pack_subsidy_key in(79992 79935) then delete;
	dim_form_pack_code=strip(put(dim_form_pack_subsidy_key, 8.));
run;

*Extract all prescriptions for those codes;
proc sql;
	create table angina_prescriptions as
	select b.snz_uid, b.snz_moh_uid, b.moh_pha_dispensed_date, b.moh_pha_quan_presc_nbr, b.moh_pha_quan_disp_nbr, a.*
	from angina_codes as a inner join moh.pharmaceutical as b on a.dim_form_pack_code=b.moh_pha_dim_form_pack_code
	/*restrict to a sample for testing*/
	order by snz_uid, moh_pha_dispensed_date;
quit;

*Flag individuals with 2 or more dispensings in a 12 month period;
*Calculate time between dispensings;
data with_time;
	set angina_prescriptions;
	by snz_uid;
	disp_date=input(moh_pha_dispensed_date, yymmdd10.);
	format disp_date ddmmyy10.;
	last_date=lag(disp_date);
	time_since_last=disp_date-last_date;
	if first.snz_uid then time_since_last=.;
	if time_since_last le 365 and time_since_last ne . and time_since_last ne 0 then repeat=1;
	else repeat=0;
	format first_presc ddmmyy10.;
	if repeat=1 then first_presc=last_date;
run;

*List all pairs where the gap was less than 12 months;
proc sql;
	create table angina_list as
	select distinct snz_uid, snz_moh_uid, first_presc
	from with_time
	where repeat=1
	order by snz_uid, first_presc;
quit;

*Select the first instance where the gap was less than 12 months;
data final_angina_list;
	set angina_list;
	by snz_uid;
	if first.snz_uid then keep=1;
	if keep ne 1 then delete;
	drop keep;
	pharms_angina_flag=1;
	rename first_presc=diagnosis_date;
	*Code all angina cases identified in this way as 'AngM' in the cvd4 codes and 'ACVD' in the any CVD codes;
	cvd_code_4='AngM';
	cvd_code_any='ACVD';
run;

*Combine angina and CVD events;
data cvd_all;
	set cvd_events final_angina_list;
run;

proc sort data=cvd_all;
	by snz_uid diagnosis_date;
run;

** And add an indicator to our data;
data health;
	merge sandpit.health(in=a) cvd_all(in=b keep=snz_uid);
	by snz_uid;
	if a;
	if b then h2_cvd=1;
	else h2_cvd=0;
	if last.snz_uid then output;
run;

proc summary data=health nway mean print;
class idd_id;
var h2_cvd;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

**********************************************************************************;
** H30 - Secondary healthcare costs
**
** We use public hospital data, NNPAC and PRIMHD;
** Data comes from SIAL and SQL code needs to be run first: MOH_nnpac_events IHC.sql, MOH_pfhd_events IHC.sql, and MOH_primhd_events IHC.sql;
**;

** Merge NNPAC costs with our data;
proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table nnpac_costs as
	select *
    from connection to odbc(
	select distinct a.snz_uid,sum(cost) as nnpac_cost
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_usercode."DL-MAA2022-54".SIAL_MOH_nnpac_events b
	on a.snz_uid=b.snz_uid
	group by a.snz_uid
	order by a.snz_uid);
    disconnect from odbc;
quit;

** Merge public hospital costs with our data;
proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table pfhd_costs as
	select *
    from connection to odbc(
	select distinct a.snz_uid,sum(cost) as pfhd_cost
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_usercode."DL-MAA2022-54".SIAL_MOH_pfhd_events b
	on a.snz_uid=b.snz_uid
	group by a.snz_uid
	order by a.snz_uid);
    disconnect from odbc;
quit;

** Merge PRIMHD costs with our data;
proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table primhd_costs as
	select *
    from connection to odbc(
	select distinct a.snz_uid,sum(cost) as primhd_cost
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_usercode."DL-MAA2022-54".SIAL_MOH_primhd_events b
	on a.snz_uid=b.snz_uid
	group by a.snz_uid
	order by a.snz_uid);
    disconnect from odbc;
quit;

** Now bring them all together and add them up;
data all_costs;
	merge nnpac_costs pfhd_costs primhd_costs;
	by snz_uid;
	h30_healthcosts=sum(0,nnpac_cost,pfhd_cost,primhd_cost);
run;

data health;
	merge sandpit.health all_costs;
	by snz_uid;
	if a;
run;

proc summary data=health nway mean print;
class idd_id;
var h30_healthcosts;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

************************************************************************************************************;
** Now various health indicators from SWA definitions library
** 
** SQL code needs to be run first: 
** - Dementia and Parkinsons: DAP_register IHC
** - COPD: COPD_register IHC
** - chronic_obstructive_pulmonary_disease IHC
** - chronic_diabetes IHC
** - chronic_coronary_heart_disease IHC
** - cancer_register IHC
**;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table health_copd1 as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,case when b.snz_uid is not null then 1 else 0 end as copd_1
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".defn_chronic_obstructive_pulmonary_disease b
	on a.snz_uid=b.snz_uid and b.start_date<='2018-06-30'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc summary data=health_copd1 nway mean print;
class idd_id;
var copd_1;
run;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table health_copd2 as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,case when b.snz_uid is not null then 1 else 0 end as copd_2
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".def_copd b
	on a.snz_uid=b.snz_uid and b.event_date<='2018-06-30'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc summary data=health_copd2 nway mean print;
class idd_id;
var copd_2;
run;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table health_dap as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,case when b.snz_uid is not null then 1 else 0 end as dap
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".defn_dap b
	on a.snz_uid=b.snz_uid and b.event_date<='2018-06-30'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc summary data=health_dap nway mean print;
class idd_id;
var dap;
run;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table health_chd as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,case when b.snz_uid is not null then 1 else 0 end as chd
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".defn_chronic_coronary_heart_disease b
	on a.snz_uid=b.snz_uid and b.start_date<='2018-06-30'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc summary data=health_chd nway mean print;
class idd_id;
var chd;
run;


proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table health_diabetes as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,case when b.snz_uid is not null then 1 else 0 end as diabetes
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".defn_chronic_diabetes b
	on a.snz_uid=b.snz_uid and b.start_date<='2018-06-30'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc summary data=health_diabetes nway mean print;
class idd_id;
var diabetes;
run;

proc sql;
    connect to odbc(dsn=idi_sandpit_srvprd);
	create table health_cancer as
	select *
    from connection to odbc(
	select distinct a.snz_uid,a.idd_id,case when b.snz_uid is not null then 1 else 0 end as cancer
	from idi_sandpit."DL-MAA2022-54".apcpop_cen_idd_2018 a left join idi_sandpit."DL-MAA2022-54".def_cancer b
	on a.snz_uid=b.snz_uid and b.event_date<='2018-06-30' and b.event_date>='2016-07-01'
	order by a.snz_uid);
    disconnect from odbc;
quit;

proc summary data=health_cancer nway mean print;
class idd_id;
var cancer;
run;

data health;
	merge sandpit.health health_copd1 health_copd2 health_dap health_chd health_diabetes health_cancer;
	by snz_uid;
	rename cancer=h6_cancer2 dap=h14_dementia copd_1=h3_copd1 copd_2=h3_copd2 chd=h2_chd diabetes=h4_diabetes2;
run;

proc contents data=health;
run;

proc summary data=health nway mean print;
class idd_id;
var h2_chd h2_cvd h3_copd1 h3_copd2 h4_diabetes h4_diabetes2 h6_cancer h6_cancer2 h10_injury h11_dent_hosp h14_dementia h16_pho_enrol h17_careplus h18_consult_3m
	h19_consult_1y h20_consult_2y h27_emergency h28_pah h30_healthcosts;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;

** Now need to do mental health;
******************************************************************************************************************************************************************
** Base this off Matt Cronin and Steven Johnstons code from MOH - turned into a macro for MSD by Bryan Ku
******************************************************************************************************************************************************************;

data health;
	set sandpit.health;
run;

%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/frmtdatatight.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/spellhistoryinverter.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/spellcombine.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/use_fmt.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/subset_ididataset2.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/hashtbldynajoin.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/spellcondense.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/hashtblfulljoin.sas';
%include '/nas/DataLab/MAA/MAA2022-54/code/Misc/mentalhealth_events_202210.sas';

%mentalhealth_events_202210 (
   moh_mh_infile=health 
  ,moh_mh_outfile=health_mh
  ,moh_mh_extdt = 202210
  ,moh_mh_sandpit_schema = DL-MAA2022-54);

proc sort data=health_mh;
	by snz_uid;
run;

data health_mh2(keep=snz_uid h12_mooddisorder h13_psychosis h14_dementia2 h15_mentlhlth);
	set health_mh;
	by snz_uid;
	where event_type ne 'Intellectual';
	retain h12_mooddisorder h13_psychosis h14_dementia2 h15_mentlhlth;
	if first.snz_uid then do; h12_mooddisorder=0; h13_psychosis=0; h14_dementia2=0; h15_mentlhlth=0; end;
	where start_date<='30jun2018'd and end_date>='01jul2017'd;
	if event_type='Mood' then h12_mooddisorder=1;
	else if event_type='Psychotic' then h13_psychosis=1;
	else if event_type='Dementia' then h14_dementia2=1;
	h15_mentlhlth=1;
	if last.snz_uid;
run;


** Finally, look at the distinct number of chemicals prescribed;
proc sql;
	create table health_pharma as
	select a.snz_uid,sum(distinct b.chemical_id) as h21_countpharma
	from health a 
	inner join moh.pharmaceutical b on a.snz_uid=b.snz_uid and '01jul2017'd<=b.moh_pha_dispensed_date<='30jun2018'd
	inner join mohmeta.moh_dim_form_pack_subsidy_code c	on b.dim_form_pack_code=c.DIM_FORM_PACK_SUBSIDY_KEY
	group by snz_uid
	order by snz_uid;
quit;

data health;
	merge sandpit.health health_mh2 health_pharma;
	by snz_uid;
run;

proc summary data=health nway mean print;
class idd_id;
var h2_chd h2_cvd h3_copd1 h3_copd2 h4_diabetes h4_diabetes2 h6_cancer h6_cancer2 h10_injury h11_dent_hosp 
	h12_mooddisorder h13_psychosis h14_dementia h14_dementia2 h15_mentlhlth h16_pho_enrol h17_careplus h18_consult_3m
	h19_consult_1y h20_consult_2y h27_emergency h28_pah h30_healthcosts;
run;

proc datasets lib=sandpit; delete health; run;
data sandpit.health; set health; run;
