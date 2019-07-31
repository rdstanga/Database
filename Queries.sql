/* 1. List a specific company's workers by names. */
SELECT name
FROM works NATURAL JOIN position NATURAL JOIN person NATURAL JOIN company
WHERE comp_id = ?

/* 2. List a specific company's staff (salary workers) by salary in descending order. */
SELECT name, pay_type, pay_rate
FROM works NATURAL JOIN position NATURAL JOIN person NATURAL JOIN company
WHERE pay_type = 'salary' AND comp_id = ?
GROUP BY pay_type, name, pay_rate
ORDER BY pay_rate DESC

/* 3. List the average annual pay (the salary or wage rates multiplying by 1920 hours) of each company in descending order. */
SELECT comp_id, AVG(pay) AS average
FROM (SELECT comp_id, (pay_rate) * 1920 AS pay
	  FROM position
 	  WHERE pay_type = 'wage'
 	  UNION
	  SELECT comp_id, pay_rate AS pay
	  FROM position
	  WHERE pay_type = 'salary')
GROUP BY comp_id
ORDER BY average DESC

/* 4. List the average, maximum and minimum annual pay (total salaries or wage rates multiplying by 1920 hours) of each industry (listed in GICS) in the order of the industry names. */
WITH total_pay AS (SELECT comp_id, pay
		   FROM (SELECT comp_id, (pay_rate) * 1920 AS pay
				 FROM position
				 WHERE pay_type = 'wage'
				 UNION
				 SELECT comp_id, pay_rate AS pay
				 FROM position
				 WHERE pay_type = 'salary'))
SELECT ind_title, AVG(pay) AS avg_pay, MIN(pay) AS min_pay, MAX(pay) AS max_pay
FROM total_pay NATURAL JOIN industry_company NATURAL JOIN gics
WHERE hierarchy = 'industry'
GROUP BY ind_title
ORDER BY ind_title

/* 5.1 Find out the biggest employer in terms of number of employees. */
WITH max_employment AS(SELECT comp_id, COUNT(per_id) AS employment
					   FROM works NATURAL JOIN position
					   GROUP BY comp_id)
SELECT comp_id, employment
FROM max_employment
WHERE employment = (SELECT MAX(employment) 
					FROM max_employment)

/* 5.2. Find out the biggest industry in terms of number of employees */
WITH max_employment AS(SELECT ind_title, COUNT(per_id) AS employment
					   FROM works NATURAL JOIN position NATURAL JOIN industry_company NATURAL JOIN gics
					   GROUP BY ind_title)
SELECT ind_title, employment
FROM max_employment
WHERE employment = (SELECT MAX(employment)
					FROM max_employment)

/* 5.3. Find out the biggest industry group in terms of number of employees */
WITH max_employment AS(SELECT ind_title, COUNT(per_id) AS employment
					   FROM works NATURAL JOIN position NATURAL JOIN industry_group NATURAL JOIN gics
					   GROUP BY ind_title)
SELECT ind_title, employment
FROM max_employment
WHERE employment = (SELECT MAX(employment)
					FROM max_employment)

/* 6. Find out the job distribution among industries by showing the number of employees in each industry. */
SELECT ind_id, ind_title, COUNT(per_id)
FROM gics NATURAL JOIN industry_company NATURAL JOIN position NATURAL JOIN works
WHERE hierarchy = 'industry'
GROUP BY ind_id, ind_title
ORDER BY COUNT(per_id) DESC

/* 7. Given a person's identifier, find all the job positions this person is currently holding and worked in the past. */
SELECT ALL pos_code, title
FROM works NATURAL JOIN position NATURAL JOIN person
WHERE per_id = ?

/* 8. Given a person's identifier, list this person's knowledge/skills in a readable format. */
SELECT title, ks_code, experience
FROM has_skill NATURAL JOIN knowledge_skill
WHERE per_id = ?

/* 9. Given a person's identifier, show the distribution of his/her skills by listing the number of skills in each of the cc_codes in Table A. */
SELECT COUNT(ks_code), cc_code, title
FROM has_skill NATURAL JOIN knowledge_skill
WHERE per_id = ?
GROUP BY cc_code, title

/* 10. List the required knowledge/skills of a given pos_code in a readable format. */
SELECT title, ks_code
FROM requires NATURAL JOIN knowledge_skill
WHERE pos_code = ?

/* 11. List the required skill categories of a given job category code in a readable format. */
SELECT work_function, cc_code, func_code
FROM skill_category NATURAL JOIN core_skill
WHERE job_cate = ?

/* 12. Given a person's identifier, list a person's missing knowledge/skills for a specific pos_code in a readable format. */
WITH miss_skill AS (SELECT ks_code
					FROM requires 
					WHERE pos_code = ?
					MINUS
					SELECT ks_code
					FROM has_skill
					WHERE per_id = ?)
SELECT ks_code, title, description
FROM miss_skill NATURAL JOIN knowledge_skill

/* 13. Given a person's identifier and a pos_code, list the courses (course id and title) that each alone teaches all the missing knowledge skills for this person to be qualified for the specified job position. */
WITH miss_skill AS (SELECT ks_code
					FROM requires
					WHERE pos_code = ?
					MINUS
					SELECT ks_code
					FROM has_skill
					WHERE per_id = ?)
SELECT c_code, title
FROM miss_skill NATURAL JOIN teaches NATURAL JOIN course
GROUP BY c_code, title

/* 14. Suppose the skill gap of a worker and the requirement of a desired job position can be covered by one course. Find the cheapest course to make up one's skill gap by showing the course with the lowest minimum section price. */
WITH miss_skill AS (SELECT ks_code
					FROM requires
					WHERE pos_code = ?
					MINUS
					SELECT ks_code
					FROM has_skill
					WHERE per_id = ?),
course_to_take  AS (SELECT c_code, title, price
					FROM miss_skill NATURAL JOIN teaches NATURAL JOIN course
					GROUP BY c_code, title, price)
SELECT c_code, title, price
FROM course_to_take
WHERE price = (SELECT MIN(price)
			   FROM course_to_take)

/* 15. Given a person's identifier, find the job position with the highest pay rate for this person according to his/her skill possession. */
WITH qualified AS (SELECT DISTINCT pos_code 
				   FROM position
				   WHERE NOT EXISTS (SELECT ks_code
									 FROM requires 
									 WHERE pos_code = position.pos_code
									 MINUS
									 SELECT ks_code
									 FROM has_skill
									 WHERE per_id = ?))
SELECT pos_code, pay_rate
FROM position
WHERE pay_rate = (SELECT MAX(pay_rate)
				  FROM position NATURAL JOIN qualified)

/* 16. Given a position code, list all the names along with the emails of the persons who are qualified for this position. */
WITH qualified AS (SELECT DISTINCT per_id
				   FROM person
				   WHERE NOT EXISTS (SELECT ks_code
									 FROM requires 
									 WHERE pos_code = ?
									 MINUS
									 SELECT ks_code
									 FROM has_skill
									 WHERE per_id = person.per_id))
SELECT name, email
FROM person NATURAL JOIN qualified

/* 17. When a company cannot find any qualified person for a job position, a secondary solution is to find a person who is almost qualified to the job position. Make a “missing-k” list that lists people who miss only k skills for a specified pos_code k < 4. */
WITH missing  AS (SELECT per_id, ks_code
				  FROM person, requires
				  WHERE pos_code = ?
				  MINUS
				  SELECT per_id, ks_code
				  FROM has_skill),
missing_count AS (SELECT per_id, COUNT(ks_code) AS misses
				  FROM missing
				  GROUP BY per_id)
SELECT per_id, name, misses
FROM missing_count NATURAL JOIN person
WHERE misses < 4

/* 18. Suppose there is a new position that has nobody qualified. List the persons who miss the least number of skills that are required by this pos_code and report the “least number”. */
WITH missing 	AS (SELECT per_id, ks_code
					FROM person, requires
					WHERE pos_code = ?
					MINUS
					SELECT per_id, ks_code
					FROM has_skill),
missing_count	AS (SELECT per_id, COUNT(ks_code) AS misses
					FROM missing
					GROUP BY per_id)
SELECT per_id, name, misses
FROM  missing_count NATURAL JOIN person
WHERE misses = (SELECT MIN(misses)
				FROM missing_count)

/* 19. List each of the skill code and the number of people who misses the skill and are in the missing-k list for a given position code in the ascending order of the people counts. */
WITH missing	AS (SELECT per_id, ks_code
					FROM person, requires
					WHERE pos_code = ?
					MINUS
					SELECT per_id, ks_code
					FROM has_skill),
missing_count	AS (SELECT per_id, COUNT(ks_code) AS misses
					FROM missing
					GROUP BY per_id),
missing_k 		AS (SELECT per_id, name
					FROM missing_count NATURAL JOIN person
					WHERE misses < 4)
SELECT ks_code, COUNT(per_id) AS lacking_ks_code
FROM missing_k NATURAL JOIN missing
GROUP BY ks_code
ORDER BY lacking_ks_code ASC

/* 20. In a local or national crisis, we need to find all the people who once held a job position of the special job category identifier. List per_id, name, job position title and the years the person worked (starting year and ending year). */
SELECT per_id, name, position.title, start_date, end_date
FROM works NATURAL JOIN position NATURAL JOIN person
WHERE job_cate = ?

/* 21.1. Find out the number of the workers whose earnings increased. */
WITH earnings 	AS (SELECT pos_code, pay
					FROM (SELECT comp_id, pos_code, (pay_rate) * 1920 AS pay
						  FROM position
						  WHERE pay_type = 'wage'
						  UNION
						  SELECT comp_id, pos_code, pay_rate AS pay
						  FROM position
						  WHERE pay_type = 'salary')),
last_job 		AS (SELECT per_id, MAX(end_date) AS last_end
					FROM works
					GROUP BY per_id),
last_pay 		AS (SELECT per_id, pay
					FROM last_job NATURAL JOIN earnings NATURAL JOIN works
					WHERE last_end = works.end_date),
current_pay 	AS (SELECT per_id, SUM(pay) AS income
					FROM works NATURAL JOIN earnings
					WHERE end_date IS NULL
					GROUP BY per_id)
SELECT COUNT(per_id)
FROM last_pay NATURAL JOIN current_pay
WHERE income > pay

/* 21.2. Find out the number of the workers whose earnings decreased. */
WITH earnings 	AS (SELECT pos_code, pay
					FROM (SELECT comp_id, pos_code, (pay_rate) * 1920 AS pay
						  FROM position
						  WHERE pay_type = 'wage'
						  UNION
						  SELECT comp_id, pos_code, pay_rate AS pay
						  FROM position
						  WHERE pay_type = 'salary')),
last_job 		AS (SELECT per_id, MAX(end_date) AS last_end
					FROM works
					GROUP BY per_id),
last_pay 		AS (SELECT per_id, pay
					FROM last_job NATURAL JOIN earnings NATURAL JOIN works
					WHERE last_end = works.end_date),
current_pay 	AS (SELECT per_id, SUM(pay) AS income
					FROM works NATURAL JOIN earnings
					WHERE end_date IS NULL
					GROUP BY per_id)
SELECT COUNT(per_id)
FROM last_pay NATURAL JOIN current_pay
WHERE income < pay

/* 21.3. Find out the ratio of workers whose earnings increased to the workers whose earnings decreased. */
WITH earnings 	AS (SELECT pos_code, pay
					FROM (SELECT comp_id, pos_code, (pay_rate) * 1920 AS pay
						  FROM position
						  WHERE pay_type = 'wage'
						  UNION
						  SELECT comp_id, pos_code, pay_rate AS pay
						  FROM position
						  WHERE pay_type = 'salary')),
last_job 		AS (SELECT per_id, MAX(end_date) AS last_end
					FROM works
					GROUP BY per_id),
last_pay 		AS (SELECT per_id, pay
					FROM last_job NATURAL JOIN earnings NATURAL JOIN works
					WHERE last_end = works.end_date),
current_pay 	AS (SELECT per_id, SUM(pay) AS income
					FROM works NATURAL JOIN earnings
					WHERE end_date IS NULL
					GROUP BY per_id),
earner_inc		AS (SELECT COUNT(per_id) AS earn_more
					FROM last_pay NATURAL JOIN current_pay
					WHERE income > pay),
earner_dec		AS (SELECT COUNT(per_id) AS earn_less
					FROM last_pay NATURAL JOIN current_pay
					WHERE income < pay)
SELECT earn_more/earn_less
FROM earner_inc, earner_dec

/* 21.4. Find out the the average earning changing rate of the workers in a specific industry group. */
WITH earnings 	AS (SELECT pos_code, pay
					FROM (SELECT comp_id, pos_code, (pay_rate) * 1920 AS pay
						  FROM position
						  WHERE pay_type = 'wage'
						  UNION
						  SELECT comp_id, pos_code, pay_rate AS pay
						  FROM position
						  WHERE pay_type = 'salary')),
last_job 		AS (SELECT per_id, MAX(end_date) AS last_end
					FROM works
					GROUP BY per_id),
last_pay 		AS (SELECT per_id, pay
					FROM last_job NATURAL JOIN earnings NATURAL JOIN works
					WHERE last_end = works.end_date),
current_pay 	AS (SELECT per_id, SUM(pay) AS income
					FROM works NATURAL JOIN earnings
					WHERE end_date IS NULL
					GROUP BY per_id),
earning_diff  AS (SELECT per_id, (income - pay) AS difference
				  FROM current_pay NATURAL JOIN last_pay NATURAL JOIN company
				  WHERE ind_id = ?)
SELECT AVG(difference)
FROM earning_diff

/* 22. Find all the unemployed people who once held a job position of the given pos_code. */
WITH current_job (per_id) AS (SELECT per_id
							  FROM works
							  WHERE end_date IS NULL),
list_unemployed (per_id)  AS (SELECT per_id
							  FROM (SELECT per_id
									FROM person
									MINUS
									SELECT per_id
									FROM current_job))
SELECT DISTINCT per_id, name
FROM person NATURAL JOIN works NATURAL JOIN list_unemployed
WHERE pos_code = ?
GROUP BY per_id, name

/* 23. Find the leaf-node job categories that have the most openings due to lack of qualified workers. */
WITH leaf 		AS (SELECT job_cate
		    		FROM job_category
		    		MINUS
		    		SELECT parent_cate
		    		FROM job_category),
employed 		AS (SELECT per_id, pos_code
		    		FROM works
		    		WHERE end_date IS NULL),
vac_position 	AS (SELECT pos_code
		    		FROM position
		    		MINUS
		    		SELECT pos_code
		    		FROM employed),
vp_of_leaf_cnt	 AS (SELECT job_cate, COUNT(pos_code) as pos_count 
		    		FROM vac_position NATURAL JOIN leaf NATURAL JOIN position
		    		GROUP BY job_cate
		    		ORDER BY job_cate),
vp_of_leaf 	AS (SELECT job_cate, pos_code 
		    	FROM vac_position NATURAL JOIN leaf NATURAL JOIN position
		    	ORDER BY job_cate),
unemployed 	AS (SELECT per_id 
		    	FROM (SELECT per_id
					  FROM person
					  MINUS
					  SELECT per_id
					  FROM employed)), 
qual 		AS (SELECT job_cate, pos_code, per_id
		    	FROM unemployed, vp_of_leaf
		    	WHERE NOT EXISTS (SELECT ks_code
								  FROM requires
								  WHERE pos_code = vp_of_leaf.pos_code
								  MINUS
								  SELECT ks_code
								  FROM has_skill
								  WHERE per_id = unemployed.per_id)),
people_qual 	AS (SELECT job_cate, pos_code, COUNT(per_id) AS per_count 
					FROM qual
					GROUP BY job_cate, pos_code)
SELECT DISTINCT (job_cate), pos_count-per_count AS difference
FROM vp_of_leaf_cnt NATURAL JOIN people_qual

/* 24. If query #13 returns nothing, find the course sets that their combination covers all the missing knowledge/skills for a person to pursue a pos_code. The considered course sets will not include more than three courses. If multiple course sets are found, list the course sets (with their course IDs) in the order of the ascending order of the course sets' total costs. */
CREATE SEQUENCE CourseSet_seq 
START WITH 1
INCREMENT BY 1
MAXVALUE 999999
NOCYCLE

CREATE OR REPLACE TABLE CourseSet (
csetID NUMBER(8, 0) PRIMARY KEY,
c_code1 NUMBER(6, 0),
c_code2 NUMBER(6, 0),
c_code3 NUMBER(6, 0),
csetsize NUMBER(2, 0))

INSERT INTO CourseSet
SELECT CourseSet_seq.NEXTVAL, C1.c_code, C2.c_code, null, 2
FROM Course C1, Course C2
WHERE C1.c_code < C2.code

INSERT INTO CourseSet
SELECT CourseSet_seq.NEXTVAL, C1.c_code, C2.c_code, C3.c_code, 3
FROM Course C1, Course C2, Course C3
WHERE C1.c_code < C2.code AND C2.code < C3.code

CREATE OR REPLACE TABLE CourseSet_Skill (
csetID NUMBER(8, 0) PRIMARY KEY,
ks_code VARCHAR(8) )

INSERT INTO CourseSet_Skill (csetID, ks_code)
SELECT csetID, ks_code
FROM CourseSet CSet JOIN Course_Skill CS ON CSet.c_code1=CS.c_code
UNION
SELECT csetID, ks_code
FROM CourseSet CSet JOIN Course_Skill CS ON CSet.c_code2=CS.c_code
UNION
SELECT csetID, ks_code
FROM CourseSet CSet JOIN Course_Skill CS ON CSet.c_code3=CS.c_code

WITH missing_skill 		 AS (SELECT ks_code
			   				 FROM requires
			   				 WHERE pos_code = ?
			   				 MINUS
			   				 SELECT ks_code
			   				 FROM has_skill
			   				 WHERE per_id = ?),
Cover_CSet(csetID, size) AS (SELECT csetID, size
							 FROM CourseSet CSet
							 WHERE NOT EXISTS (SELECT ks_code
  					    					   FROM missing_skill
    										   MINUS
    										   SELECT ks_code
    										   FROM CourseSet_Skill CSSk
   					    					   WHERE CSSk.csetID = Cset.csetID)),
set_price				 AS (SELECT csetID, (SELECT (price)
							 				 FROM course C
							 				 WHERE C.c_code = C1.c_code),
											(SELECT (price)
											 FROM course C
											 WHERE C.c_code = C2.c_code),
											(SELECT (price)
											 FROM course C
											 WHERE C.c_code = C3.c_code)
							 FROM CourseSet NATURAL JOIN Cover_CSet)
SELECT c_code1, c_code2, c_code3
FROM Cover_CSet NATURAL JOIN CourseSet
WHERE csetsize = (SELECT MIN(SIZE)
				  FROM Cover_CSet)

/* 25. Find the course sets that teach every skill required by the job positions of the job categories found in Query #23. These courses should effectively help most jobless people become qualified for the jobs with high demands. */
WITH leaf 		AS (SELECT job_cate
		    		FROM job_category
		    		MINUS
		    		SELECT parent_cate
		    		FROM job_category),
employed 		AS (SELECT per_id, pos_code
		    		FROM works
		    		WHERE end_date IS NULL),
vac_position 	AS (SELECT pos_code
		    		FROM position
		    		MINUS
		    		SELECT pos_code
		    		FROM employed),
vp_of_leaf_cnt	 AS (SELECT job_cate, COUNT(pos_code) as pos_count 
		    		FROM vac_position NATURAL JOIN leaf NATURAL JOIN position
		    		GROUP BY job_cate
		    		ORDER BY job_cate),
vp_of_leaf 	AS (SELECT job_cate, pos_code 
		    	FROM vac_position NATURAL JOIN leaf NATURAL JOIN position
		    	ORDER BY job_cate),
unemployed 	AS (SELECT per_id 
		    	FROM (SELECT per_id
					  FROM person
					  MINUS
					  SELECT per_id
					  FROM employed)), 
qual 		AS (SELECT job_cate, pos_code, per_id
		    	FROM unemployed, vp_of_leaf
		    	WHERE NOT EXISTS (SELECT ks_code
								  FROM requires
								  WHERE pos_code = vp_of_leaf.pos_code
								  MINUS
								  SELECT ks_code
								  FROM has_skill
								  WHERE per_id = unemployed.per_id)),
people_qual 	AS (SELECT job_cate, pos_code, COUNT(per_id) AS per_count 
					FROM qual
					GROUP BY job_cate, pos_code),
final	 		AS (SELECT DISTINCT (job_cate), pos_count-per_count AS difference
					FROM vp_of_leaf_cnt NATURAL JOIN people_qual)
missing_skill 	AS (SELECT ks_code
			   		FROM requires
			   		WHERE pos_code = 
			   		MINUS
			   		SELECT ks_code
			   		FROM unemp
			   		WHERE per_id = ),
Cover_CSet(csetID, size) AS (SELECT csetID
							 FROM CourseSet CSet
							 WHERE NOT EXISTS (SELECT ks_code
  					    					   FROM missing_skill
    										   MINUS
    										   SELECT ks_code
    										   FROM CourseSet_Skill CSSk
   					    					   WHERE CSSk.csetID = Cset.csetID))
SELECT c_code1, c_code2, c_code3
FROM Cover_CSet NATURAL JOIN CourseSet
WHERE csetsize = (SELECT MIN(SIZE)
				  FROM Cover_CSet)