
/*ACCESS DATA*/

%let path=ECRB94/data;
libname tsa "&path";
options validvarname=v7;

proc import datafile="&path/TSAClaims2002_2017.csv" dbms=csv 
		out=tsa.ClaimsImport replace;
	guessingrows=max;
run;

proc print data=tsa.ClaimsImport (obs=20);
run;

proc contents data=tsa.ClaimsImport varnum;
run;

proc freq data=tsa.ClaimsImport;
	tables Claim_Site Disposition Claim_Type / nocum nopercent;
	tables Date_Received Incident_Date / nocum nopercent;
	format Date_Received Incident_Date year4.;
run;

/*PREPARE DATA*/

proc sort data=tsa.ClaimsImport out=tsa.Claims_NoDups nodupkey;
	by _all_;
run;

proc sort data=tsa.Claims_NoDups;
	by Incident_Date;
run;

data tsa.claims_cleaned;
	set tsa.claims_nodups;

	if Claim_site in ('-', '') then
		Claim_Site="Unknown";

	if Disposition in ("-", "") then
		Disposition='Unknown';
	else if Disposition='Closed: Canceled' then
		Disposition='Closed:Canceled';
	else if Disposition='losed: Contractor Claim' then
		Disposition='Closed:Contractor Claim';

	if Claim_Type in ("-", "") then
		Claim_Type="Unknown";
	else if Claim_Type='Passenger Property Loss/Personal Injur' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Passenger Property Loss/Personal Injury' then
		Claim_Type='Passenger Property Loss';
	else if Claim_Type='Property Damage/Personal Injury' then
		Claim_Type='Property Damage';
	State=upcase(state);
	StateName=propcase(StateName);

	if (Incident_Date > Date_Received or Incident_Date=. or Date_Received=. or 
		year(Incident_Date) < 2002 or year(Incident_Date) > 2017 or 
		year(Date_Received) < 2002 or year(Date_Received) > 2017) then
			Date_Issues="Needs Review";
	format Incident_Date Date_Received date9. Close_Amount Dollar20.2;
	label Airport_Code="Airport Code" Airport_Name="Airport Name" 
		Claim_Number="Claim Number" Claim_Site="Claim Site" Claim_Type="Claim Type" 
		Close_Amount="Close Amount" Date_Issues="Date Issues" 
		Date_Received="Date Received" Incident_Date="Incident Date" 
		Item_Category="Item Category";
	drop County City;
run;

proc freq data=tsa.Claims_Cleaned order=freq;
	tables Claim_Site
		Disposition
		Claim_Type
		Date_Issues/nopercent nocum;
run;

/*ANALYZE DATA*/

title "Overall Date Issues in the Data";
proc freq data=TSA.Claims_Cleaned;
 table Date_Issues / missing nocum nopercent;
run;
title;

ods graphics on;
title "Overall Claims by Year";
proc freq data=TSA.Claims_Cleaned;
 table Incident_Date / nocum nopercent plots=freqplot;
 format Incident_Date year4.;
 where Date_Issues is null;
run;
title;

%let StateName=Hawaii;
title "&StateName Claim Types, Claim Sites and Disposition
Frequencies";
proc freq data=TSA.Claims_Cleaned order=freq;
 table Claim_Type Claim_Site Disposition / nocum nopercent;
 where StateName="&StateName" and Date_Issues is null;
run;
title "Close_Amount Statistics for &StateName";
proc means data=TSA.Claims_Cleaned mean min max sum maxdec=0;
 var Close_Amount;
 where StateName="&StateName" and Date_Issues is null;
run;
title;

