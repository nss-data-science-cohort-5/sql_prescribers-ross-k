			-- NSS DS5 - SQL_Prescribers - ROSS KIMBERLIN --

/*
	1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

	   A - NPI 1881634483 had the highest number of claims at 99,707.
*/

SELECT DISTINCT pn.npi,  
	SUM(pn.total_claim_count) AS claim_sum
FROM prescription pn
GROUP BY pn.npi
ORDER BY claim_sum DESC;


/*
    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
*/

SELECT DISTINCT pn.npi,   
		pr.nppes_provider_first_name,
		pr.nppes_provider_last_org_name,
		pr.specialty_description,
	SUM(pn.total_claim_count) AS claim_sum
FROM prescription pn
	INNER JOIN prescriber pr
		ON pn.npi = pr.npi
GROUP BY pn.npi, 
		pr.nppes_provider_first_name,
		pr.nppes_provider_last_org_name,
		pr.specialty_description
ORDER BY claim_sum DESC;


/*
	2. a. Which specialty had the most total number of claims (totaled over all drugs)?
	
	   A - Family practice had 9,752,347.
*/

SELECT DISTINCT pr.specialty_description,
	SUM(pn.total_claim_count) AS claim_sum
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
GROUP BY pr.specialty_description
ORDER BY claim_sum DESC;


/*
    b. Which specialty had the most total number of claims for opioids?
	
	A - Nurse practitioners had the most at 900,845.
*/

SELECT DISTINCT pr.specialty_description,
	SUM(pn.total_claim_count) AS claim_sum
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY pr.specialty_description
ORDER BY claim_sum DESC;


/*
    c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
	
	A - No, not that I can detect.
*/

SELECT DISTINCT pr.specialty_description,
	SUM(pn.total_claim_count) AS claim_sum
FROM prescriber pr
	LEFT JOIN prescription pn
		ON pr.npi = pn.npi
GROUP BY pr.specialty_description
HAVING SUM(pn.total_claim_count) = 0
ORDER BY claim_sum DESC;


/*
    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
	
	A - Case Manager/Care Coordinator, Orthopaedic Surgery, Interventional Pain Management,
Anesthesiology, Pain Management, Hand Surgery, AND Surgical Oncology ALL HAVE MORE THAN 50% OPIOID CLAIMS.
*/

;WITH cteOpClaims AS
(
SELECT DISTINCT pr.specialty_description AS specialty,
	SUM(pn.total_claim_count) AS op_sum
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY pr.specialty_description
),
cteTotalClaims AS 
(
SELECT DISTINCT pr.specialty_description AS specialty,
	SUM(pn.total_claim_count) AS claim_sum
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		USING(drug_name)
GROUP BY pr.specialty_description
)
SELECT DISTINCT tc.specialty,
	oc.op_sum / tc.claim_sum AS opioid_pct
FROM cteOpClaims oc
	INNER JOIN cteTotalClaims tc
		USING(specialty)
ORDER BY opioid_pct DESC;


/*
	3. a. Which drug (generic_name) had the highest total drug cost?
*/



/*
       b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
*/


/*
	4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
*/

/*
       b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
*/


/*
	5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

       b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

       c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
*/


/*
6. 
    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
*/


/*
7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.

    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
*/



