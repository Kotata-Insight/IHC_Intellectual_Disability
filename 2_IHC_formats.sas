proc format;
value age5yr
0-4  ='00-04'
5-9  ='05-09'
10-14='10-14'
15-19='15-19'
20-24='20-24'
25-29='25-29'
30-34='30-34'
35-39='35-39'
40-44='40-44'
45-49='45-49'
50-54='50-54'
55-59='55-59'
60-64='60-64'
65-69='65-69'
70-74='70-74'
75-79='75-79'
80-84='80-84'
85-89='85-89'
90-94='90-94'
95-high='95+'
;

value agegroups
0-14='00-14'
15-24='15-24'
25-34='25-34'
35-44='35-44'
45-54='45-54'
55-64='55-64'
65-74='65-74'
75-high='75+'
;

value qualification
0 = 'No qualification'
1 = 'Level 1 certificate'
2 = 'Level 2 certificate'
3 = 'Level 3 certificate'
4 = 'Level 4 certificate'
5 = 'Level 5 diploma'
6 = 'Level 6 diploma'
7 = 'Bachelor degree and Level 7 qualification'
8 = 'Post-graduate and honours degrees'
9 = 'Masters degree'
10= 'Doctorate degree'
;

value qualgroup
. = 'Unknown'
0 = 'No qualification'
1 = 'Level 1 certificate'
2 = 'Level 2 certificate'
3 = 'Level 3 certificate'
4 = 'Level 4 certificate'
5 = 'Level 5/6 diploma'
6 = 'Level 5/6 diploma'
7 = 'Bachelor degree and Level 7 qualification'
8 = 'Post-graduate/honours/Masters/Doctorate degrees'
9 = 'Post-graduate/honours/Masters/Doctorate degrees'
10= 'Post-graduate/honours/Masters/Doctorate degrees'
999 = 'Age N/A'
;

value employed
. = 'Not employed'
1 = 'Employed'
999 = 'Age N/A'
;

value ynt
.='Total'
0='No'
1='Yes'
;

value $ sex
'1'='Male'
'2'='Female'
'3'='Other'
;

value $ ind
/* culture capability and belonging */
'ccb1_incarcerated'='Currently incarcerated (sentenced or on remand)'
'ccb2_convictions'= 'Convicted of a crime in the past 5 years'
'ccb3_travel'='Any international travel in the past 5 years'
/* Family and Friends */
'ff1_parent'='Ever been registered as a parent on a birth certificate'
'ff2_marr_civil'='Ever been registered as married or in a civil union'
'ff3_divorce'='If ever married/civil union, has ever had a divorce/dissolution'
'ff4_living_parent'='Is in the same household as a registered birth parent at Census'
'ff5_soleparent'='Child in a single parent household'
'ff6_teenparent'='Was born to at least one teen parent (under 20 years old)'
/* Health */
'h2_chd'='Treated for coronary heart disease'
'h2_cvd'='Treated for cardiovascular disease (UoO)'
'h3_copd1'='Treated for chronic obstructive pulmonary disease (SWA - ICD10)'
'h3_copd2'='Treated for chronic obstructive pulmonary disease (SWA - ICD9 and ICD10)'
'h4_diabetes2'='Treated for diabetes (SWA)'
'h6_cancer2'='Treated for cancer in past two years (SWA)'
'h10_injury'='Number of injury-related public hospital discharges in past year'
'h11_dent_hosp'='Number of dental treatment public hospital discharges in past year'
'h12_mooddisorder'='Treated for a mood disorder in past year'
'h13_psychosis'='Treated for psychosis in past year'
'h14_dementia'='Ever treated for dementia'
'h14_dementia2'='Treated for dementia in past year'
'h15_mentlhlth'='Treated for any mental health condition in past year'
'h16_pho_enrol'='Enrolled with a PHO'
'h17_careplus'='Enrolled in careplus'
'h18_consult_3m'='Seen a GP in past 3 months'
'h19_consult_1y'='Seen a GP in past year'
'h20_consult_2y'='Seen a GP in past 2 years'
'h21_countpharma'='Number of different pharmaceuticals prescribed in past year'
'h27_emergency'='Number of emergency department visits in past year'
'h28_pah'='Number of potentially avoidable hospitalisations in past year'
'h30_healthcosts'='Secondary health-care costs'
/* Housing */
'hs2_transience'='Number of different addresses lived at in last 5 years'
'hs3_mouldy_damp'='House is mouldy or damp'
'hs4_crowded'='House is crowded'
/* Income consumption and wealth */
'icw1_income'='Total personal income'
'icw2_equiv_hh_inc'='Equivalised disposable household income before housing costs'
'icw3_nzdep18'='NZ Deprivation Index 2018 decile'
'icw4_internet'='Living in a household with internet access'
'lowinc_50'='Equiv disp BHC HH income < 50% of median'
'lowinc_60'='Equiv disp BHC HH income < 60% of median'
'highdep_dec'='Living in most deprived NZDep decile'
'highdep_quint'='Living in most deprived NZDep quintile'
/* Knowledge and skills */
'ks1_ece'='Reported ECE attendance before starting school'
'ks1_ece2'='ECE enrolment recorded for 3 and 4 year olds'
'ks2_school'='School enrolment'
'special_school'='Enrolled at a special school'
'ks3_high_qual2'='Highest qualification at least NCEA level 2'
'high_qual4'='Highest qualification at least NCEA level 4'
'high_qual7'='Highest qualification at least NCEA level 7'
'noqual'='No qualification'
'ks4_licence'='Has some form of drivers licence'
/* Safety */
's3_victim'='Victim of crime (number of victimisations)'
's5_placement'='Child placed in care'
's6_fam_violence'='Child exposed to violence'
's7_childplacement'='Adult with a child who has been placed in care'
'victim_end'='Victim of crime indicator'
/* Work care and volunteering */
'wcv1_employed'='Employed'
'wcv2_yneet'='Youth NEET'
'youth_study'='Youth studying only'
'youth_work'='Youth working only'
'youth_wkstudy'='Youth working and studying'
'wcv3_benefit'='Receiving benefit'
'wcv4_parentemp'='Child with all parents in some form of employment'
'wcv5_parentcare'='Child with at least one parent not in work or part-time employed'
'wcv6_volunteer'='Volunteered outside home in last 4 weeks'
'care_child'='Cared for a child outside home in last 4 weeks'
'care_illdis'='Cared for someone with illness or disability outside home in last 4 weeks'
'other_helpvol'='Volunteered for another organisation in last 4 weeks'
;

value $ fam_type
'0'='Not in a family nucleus'
'1'='Couple no children'
'2'='Couple with children'
'3'='One parent with children'
;

value $ fam_dep_type
'00'='Not in a family nucleus'
'11'='Couple without children'
'21'='Couple with dependent child(ren) under 18 only'
'22'='Couple with adult child(ren) only'
'23'='Couple with adult child(ren) and dependent child(ren) under 18 only'
'31'='One parent with dependent child(ren) under 18 only'
'32'='One parent with adult child(ren) only'
'33'='One parent with adult child(ren) and dependent children under 18 only'
'99'='Family with children with unknown dependency status'
;

value $ num_people
' '='Missing'
'00'='0'
'01'='1'
'02'='2'
other='3 or more'
;

value agethree
0-14=1
15-64=2
65-high=3
;
run;

** Read in June 2018 ERP by 5 year age bands for age standardisation purposes;
** Note: these are published figures and are publically available;
data age5yrpop_jun2018;
input age_5yr $ 1-5 popn 7-12;
datalines;
00-04 305030
05-09 327910
10-14 313510
15-19 317350
20-24 340080
25-29 371190
30-34 338220
35-39 310070
40-44 301180
45-49 333580
50-54 320180
55-59 316440
60-64 270940
65-69 235100
70-74 191670
75-79 135870
80-84 87340
85-89 54270
90-94 23930
95+   6760
;
run;

data who_age5yrpop_jun2018;
input age_5yr $ 1-5 popn 7-12;
datalines;
00-04 8.86
05-09 8.69
10-14 8.60
15-19 8.47
20-24 8.22
25-29 7.93
30-34 7.61
35-39 7.15
40-44 6.59
45-49 6.04
50-54 5.37
55-59 4.55
60-64 3.72
65-69 2.96
70-74 2.21
75-79 1.52
80-84 0.91
85-89 0.44
90-94 0.15
95+   0.04
;
run;