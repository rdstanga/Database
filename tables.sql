CREATE TABLE person (
per_id VARCHAR(8),
name VARCHAR(30) NOT NULL,
email VARCHAR(30),
gender VARCHAR(6),
phone VARCHAR(10),
PRIMARY KEY (per_id)
);

CREATE TABLE address (
zip_code NUMERIC(5),
city VARCHAR(25),
state VARCHAR(18),
street_name VARCHAR(25),
street_num VARCHAR(4),
apt_num VARCHAR(3),
PRIMARY KEY (zip_code)
);

CREATE TABLE knowledge_skill (
ks_code VARCHAR(20) NOT NULL,
cc_code VARCHAR(6),
func_code VARCHAR(1),
title VARCHAR(50),
description VARCHAR(150),
experience VARCHAR(8),
PRIMARY KEY (ks_code)
);

CREATE TABLE company (
comp_id VARCHAR(10) NOT NULL,
ind_id VARCHAR(20),
website VARCHAR(40),
PRIMARY KEY (comp_id)
);

CREATE TABLE course (
c_code VARCHAR(4) NOT NULL,
title VARCHAR(50),
description VARCHAR(150),
status VARCHAR(7),
price NUMERIC(3),
PRIMARY KEY (c_code)
);

CREATE TABLE gics (
ind_id NUMERIC(8),
ind_title VARCHAR(50),
hierarchy VARCHAR(14),
description VARCHAR(500),
parent_id NUMERIC(8),
PRIMARY KEY (ind_id)
);

CREATE TABLE job_category (
job_cate VARCHAR(25),
title VARCHAR(50),
description VARCHAR(100),
pay_range_high NUMERIC(6),
pay_range_low NUMERIC(5),
parent_cate VARCHAR(25),
PRIMARY KEY (job_cate)
);

CREATE TABLE position (
pos_code VARCHAR(10),
title VARCHAR(40),
emp_mode VARCHAR(9),
pay_rate NUMERIC(8),
pay_type VARCHAR(6),
job_cate VARCHAR(25),
comp_id VARCHAR(10),
PRIMARY KEY (pos_code)
);

CREATE TABLE skill_category (
cc_code VARCHAR(6) NOT NULL,
func_code CHAR(1),
work_function VARCHAR(100),
active CHAR(1),
PRIMARY KEY (cc_code, func_code)
);

CREATE TABLE belongs_to (
ind_id NUMERIC(8),
parent_id NUMERIC(8),
PRIMARY KEY (ind_id, parent_id),
FOREIGN KEY (ind_id) REFERENCES gics,
FOREIGN KEY (parent_id) REFERENCES gics
);

CREATE TABLE career_cluster (			
cc_code VARCHAR(6),
func_code CHAR(1),
title VARCHAR(100),
PRIMARY KEY (cc_code, func_code, title),
FOREIGN KEY (cc_code, func_code) REFERENCES skill_category 
);

CREATE TABLE company_address (
comp_id VARCHAR(10),
street_num VARCHAR(4),
street_name VARCHAR(25),
apt_num VARCHAR(3),
city VARCHAR(25),
zip_code NUMERIC(5),
PRIMARY KEY (comp_id, zip_code),
FOREIGN KEY (comp_id) REFERENCES company
);

CREATE TABLE comp_pos (
pos_code VARCHAR(10),
comp_id VARCHAR(10),
PRIMARY KEY (pos_code, comp_id),
FOREIGN KEY (pos_code) REFERENCES position,
FOREIGN KEY (comp_id) REFERENCES company
);

CREATE TABLE core_skill (	
job_cate VARCHAR(25),	
cc_code VARCHAR(6),
func_code CHAR(1),
PRIMARY KEY (job_cate, cc_code, func_code),
FOREIGN KEY (job_cate) REFERENCES job_category,
FOREIGN KEY (cc_code, func_code) REFERENCES skill_category
);

CREATE TABLE develops (		
ks_code VARCHAR(20),
cc_code VARCHAR(6),
func_code CHAR(1),
PRIMARY KEY (ks_code, cc_code, func_code),
FOREIGN KEY (ks_code) REFERENCES knowledge_skill,
FOREIGN KEY (cc_code, func_code) REFERENCES skill_category
);

CREATE TABLE has_skill (
per_id VARCHAR(8),
ks_code VARCHAR(20),
FOREIGN KEY (per_id) REFERENCES person,
FOREIGN KEY (ks_code) REFERENCES knowledge_skill
);

CREATE TABLE industry_company (
ind_id NUMERIC(8),
comp_id VARCHAR(10),
PRIMARY KEY (ind_id, comp_id),
FOREIGN KEY (ind_id) REFERENCES gics,
FOREIGN KEY (comp_id) REFERENCES company
);

CREATE TABLE industry_group (
ind_id NUMERIC(8),
comp_id VARCHAR(10),
PRIMARY KEY (ind_id, comp_id),
FOREIGN KEY (ind_id) REFERENCES gics,
FOREIGN KEY (comp_id) REFERENCES company
);

CREATE TABLE job_pos (
pos_code VARCHAR(10),
job_cate VARCHAR(25),
PRIMARY KEY (pos_code, job_cate),
FOREIGN KEY (pos_code) REFERENCES position,
FOREIGN KEY (job_cate) REFERENCES job_category
);

CREATE TABLE person_address (
per_id VARCHAR(8),
street_num VARCHAR(4),
street_name VARCHAR(25),
apt_num VARCHAR(3),
city VARCHAR(25),
zip_code NUMERIC(5),
PRIMARY KEY (per_id, zip_code),
FOREIGN KEY (zip_code) REFERENCES address,
FOREIGN KEY (per_id) REFERENCES person
);

CREATE TABLE prerequisite (
c_code VARCHAR(4),
required_code VARCHAR(4),
PRIMARY KEY (c_code, required_code),
FOREIGN KEY (c_code) REFERENCES course 
);

CREATE TABLE requires(
pos_code VARCHAR(10),
ks_code VARCHAR(20),
prefer VARCHAR(3),
PRIMARY KEY (pos_code, ks_code),
FOREIGN KEY (pos_code) REFERENCES position,
FOREIGN KEY (ks_code) REFERENCES knowledge_skill
);

CREATE TABLE section (
c_code VARCHAR(4),
sec_no VARCHAR(6),
year NUMERIC(4),
complete_date DATE,
offered_by VARCHAR(40),
format VARCHAR(16),
price NUMERIC(3),
PRIMARY KEY (c_code, sec_no),
FOREIGN KEY (c_code) REFERENCES course
);

CREATE TABLE takes (
per_id VARCHAR(8),
c_code VARCHAR(4),
sec_no VARCHAR(6),
complete_date DATE,
PRIMARY KEY (per_id, c_code, sec_no),
FOREIGN KEY (per_id) REFERENCES person,
FOREIGN KEY (c_code, sec_no) REFERENCES section
);

CREATE TABLE teaches (
c_code VARCHAR(4),
ks_code VARCHAR(20),
PRIMARY KEY (c_code, ks_code),
FOREIGN KEY (c_code) REFERENCES course,
FOREIGN KEY (ks_code) REFERENCES knowledge_skill
);

CREATE TABLE works (
per_id VARCHAR(8),
pos_code VARCHAR(10),
start_date DATE,
end_date DATE,
PRIMARY KEY (per_id, pos_code),
FOREIGN KEY (per_id) REFERENCES person,
FOREIGN KEY (pos_code) REFERENCES position
);

CREATE TABLE emp_table (
per_id VARCHAR(8),
c_code VARCHAR(4),
sec_no VARCHAR(6),
complete_date DATE,
PRIMARY KEY (per_id, c_code, sec_no),
FOREIGN KEY (per_id) REFERENCES person,
FOREIGN KEY (c_code, sec_no) REFERENCES section
);


COMMIT;
