			-- NSS DS5 - SQL_Prescribers, Part 1 - ROSS KIMBERLIN --

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
	SUM(pn.total_claim_count)     AS claim_sum
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
	SUM(pn.total_claim_count)          AS claim_sum
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
	SUM(pn.total_claim_count)          AS claim_sum
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
	
	A - Yes, 14 of them.
*/


SELECT DISTINCT pr.specialty_description,
	COUNT(pn.total_claim_count)   AS claim_cnt
FROM prescriber pr
	LEFT JOIN prescription pn
		ON pr.npi = pn.npi
-- WHERE SUM(pn.total_claim_count) IS NULL
GROUP BY pr.specialty_description
HAVING COUNT(pn.total_claim_count) = 0
ORDER BY claim_cnt DESC;


/*
    d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
	
	A - Case Manager/Care Coordinator, Orthopaedic Surgery, Interventional Pain Management,
Anesthesiology, Pain Management, Hand Surgery, AND Surgical Oncology ALL HAVE MORE THAN 50% OPIOID CLAIMS.
*/

;WITH cteOpClaims AS
(
	SELECT DISTINCT pr.specialty_description AS specialty,
		SUM(pn.total_claim_count)            AS op_sum
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
		SUM(pn.total_claim_count)            AS claim_sum
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
WHERE oc.op_sum / tc.claim_sum > .5
ORDER BY opioid_pct DESC;


/*
	3. a. Which drug (generic_name) had the highest total drug cost?
	
	   A - Insulin glargine has the highest total cost at $104,264,066.35.
*/

SELECT DISTINCT d.generic_name, 
	SUM(p.total_drug_cost)::money     AS drug_cost
FROM drug d
	INNER JOIN prescription p
		ON d.drug_name = p.drug_name
	--	ON d.generic_name = p.drug_name
GROUP BY d.generic_name
ORDER BY drug_cost DESC;


/*
       b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
	   
	  A - C1 Esterase Inhibitor at $3495.22 per day (?!?). 
*/

SELECT DISTINCT d.generic_name, 
	SUM(p.total_drug_cost)::money / ROUND(SUM(total_day_supply), 2)    AS cost_per_day
FROM drug d
	INNER JOIN prescription p
		ON d.drug_name = p.drug_name
	--	ON d.generic_name = p.drug_name
GROUP BY d.generic_name
ORDER BY cost_per_day DESC;
			 

/*
	4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
*/

SELECT DISTINCT drug_name,
	CASE WHEN opioid_drug_flag = 'Y'     THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither'
	END AS drug_type
FROM drug
ORDER BY drug_name;


/*
       b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
	   
	   A - More money was spent on opioids than on antibiotics
	   		($105,080,626.37 vs $34,972,135.84--opioid crisis, anyone?).
*/

;WITH cteDrugType AS
(
	SELECT DISTINCT drug_name,	-- SOME DRUGS ARE COUNTED TWICE, BOTH AS OPIOIDS AND NON-OPIOIDS - OPIOIDS CRUSH EVERYTHING ELSE REGARDLESS
		CASE WHEN opioid_drug_flag = 'Y'     THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE 'neither'
		END AS drug_type
	FROM drug
)
SELECT DISTINCT cdt.drug_type, 
	SUM(p.total_drug_cost::money)     AS drug_cost
FROM cteDrugType cdt
	INNER JOIN prescription p
		ON cdt.drug_name = p.drug_name
WHERE cdt.drug_type <> 'neither'
GROUP BY cdt.drug_type
ORDER BY drug_cost DESC;



/*
	5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
	
	   A - 10.
*/

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';


/*
       b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
	   
	   A - Nashville-Davidson--Murfreesboro--Franklin has the largest combined population in TN with 1,830,410 people, while Morristown has the smallest with 116,352 people.
*/	

	SELECT DISTINCT c.cbsaname,
		SUM(p.population) AS pop
	FROM cbsa c
		INNER JOIN fips_county fc
			ON c.fipscounty = fc.fipscounty
		INNER JOIN population p
			ON fc.fipscounty = p.fipscounty
	WHERE fc.state = 'TN'
		AND cbsaname LIKE '%TN%'
	GROUP BY c.cbsaname
	ORDER BY pop DESC;



	-- BRYAN HAD THIS TO SHOW ONLY THE HIGHEST AND LOWEST VALUES
	select *
	from 
	(
		select cbsa.cbsa, sum(population) total_population
	      from cbsa
	               inner join population p on cbsa.fipscounty = p.fipscounty
	      group by cbsa.cbsa
	      order by total_population desc
	      limit 1
	) sq1
	union
	select *
	from 
	(
		select cbsa.cbsa, sum(population) total_population
	      from cbsa
	               inner join population p on cbsa.fipscounty = p.fipscounty
	      group by cbsa.cbsa
	      order by total_population asc
	      limit 1
	) sq1


/*
       c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
	   
	   A - Sevier County, TN.
*/

SELECT fc.county,
	c.cbsa,
	p.population AS pop
FROM fips_county fc
	LEFT JOIN cbsa c
		ON fc.fipscounty = c.fipscounty
	INNER JOIN population p
		ON fc.fipscounty = p.fipscounty
WHERE c.cbsa IS NULL
	AND fc.state = 'TN'
ORDER BY pop DESC;


/*
	6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
*/

SELECT drug_name,
	total_claim_count AS total_claims
FROM prescription
WHERE total_claim_count >= 3000
-- GROUP BY drug_name
ORDER BY drug_name;


/*
    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
*/

SELECT p.drug_name,
		CASE WHEN d.opioid_drug_flag = 'Y' THEN 'Opioid'
			 						   ELSE 'Non-opioid'
					END AS drug_type,
	p.total_claim_count AS total_claims
FROM prescription p
	INNER JOIN drug d
		ON p.drug_name = d.drug_name
WHERE p.total_claim_count >= 3000
-- GROUP BY drug_name
ORDER BY p.drug_name;


/*
    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
*/

SELECT pn.drug_name,
		CASE WHEN d.opioid_drug_flag = 'Y'     THEN 'Opioid'
			 							   ELSE 'Non-opioid'
									END AS drug_type,
	pr.nppes_provider_first_name || ' ' || 
		pr.nppes_provider_last_org_name AS provider_name,
	pn.total_claim_count 				AS total_claims
FROM prescription pn
	INNER JOIN drug d
		ON pn.drug_name = d.drug_name
	INNER JOIN prescriber pr
		ON pn.npi = pr.npi
WHERE pn.total_claim_count >= 3000
-- GROUP BY drug_name
ORDER BY pn.drug_name;



/*
	7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
    
	a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.
*/

	-- CONRAD HAD THIS:
	SELECT npi, drug_name
	FROM prescriber
	CROSS JOIN drug
	WHERE nppes_provider_city = 'NASHVILLE'
		AND specialty_description = 'Pain Management'
		AND opioid_drug_flag = 'Y'
	

/*
    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
*/

SELECT pr.npi,
	d.drug_name,
	COALESCE(SUM(pn.total_claim_count),0) AS total_claims
FROM prescriber pr
	LEFT JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		ON pn.drug_name = d.drug_name
WHERE pr.nppes_provider_city = 'NASHVILLE' 	
	AND pr.specialty_description = 'Pain Management'
	AND d.opioid_drug_flag = 'Y'
GROUP BY pr.npi,
	d.drug_name
ORDER BY total_claims DESC;

	
	-- FOR TESTING UNASSOCIATED RECORDS
	SELECT pr.npi AS provider_NPI,
		pn.npi AS claim_npi,
		pr.nppes_provider_first_name || ' ' || 
			pr.nppes_provider_last_org_name AS provider_name,
		pn.total_claim_count AS total_claims
	FROM prescriber pr
		LEFT JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE pn.npi IS NULL
		AND pr.nppes_provider_city = 'NASHVILLE' 
		AND pr.specialty_description = 'Pain Management'	
	ORDER BY pr.npi DESC;


	-- CONRAD HAD THIS:
	SELECT npi, drug_name, COALESCE(total_claim_count, 0)
	FROM
	(
		SELECT npi, drug_name
		FROM prescriber
		CROSS JOIN drug
		WHERE nppes_provider_city = 'NASHVILLE'
			AND specialty_description = 'Pain Management'
			AND opioid_drug_flag = 'Y'
	) AS a
		LEFT JOIN prescription
			USING(npi, drug_name)
	ORDER BY npi;


/*
    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
*/


