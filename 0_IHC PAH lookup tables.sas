data pah_noninjury_lookup;
infile cards dlm='09'x dsd truncover;
length code3 $ 3 code4 $ 4 category subcategory $ 50;
input code3 $ code4 $ category $ subcategory $;
cards;
J12		Respiratory conditions	Pneumonia
J15		Respiratory conditions	Pneumonia
J16		Respiratory conditions	Pneumonia
J18		Respiratory conditions	Pneumonia
J69		Respiratory conditions	Pneumonia
	J851	Respiratory conditions	Pneumonia
J20		Respiratory conditions	Bronchitis
J21		Respiratory conditions	Bronchitis
J47		Respiratory conditions	Bronchitis
J45		Respiratory conditions	Asthma and wheezing
J46		Respiratory conditions	Asthma and wheezing
	R062	Respiratory conditions	Asthma and wheezing
J00		Respiratory conditions	Upper & ENT respiratory infections
J01		Respiratory conditions	Upper & ENT respiratory infections
J02		Respiratory conditions	Upper & ENT respiratory infections
J03		Respiratory conditions	Upper & ENT respiratory infections
J04		Respiratory conditions	Upper & ENT respiratory infections
J06		Respiratory conditions	Upper & ENT respiratory infections
	J050	Respiratory conditions	Upper & ENT respiratory infections
J22		Respiratory conditions	LRTI
K02		Dental conditions	Dental caries
K04		Dental conditions	Diseases of pulp and periodontal tissues
K25		Gastrointestinal diseases	Peptic ulcer
K26		Gastrointestinal diseases	Peptic ulcer
K27		Gastrointestinal diseases	Peptic ulcer
K28		Gastrointestinal diseases	Peptic ulcer
	K590	Gastrointestinal diseases	Constipation
A00		Gastrointestinal diseases	Gastroenteritis and dehydration
A01		Gastrointestinal diseases	Gastroenteritis and dehydration
A02		Gastrointestinal diseases	Gastroenteritis and dehydration
A03		Gastrointestinal diseases	Gastroenteritis and dehydration
A04		Gastrointestinal diseases	Gastroenteritis and dehydration
A05		Gastrointestinal diseases	Gastroenteritis and dehydration
A06		Gastrointestinal diseases	Gastroenteritis and dehydration
A07		Gastrointestinal diseases	Gastroenteritis and dehydration
A08		Gastrointestinal diseases	Gastroenteritis and dehydration
A09		Gastrointestinal diseases	Gastroenteritis and dehydration
R11		Gastrointestinal diseases	Gastroenteritis and dehydration
	K529	Gastrointestinal diseases	Gastroenteritis and dehydration
K21		Gastrointestinal diseases	Gastro-oesophageal reflux disease
D50		Nutritional deficiency and anaemia	Anaemia
D51		Nutritional deficiency and anaemia	Anaemia
D52		Nutritional deficiency and anaemia	Anaemia
D53		Nutritional deficiency and anaemia	Anaemia
E40		Nutritional deficiency and anaemia	Nutritional deficiency
E41		Nutritional deficiency and anaemia	Nutritional deficiency
E42		Nutritional deficiency and anaemia	Nutritional deficiency
E43		Nutritional deficiency and anaemia	Nutritional deficiency
E44		Nutritional deficiency and anaemia	Nutritional deficiency
E45		Nutritional deficiency and anaemia	Nutritional deficiency
E46		Nutritional deficiency and anaemia	Nutritional deficiency
E50		Nutritional deficiency and anaemia	Nutritional deficiency
E51		Nutritional deficiency and anaemia	Nutritional deficiency
E52		Nutritional deficiency and anaemia	Nutritional deficiency
E53		Nutritional deficiency and anaemia	Nutritional deficiency
E54		Nutritional deficiency and anaemia	Nutritional deficiency
E55		Nutritional deficiency and anaemia	Nutritional deficiency
E56		Nutritional deficiency and anaemia	Nutritional deficiency
E58		Nutritional deficiency and anaemia	Nutritional deficiency
E59		Nutritional deficiency and anaemia	Nutritional deficiency
E60		Nutritional deficiency and anaemia	Nutritional deficiency
E61		Nutritional deficiency and anaemia	Nutritional deficiency
E63		Nutritional deficiency and anaemia	Nutritional deficiency
E64		Nutritional deficiency and anaemia	Nutritional deficiency
I00		Cardiovascular diseases	Acute rheumatic fever
I02		Cardiovascular diseases	Acute rheumatic fever
I05		Cardiovascular diseases	Chronic rheumatic heart diseases
I06		Cardiovascular diseases	Chronic rheumatic heart diseases
I07		Cardiovascular diseases	Chronic rheumatic heart diseases
I08		Cardiovascular diseases	Chronic rheumatic heart diseases
I09		Cardiovascular diseases	Chronic rheumatic heart diseases
H65		Otitis media	Otitis media
H66		Otitis media	Otitis media
H67		Otitis media	Otitis media
L00		Dermatological conditions	Skin infection
L01		Dermatological conditions	Skin infection
L02		Dermatological conditions	Skin infection
L03		Dermatological conditions	Skin infection
L04		Dermatological conditions	Skin infection
L05		Dermatological conditions	Skin infection
L08		Dermatological conditions	Skin infection
L20		Dermatological conditions	Dermatitis and eczema
L21		Dermatological conditions	Dermatitis and eczema
L22		Dermatological conditions	Dermatitis and eczema
L23		Dermatological conditions	Dermatitis and eczema
L24		Dermatological conditions	Dermatitis and eczema
L25		Dermatological conditions	Dermatitis and eczema
L26		Dermatological conditions	Dermatitis and eczema
L27		Dermatological conditions	Dermatitis and eczema
L28		Dermatological conditions	Dermatitis and eczema
L29		Dermatological conditions	Dermatitis and eczema
L30		Dermatological conditions	Dermatitis and eczema
E10		Diabetes complications	Diabetes complications
E11		Diabetes complications	Diabetes complications
E13		Diabetes complications	Diabetes complications
E14		Diabetes complications	Diabetes complications
	E162	Diabetes complications	Diabetes complications
N10		Kidney, urinary tract infections	Kidney, urinary tract infections
N12		Kidney, urinary tract infections	Kidney, urinary tract infections
	N136	Kidney, urinary tract infections	Kidney, urinary tract infections
	N300	Kidney, urinary tract infections	Kidney, urinary tract infections
	N309	Kidney, urinary tract infections	Kidney, urinary tract infections
	N390	Kidney, urinary tract infections	Kidney, urinary tract infections
A50		Sexually transmitted infections	Sexually transmitted infections
A51		Sexually transmitted infections	Sexually transmitted infections
A52		Sexually transmitted infections	Sexually transmitted infections
A53		Sexually transmitted infections	Sexually transmitted infections
A54		Sexually transmitted infections	Sexually transmitted infections
A55		Sexually transmitted infections	Sexually transmitted infections
A56		Sexually transmitted infections	Sexually transmitted infections
A57		Sexually transmitted infections	Sexually transmitted infections
A58		Sexually transmitted infections	Sexually transmitted infections
A59		Sexually transmitted infections	Sexually transmitted infections
A60		Sexually transmitted infections	Sexually transmitted infections
A63		Sexually transmitted infections	Sexually transmitted infections
A64		Sexually transmitted infections	Sexually transmitted infections
	M023	Sexually transmitted infections	Sexually transmitted infections
	N341	Sexually transmitted infections	Sexually transmitted infections
J09		Vaccine preventable diseases	Influenza and related pneumonia, meningitis
J10		Vaccine preventable diseases	Influenza and related pneumonia, meningitis
J11		Vaccine preventable diseases	Influenza and related pneumonia, meningitis
J13		Vaccine preventable diseases	Influenza and related pneumonia, meningitis
J14		Vaccine preventable diseases	Influenza and related pneumonia, meningitis
	G000	Vaccine preventable diseases	Influenza and related pneumonia, meningitis
	A080	Vaccine preventable diseases	Rotaviral enteritis
A33		Vaccine preventable diseases	Tetanus
A34		Vaccine preventable diseases	Tetanus
A35		Vaccine preventable diseases	Tetanus
A36		Vaccine preventable diseases	Diphtheria
	A370	Vaccine preventable diseases	Whooping cough
	A371	Vaccine preventable diseases	Whooping cough
	A378	Vaccine preventable diseases	Whooping cough
	A379	Vaccine preventable diseases	Whooping cough
A80		Vaccine preventable diseases	Acute poliomyelitis
	B010	Vaccine preventable diseases	Varicella
	B011	Vaccine preventable diseases	Varicella
	B012	Vaccine preventable diseases	Varicella
	B018	Vaccine preventable diseases	Varicella
	B019	Vaccine preventable diseases	Varicella
	B050	Vaccine preventable diseases	Measles
	B051	Vaccine preventable diseases	Measles
	B052	Vaccine preventable diseases	Measles
	B053	Vaccine preventable diseases	Measles
	B054	Vaccine preventable diseases	Measles
	B058	Vaccine preventable diseases	Measles
	B059	Vaccine preventable diseases	Measles
B06		Vaccine preventable diseases	Rubella
	P350	Vaccine preventable diseases	Rubella
	M014	Vaccine preventable diseases	Rubella
	B150	Vaccine preventable diseases	Hepatitis A, B, C
	B159	Vaccine preventable diseases	Hepatitis A, B, C
	B160	Vaccine preventable diseases	Hepatitis A, B, C
	B161	Vaccine preventable diseases	Hepatitis A, B, C
	B162	Vaccine preventable diseases	Hepatitis A, B, C
	B169	Vaccine preventable diseases	Hepatitis A, B, C
	B171	Vaccine preventable diseases	Hepatitis A, B, C
	B180	Vaccine preventable diseases	Hepatitis A, B, C
	B181	Vaccine preventable diseases	Hepatitis A, B, C
	B182	Vaccine preventable diseases	Hepatitis A, B, C
	B260	Vaccine preventable diseases	Mumps
	B261	Vaccine preventable diseases	Mumps
	B262	Vaccine preventable diseases	Mumps
	B263	Vaccine preventable diseases	Mumps
	B268	Vaccine preventable diseases	Mumps
	B269	Vaccine preventable diseases	Mumps
A15		Vaccine preventable diseases	Tuberculosis
A16		Vaccine preventable diseases	Tuberculosis
A17		Vaccine preventable diseases	Tuberculosis
A18		Vaccine preventable diseases	Tuberculosis
A19		Vaccine preventable diseases	Tuberculosis
	A390	Meningococcal infections	Meningococcal infections
	A391	Meningococcal infections	Meningococcal infections
	A392	Meningococcal infections	Meningococcal infections
	A393	Meningococcal infections	Meningococcal infections
	A394	Meningococcal infections	Meningococcal infections
	A395	Meningococcal infections	Meningococcal infections
	A398	Meningococcal infections	Meningococcal infections
	A399	Meningococcal infections	Meningococcal infections
G40		Epilepsy	Epilepsy
G41		Epilepsy	Epilepsy
O15		Epilepsy	Epilepsy
R568		Epilepsy	Epilepsy
M86		Other non-injury conditions	Other non-injury conditions
A87		Other non-injury conditions	Other non-injury conditions
G01		Other non-injury conditions	Other non-injury conditions
G02		Other non-injury conditions	Other non-injury conditions
G03		Other non-injury conditions	Other non-injury conditions
B34		Other non-injury conditions	Other non-injury conditions
	A403	Other non-injury conditions	Other non-injury conditions
;
run;