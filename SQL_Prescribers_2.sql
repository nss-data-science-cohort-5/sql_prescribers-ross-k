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


	-- HABEEB HAD
	SELECT 
		(SELECT COUNT(DISTINCT npi) AS npi_count
		FROM prescriber) - 
		(SELECT COUNT(DISTINCT npi) AS npi_count
		FROM prescription) AS npi_difference


	-- JESSICA HAD
	SELECT COUNT(npi)
	FROM prescriber
	WHERE NOT EXISTS 
	(
    	SELECT npi
    	FROM prescription
    	WHERE prescriber.npi = prescription.npi
	);
	
/*
	2. a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
	
	A - LEVOTHYROXINE SODIUM, LISINOPRIL, ATORVASTATIN CALCIUM, AMLODIPINE BESYLATE, and OMEPRAZOLE.
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
	
	A - ATORVASTATIN CALCIUM, CARVEDILOL, METOPROLOL TARTRATE, CLOPIDOGREL BISULFATE, and AMLODIPINE BESYLATE.
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
	
	A - ATORVASTATIN CALCIUM, LEVOTHYROXINE SODIUM, AMLODIPINE BESYLATE, LISINOPRIL, and FUROSEMIDE.
*/

	-- tmp TABLE WAY STILL NOT WORKING
	CREATE TEMP TABLE tmp_card
	(
		generic_name text,
		total_claims numeric
	);
	
	CREATE TEMP TABLE tmp_fam
	(
		generic_name text,
		total_claims numeric
	);

	BEGIN TRANSACTION;
	INSERT INTO tmp_card
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
	COMMIT TRANSACTION;
	

	BEGIN TRANSACTION;
	INSERT INTO tmp_fam
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
	COMMIT TRANSACTION;
	
	
	SELECT *
	FROM tmp_card
	INTERSECT
	SELECT *
	FROM tmp_fam
	ORDER BY generic_name
	;
	
	

	-- THIS DOES NOT GENERATE THE RIGHT RESULTS
	SELECT DISTINCT d.generic_name AS fam_prac_name,
		COALESCE(SUM(pn.total_claim_count),0) AS fam_prac_claims
	FROM drug d
		INNER JOIN prescription pn
			ON d.drug_name = pn.drug_name
		INNER JOIN prescriber pr
			ON pr.npi = pn.npi
	WHERE pr.specialty_description IN 
		('Family Practice', 'Cardiology')
	GROUP BY d.generic_name
	ORDER BY fam_prac_claims DESC
	LIMIT 5;




-- WHY DOES THIS NOT WORK?
SELECT *	-- USING BRYAN'S TRICK FROM SQL_Prescribers Question 5b)
FROM 
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
) sq1
INTERSECT
SELECT *
FROM 
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
) sq2;



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

-- tmp TABLE VERSION
CREATE TEMP TABLE tmp_Chattanooga
(
	npi numeric,
	nppes_provider_city text,
	total_claims numeric
);

CREATE TEMP TABLE tmp_Knoxville
(
	npi numeric,
	nppes_provider_city text,
	total_claims numeric
);

CREATE TEMP TABLE tmp_Memphis
(
	npi numeric,
	nppes_provider_city text,
	total_claims numeric
);

CREATE TEMP TABLE tmp_Nashville
(
	npi numeric,
	nppes_provider_city text,
	total_claims numeric
);

BEGIN TRANSACTION;
INSERT INTO tmp_Chattanooga
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
LIMIT 5;
COMMIT TRANSACTION;


BEGIN TRANSACTION;
INSERT INTO tmp_Knoxville
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
LIMIT 5;
COMMIT TRANSACTION;


BEGIN TRANSACTION;
INSERT INTO tmp_Memphis
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
COMMIT TRANSACTION;


BEGIN TRANSACTION;
INSERT INTO tmp_Nashville
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
COMMIT TRANSACTION;


SELECT *
FROM tmp_Chattanooga
UNION 
SELECT *
FROM tmp_Knoxville
UNION 
SELECT *
FROM tmp_Memphis
UNION 
SELECT *
FROM tmp_Nashville
ORDER BY nppes_provider_city,
	npi
;


	-- MAYBE RESEARCH pivot OPTION??


	-- cte UNION VERSION NOT WORKING - TO DO - RESEARCH A BETTER WAY TO DO THIS
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
	UNION
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

-- FIRST PASS OF TO_CHAR(123456.78, 'fm999G999D99') NOT WORKING - SEE https://database.guide/format-numbers-with-commas-in-postgresql/ 
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
	ctfp.fips_pop AS County_Pop,
	(SELECT ROUND(ctfp.fips_pop * 100 / 
		(SELECT TN_total_pop
		 FROM cteTotalPop ctp), 2)) AS Pct_of_State_Pop
FROM fips_county fc
	INNER JOIN cteFips ctfp
		ON fc.fipscounty = ctfp.fips_code
WHERE state = 'TN'	
GROUP BY fc.county,
	ctfp.fips_pop
ORDER BY fc.county
;



	