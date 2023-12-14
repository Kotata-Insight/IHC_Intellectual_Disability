/*cen_ind_family_role_code - Individual's role in family nucleus
This is a derived variable that indicates people's status in relation to the family nucleus to which they belong.
The variable can be cross-tabulated with a number of other family variables, as well as demographic variables such as sex, age, and ethnicity.
A family nucleus comprises a couple with or without child(ren), or one parent and their child(ren) whose usual residence is in the same household;
the children do not have partners or children of their own living in that household.
Included are people who were absent on census night but usually live in a particular dwelling and are members of a family nucleus in that dwelling,
as long as they were reported as being absent by the reference person on the dwelling form or the household summary page.

ROLEFAM V2.0

11 Parent (other than grandparent) and spouse/partner in a family nucleus
12 Grandparent in a parent role and spouse/partner in a family nucleus
21 Sole parent (other than sole grandparent) in a family nucleus
22 Sole grandparent in a parent role in a family nucleus
31 Spouse/partner only in a family nucleus
41 Child in a family nucleus (birth/biological, step, adopted and foster parent)
42 Child in a family nucleus (other parent)
51 Person under 15 in a household of people under 15
52 Other person not in a family nucleus
53 Person living alone
99 Individual's role unknown


cen_ind_id_family_nucleus - Identification of individual's family nucleus
This is a derived variable that identifies whether a person is part of a family nucleus.
A family nucleus comprises a couple with or without child(ren), or one parent and their child(ren)
whose usual residence is in the same household; the children do not have partners or children of their own living in that household.
Included are people who were absent on census night but usually live in a particular dwelling and
are members of a family nucleus in that dwelling, as long as they were reported as being absent by
the reference person on the dwelling form or the household summary page. 

IDFAMILY V1.0

11 First family nucleus
21 Second family nucleus
31 Third family nucleus
41 Fourth and susequent family nuclei
51 Person not in a family nucleus, but related to a family nucleus
52 A related person (in a household where no family nucleus is present)
53 An unrelated person (unrelated to a family nucleus, or other People)
54 Living Alone
55 Guest/visitor/inmate/patient/resident
99 Family nucleus unidentifiable

cen_ind_rltnshp_to_ref_code - Relationship to reference person
Relationship to reference person indicates the kind of relationship each person in a defined group of people,
family or not, has to the reference person (for example: father, boarder).
The reference person is the individual who completed the dwelling form or the household set-up form on census night.
Any relationship(s) collected on the census dwelling form or the household set-up form refers to the relationship
an individual has to the reference person.
Use the variable 'identification of individual's family nucleus' to determine whether people are in a family nucleus with the reference person."
Note: a person whose relationship to the reference person is 'child' or 'parent' (or maybe spouse) may not necessarily be in the family nucleus of the reference person.  

cen_ind_child_depend_code - Dependent child under 18 indicator
DEPCHU18IN V1.0

1  Dependent child under 18
2  Dependent young person or non-dependent child
3  Child of unknown dependency status

cen_fml_family_type_code - Family type classifies family nuclei according to the presence or absence of couples, parents, and children.  
1   Couple without children
2   Couple with child(ren)
3   One parent with child(ren)

cen_fml_chld_dpnd_fmly_type_code - Family type by child dependency status 
Family type classifies family nuclei according to the presence or absence of couples, parents, and children.  
A dependent child under 18 is a ‘child in a family nucleus’ aged under 15 years or aged 15–17 years and not employed full time. 
An adult child is a ‘child in a family nucleus’ who is aged 15 years or over and employed full time,
or a ‘child in a family nucleus’ who is aged 18 years or over. This group is made up of
all dependent young people and all non-dependent children. 
To be a ‘child in a family nucleus’ a person must usually reside with at least one parent and
have no partner or child(ren) of their own living in the same household.  
Note that ‘child in a family nucleus’ can apply to a person of any age.
There are four subgroups: ‘dependent child under 18’, ‘dependent young person’ (aged 18–24 years),
‘non-dependent child’, and ‘child of unknown dependency status’. 

FAMTYPCH V2.0

11  Couple without children
21  Couple with dependent child(ren) under 18 only
22  Couple with adult child(ren) only
23  Couple with adult child(ren) and dependent child(ren) under 18 only
24  Couple with dependent child(ren) under 18 and at least one child of unknown dependency status
25  Couple with adult child(ren) and at least one child of unknown dependency status
26  Couple with adult child(ren) and dependent children under 18 and at least one child of unknown dependency status
27  Couple with child(ren), all dependency status unknown
31  One parent with dependent child(ren) under 18 only
32  One parent with adult child(ren) only
33  One parent with adult child(ren) and dependent children under 18 only
34  One parent with dependent child(ren) under 18 and at least one child of unknown dependency status
35  One parent with adult child(ren) and at least one child of unknown dependency status
36  One parent with adult child(ren), dependent children under 18 and at least one child of unknown dependency status
37  One parent with child(ren), all dependency status unknown
*/

data apcpop_cen_idd_2018; set sandpit.apcpop_cen_idd_2018; run;

/*****************code to add the parents uid to children***************************/
* this will be added to the population code afterwards;
* adding parent id of people in a parent role to dependent children under 18 in the same family living in the same household;
 
proc sql;
	create table accpop_1 as
	select a.*,b.cen_ind_id_family_nucleus, b.cen_ind_family_role_code, b.cen_ind_rltnshp_to_ref_code
	from apcpop_cen_idd_2018 a
	left join census.census_individual_2018 b
	on a.snz_cen_uid=b.snz_cen_uid;
quit;

proc sql;
	create table accpop_2 as
	select a.*,	b.cen_fml_family_type_code, b.cen_fml_people_count_code,
				b.cen_fml_chld_dpnd_fmly_type_code, b.cen_fml_child_count_code
	from accpop_1 a
	left join census.census_family_2018 b
	on a.snz_cen_fam_uid=b.snz_cen_fam_uid
	order by snz_cen_fam_uid;
quit;

** Restrict to family types 2 and 3 - two parents/sole parent with children;
data families (keep=snz_uid snz_cen_uid snz_cen_fam_uid apc_age_in_years_nbr apc_fertility_code
					child_depend_code snz_sex_gender_code emp_status cen_ind_id_family_nucleus
					cen_ind_family_role_code cen_ind_rltnshp_to_ref_code
					cen_fml_family_type_code cen_fml_people_count_code
					cen_fml_chld_dpnd_fmly_type_code cen_fml_child_count_code);
	set accpop_2 (where= (cen_fml_family_type_code in ('2','3')));
run;

data children;
	** Restrict to people in a child role in a family nucleus;
	set families (where= (cen_ind_family_role_code='41'));
run;

proc freq data=children;
	table apc_age_in_years_nbr child_depend_code;
run;

** Restrict to children aged under 18;
data children_0to17;
	set children;
	where apc_age_in_years_nbr<18;
run;

** Now identify all people in a parent role in the same family nucleus - this can include grandparents;
*11 Parent (other than grandparent) and spouse/partner in a family nucleus
*12 Grandparent in a parent role and spouse/partner in a family nucleus
*21 Sole parent (other than sole grandparent) in a family nucleus
*22 Sole grandparent in a parent role in a family nucleus;

proc datasets lib=sandpit; delete children_0to17_par;run;
proc sql;
	create table sandpit.children_0to17_par as
	select a.snz_uid,b.snz_uid as parent_snz_uid
	from children_0to17 a inner join families(where=(cen_ind_family_role_code in ('11','12','21','22'))) b
	on a.snz_cen_fam_uid=b.snz_cen_fam_uid
	order by snz_uid,parent_snz_uid;
quit;

** Check number of people in parent roles for each child;
proc freq data=children_0to17_par noprint;
	tables snz_uid/out=countfam;
run;
proc freq data=countfam;
	tables count;
run;

****Create parent 1 and parent 2 files and merge them to the children file;
/*
data families_c_1;
	set census.census_individual_2018(keep=snz_cen_uid snz_cen_fam_uid cen_ind_age_code cen_ind_fertility_code
					cen_ind_child_depend_code cen_ind_sex_code cen_ind_emplnt_stus_code cen_ind_id_family_nucleus);
run;
proc sql;
	create table families_c_2 as
	select a.*,b.cen_fml_family_type_code
	from families_c_1 a
	left join census.census_family_2018 b
	on a.snz_cen_fam_uid=b.snz_cen_fam_uid
	order by snz_cen_fam_uid;
quit;
data families_c_3;
	set families_c_2 (where= (cen_fml_family_type_code in ('1','2','3')));
run;

****TRY cen_ind_family_role_code instead;

proc freq data=accpop_2 ;
table 	child_depend_code*idd_id
		cen_fml_family_type_code*idd_id
		cen_ind_id_family_nucleus*idd_id/ nocol norow nopercent missing;
run;
proc freq data=census.census_individual_2018;
table 	cen_ind_child_depend_code*cen_ind_id_family_nucleus/ nocol norow nopercent missing;
run;*/