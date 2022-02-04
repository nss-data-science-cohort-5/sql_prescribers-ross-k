			-- NSS DS5 - SQL_Prescribers, Part 2 - ROSS KIMBERLIN --

/*
	1. How many npi numbers appear in the prescriber table but not in the prescription table?
	
	A - 4458.
*/

SELECT COUNT(*)
FROM
(
	SELECT pr.npi AS provider_NPI,
		pn.npi AS claim_npi
	FROM prescriber pr
		LEFT JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE pn.npi IS NULL
) npi_both;


/*
	2. a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
	
	A - LEVOTHYROXINE SODIUM; LISINOPRIL; ATORVASTATIN CALCIUM; AMLODIPINE BESYLATE; AND OMEPRAZOLE.
*/

SELECT DISTINCT d.generic_name,
	COALESCE(SUM(pn.total_claim_count),0) AS total_claims
FROM drug d
	INNER JOIN prescription pn
		ON d.drug_name = pn.drug_name
	INNER JOIN prescriber pr
		ON pr.npi = pn.npi
WHERE pr.specialty_description = 'Family Practice'
GROUP BY d.generic_name
ORDER BY total_claims DESC
LIMIT 5;


/*
    b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
	
	A - ATORVASTATIN CALCIUM; CARVEDILOL; METOPROLOL TARTRATE; CLOPIDOGREL BISULFATE; AND AMLODIPINE BESYLATE.
*/

SELECT DISTINCT d.generic_name,
	COALESCE(SUM(pn.total_claim_count),0) AS total_claims
FROM drug d
	INNER JOIN prescription pn
		ON d.drug_name = pn.drug_name
	INNER JOIN prescriber pr
		ON pr.npi = pn.npi
WHERE pr.specialty_description = 'Cardiology'
GROUP BY d.generic_name
ORDER BY total_claims DESC
LIMIT 5;


/*
    c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
*/


-- TO DO - RESEARCH WHY THIS DOES NOT WORK
; WITH cteFamPrac AS
(
	SELECT DISTINCT d.generic_name AS fam_prac_name,
		COALESCE(SUM(pn.total_claim_count),0) AS fam_prac_claims
	FROM drug d
		INNER JOIN prescription pn
			ON d.drug_name = pn.drug_name
		INNER JOIN prescriber pr
			ON pr.npi = pn.npi
	WHERE pr.specialty_description = 'Family Practice'
	GROUP BY d.generic_name
	ORDER BY fam_prac_claims DESC
	LIMIT 5
),
cteCard AS
(
	SELECT DISTINCT d.generic_name AS card_name,
		COALESCE(SUM(pn.total_claim_count),0) AS card_claims
	FROM drug d
		INNER JOIN prescription pn
			ON d.drug_name = pn.drug_name
		INNER JOIN prescriber pr
			ON pr.npi = pn.npi
	WHERE pr.specialty_description = 'Cardiology'
	GROUP BY d.generic_name
	ORDER BY card_claims DESC
	LIMIT 5
)
SELECT *
FROM cteFamPrac
INTERSECT
SELECT *
FROM cteCard
;
	
	
	
	-- RESEARCH: WHY DOES INTERSECT NOT WORK FOR THIS?
	SELECT DISTINCT d.generic_name,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM drug d
		INNER JOIN prescription pn
			ON d.drug_name = pn.drug_name
		INNER JOIN prescriber pr
			ON pr.npi = pn.npi
	WHERE pr.specialty_description = 'Family Practice'
	GROUP BY d.generic_name
	INTERSECT
	SELECT DISTINCT d.generic_name,
		COALESCE(SUM(pn.total_claim_count),0)
	FROM drug d
		INNER JOIN prescription pn
			ON d.drug_name = pn.drug_name
		INNER JOIN prescriber pr
			ON pr.npi = pn.npi
	WHERE pr.specialty_description = 'Cardiology'
	GROUP BY d.generic_name
	ORDER BY total_claims DESC
	LIMIT 5;


/*
3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

    a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
*/

	SELECT DISTINCT pr.npi,
		pr.nppes_provider_city,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM prescriber pr
		INNER JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY pr.npi,
		pr.nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5;
	

/*
	b. Now, report the same for Memphis.
*/

	SELECT DISTINCT pr.npi,
		pr.nppes_provider_city,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM prescriber pr
		INNER JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY pr.npi,
		pr.nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5;
	

/*
	c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
*/

	-- TO DO - RESEARCH A BETTER WAY TO DO THIS
	SELECT DISTINCT pr.npi,
		pr.nppes_provider_city,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM prescriber pr
		INNER JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE nppes_provider_city = 'CHATTANOOGA'
	GROUP BY pr.npi,
		pr.nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5
	UNION
		SELECT DISTINCT pr.npi,
		pr.nppes_provider_city,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM prescriber pr
		INNER JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY pr.npi,
		pr.nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5
	UNION
		SELECT DISTINCT pr.npi,
		pr.nppes_provider_city,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM prescriber pr
		INNER JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY pr.npi,
		pr.nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5
		SELECT DISTINCT pr.npi,
		pr.nppes_provider_city,
		COALESCE(SUM(pn.total_claim_count),0) AS total_claims
	FROM prescriber pr
		INNER JOIN prescription pn
			ON pr.npi = pn.npi
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY pr.npi,
		pr.nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5;
	

/*
	4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017. Report the county name and number of overdose deaths.
*/

	;WITH cteStateAvg AS
	(
		SELECT DISTINCT od.year,
			AVG(od.overdose_deaths) as avg_od
		FROM overdose_deaths od
		WHERE fipscounty IN
		(
			SELECT fipscounty
			FROM fips_county
			WHERE state = 'TN'
				AND year = '2017'
		)
		GROUP BY year
	)
	SELECT DISTINCT fc.county,
		o.overdose_deaths
	FROM fips_county fc
		INNER JOIN overdose_deaths o
			ON fc.fipscounty = o.fipscounty
	WHERE fc.state = 'TN'
		AND o.year = 2017 
		AND o.overdose_deaths > (
									SELECT avg_od
									FROM cteStateAvg
								)
	ORDER BY fc.county
	;


/*
	5. a. Write a query that finds the total population of Tennessee.
*/	

SELECT SUM(population) AS TN_total_pop
FROM population
WHERE fipscounty IN
(
	SELECT fipscounty
	FROM fips_county
	WHERE state = 'TN'
);


/*
    b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
*/

		TO DO!


;WITH cteFips AS
(	
	SELECT fipscounty AS fips_code,
		population AS fips_pop
	FROM population
	WHERE fipscounty IN
	(
		SELECT fipscounty
		FROM fips_county
		WHERE state = 'TN'
	)
),
cteTotalPop AS
(
	SELECT SUM(fips_pop) AS TN_total_pop
	FROM cteFips
)
SELECT DISTINCT fc.county,
	ctfp.fips_pop,
	ctfp.fips_pop / 
		(SELECT SUM(fips_pop)
		 FROM cteTotalPop ctp) AS Population_Pct
FROM fips_county fc
	INNER JOIN cteFips ctfp
		ON fc.fipscounty = ctfp.fips_code
WHERE state = 'TN'	
GROUP BY fc.county,
	ctfp.fips_pop
ORDER BY fc.county
;



	