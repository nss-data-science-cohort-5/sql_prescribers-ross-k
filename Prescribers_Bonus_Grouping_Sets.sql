			-- NSS DS5 - Prescribers_Bonus_Grouping_Sets - ROSS KIMBERLIN --
	
/*	
	In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres. 

	For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

	1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

specialty_description         |total_claims|
------------------------------|------------|
Interventional Pain Management|       55906|
Pain Management               |       70853|

*/

SELECT DISTINCT pr.specialty_description,
	SUM(pn.total_claim_count) AS total_claims
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
WHERE pr.specialty_description IN
	('Interventional Pain Management', 'Pain Management')
GROUP BY pr.specialty_description
ORDER BY pr.specialty_description
;


/*
	2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

specialty_description         |total_claims|
------------------------------|------------|
                              |      126759|
Interventional Pain Management|       55906|
Pain Management               |       70853|

*/

SELECT *
FROM
(
	SELECT pr.specialty_description,
	SUM(pn.total_claim_count) AS total_claims
	FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	WHERE pr.specialty_description = 'Interventional Pain Management'
	GROUP BY pr.specialty_description
) sq1
UNION	-- UNION vs UNION ALL SEEMS TO MAKE NO DIFFERENCE HERE
SELECT *
FROM 
(
	SELECT pr.specialty_description,
	SUM(pn.total_claim_count) AS total_claims
	FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	WHERE pr.specialty_description = 'Pain Management'
	GROUP BY pr.specialty_description
) sq2
UNION
SELECT *
FROM 
(
	SELECT NULL,
	SUM(pn.total_claim_count) AS total_claims
	FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	WHERE pr.specialty_description IN
		('Interventional Pain Management', 'Pain Management')
) sq3
;


/*
3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.
*/

SELECT pr.specialty_description,
	SUM(pn.total_claim_count) AS total_claims
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
WHERE pr.specialty_description IN
	('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS ((), (pr.specialty_description));


/*
	4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

specialty_description         |opioid_drug_flag|total_claims|
------------------------------|----------------|------------|
                              |                |      129726|
                              |Y               |       76143|
                              |N               |       53583|
Pain Management               |                |       72487|
Interventional Pain Management|                |       57239|

*/

SELECT pr.specialty_description,
	d.opioid_drug_flag,
	SUM(pn.total_claim_count) AS total_claims
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		ON pn.drug_name = d.drug_name
WHERE pr.specialty_description IN
	('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS ((), (d.opioid_drug_flag),
	(pr.specialty_description));


/*
	5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?
	
	A - ROLLUP gives us addtional summaries for more levels of aggregation with hierarchical relationships.  In this case, 
not only do we still aggregate for Opioid Drug Flag, as we did in Question 4, we also aggregate for Opioid Drug Flag WITHIN Specialties.  However, what we no longer see is different aggregations for individual Specialty Description regardless of Drug Flags (we do still see the combined total claims for both specialty descritpions).  We will see these re-appear when we switch the ROLLUP order in Question 6.
*/

SELECT pr.specialty_description,
	d.opioid_drug_flag,
	SUM(pn.total_claim_count) AS total_claims
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		ON pn.drug_name = d.drug_name
WHERE pr.specialty_description IN
	('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(opioid_drug_flag, specialty_description);
	

/*
	6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?
	
	Here we see the reverse of our result set from Question 5.  We have total claims for both specialty descriptions, and also hierarchical aggregations for drug flags WITHIN specialties, but we no longer have aggregations for Opioid Drug Flags regardless of Specialty Description.
*/

SELECT pr.specialty_description,
	d.opioid_drug_flag,
	SUM(pn.total_claim_count) AS total_claims
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		ON pn.drug_name = d.drug_name
WHERE pr.specialty_description IN
	('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(specialty_description, opioid_drug_flag);


/*
	7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
	
	A - CUBE shows us all possible levels of aggregation referred to in Questions 5 and 6.  It is actually shorthand for GROUP BY GROUPING SETS((), (pr.specialty_description), (d.opioid_drug_flag), (pr.specialty_description, d.opioid_drug_flag)).
*/

SELECT pr.specialty_description,
	d.opioid_drug_flag,
	SUM(pn.total_claim_count) AS total_claims
FROM prescriber pr
	INNER JOIN prescription pn
		ON pr.npi = pn.npi
	INNER JOIN drug d
		ON pn.drug_name = d.drug_name
WHERE pr.specialty_description IN
	('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE(specialty_description, opioid_drug_flag)
--GROUP BY GROUPING SETS((), (pr.specialty_description), (d.opioid_drug_flag), (pr.specialty_description, d.opioid_drug_flag))
;


/*
	8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

The end result of this question should be a table formatted like this:

city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-----------|-------|--------|-----------|--------|---------|-----------|
CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
	CREATE EXTENSION tablefunc;

Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.

Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.

Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.

*/


