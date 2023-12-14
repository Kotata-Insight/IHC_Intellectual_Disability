/**Setting library names for MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)

Project - MAA2022-54 Health and Social Indicators for New Zealanders with Intellectual Disabilities (IHC)
Funder - IHC
Researchers - Keith McLeod and Luisa Beltran-Castillon from Kotata Insight
Code written by - Luisa Beltran-Castillon 
Start date - 10/01/2023
Code location - I:\MAA2022-54\code

Approved datasets:

CLEAN_READ_ACC
CLEAN_READ_CENSUS2013
CLEAN_READ_CENSUS2018
CLEAN_READ_COR
CLEAN_READ_DIA
CLEAN_READ_DOL
CLEAN_READ_GEOGRAPHIC
CLEAN_READ_HNZ
CLEAN_READ_IR_restrict
CLEAN_READ_MOE
CLEAN_READ_MOH_CHRONIC_CONDITION
CLEAN_READ_MOH_HOSPITAL_DISCHARGES
CLEAN_READ_MOH_LAB_CLAIMS
CLEAN_READ_MOH_MORTALITY
CLEAN_READ_MOH_NNPAC
CLEAN_READ_MOH_PHARMACEUTICAL
CLEAN_READ_MOH_PHO_ENROLMENT
CLEAN_READ_MOH_PRIMHD
CLEAN_READ_MOH_SOCRATES
CLEAN_READ_MSD
CLEAN_READ_NZTA
CLEAN_READ_POL
CLEAN_READ_WFF
CLEAN_READ_CYF

*/ 

%LET extractdate = 202210;

** Project shared space;
libname project '/nas/DataLab/MAA/MAA2022-54/data';

** Project sandpit;
LIBNAME sandpit ODBC dsn=idi_sandpit_srvprd schema="DL-MAA2022-54" insertbuff=32767 dbcommit=32767;

** IDI Libnames;
LIBNAME ACC ODBC dsn=idi_clean_&extractdate._srvprd schema=acc_clean;
LIBNAME CENSUS ODBC dsn=idi_clean_&extractdate._srvprd schema=cen_clean;
LIBNAME COR ODBC dsn=idi_clean_&extractdate._srvprd schema=cor_clean;
LIBNAME DIA ODBC dsn=idi_clean_&extractdate._srvprd schema=dia_clean;
LIBNAME DOL ODBC dsn=idi_clean_&extractdate._srvprd schema=dol_clean;
LIBNAME GEOG ODBC dsn=idi_clean_&extractdate._srvprd schema=geography_clean;/*this code gives an error - KM - was too long, libname >8 characters*/
LIBNAME HNZ ODBC dsn=idi_clean_&extractdate._srvprd schema=hnz_clean;
LIBNAME IR ODBC dsn=idi_clean_&extractdate._srvprd schema=ir_clean;
LIBNAME MOE ODBC dsn=idi_clean_&extractdate._srvprd schema=moe_clean;
LIBNAME MOH ODBC dsn=idi_clean_&extractdate._srvprd schema=moh_clean;
LIBNAME MOJ ODBC dsn=idi_clean_&extractdate._srvprd schema=moj_clean;
LIBNAME MSD ODBC dsn=idi_clean_&extractdate._srvprd schema=msd_clean;
LIBNAME NZTA ODBC dsn=idi_clean_&extractdate._srvprd schema=nzta_clean;
LIBNAME POL ODBC dsn=idi_clean_&extractdate._srvprd schema=pol_clean;
LIBNAME WFF ODBC dsn=idi_clean_&extractdate._srvprd schema=wff_clean;
LIBNAME CYF ODBC dsn=idi_clean_&extractdate._srvprd schema=cyf_clean; /** KM - Note we arent listed as having acces to this, although we requested it */

LIBNAME SNZDATA ODBC dsn=idi_clean_&extractdate._srvprd schema=data; /* KM - Note admin census data (begins APC) is stored here */
libname security ODBC dsn=idi_clean_&extractdate._srvprd schema=security  ;
libname metadata ODBC dsn=idi_clean_&extractdate._srvprd schema=metadata;
libname old_meta ODBC dsn=idi_metadata_srvprd schema=clean_read_CLASSIFICATIONS;

libname mojmeta ODBC dsn=idi_metadata_&extractdate._srvprd schema=moj;
libname moemeta ODBC dsn=idi_metadata_&extractdate._srvprd schema=moe_school;

** Adhoc;
LIBNAME SOCRATES ODBC dsn=idi_adhoc schema=clean_read_MOH_SOCRATES;
LIBNAME moeadhoc ODBC dsn=idi_adhoc schema=clean_read_MOE;
LIBNAME msdADHOC ODBC dsn=idi_adhoc schema=clean_read_msd;
/* KM - We might need to get access to interrai also, for the older population */

** Set macro vars for project folders;
%let outfolder=/nas/DataLab/MAA/MAA2022-54/output;


