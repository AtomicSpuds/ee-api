--
-- Connect as admin
--

CREATE ROLE ee_api WITH NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
CREATE DATABASE ee WITH OWNER ee_api;
\password ee_api

--
-- ... connect as ee_api
--
CREATE TABLE ee_api_names (
	id int,
	name varchar,
	created timestamp without time zone default now()
);

-- one entry per id

CREATE TABLE ee_api_summary (
	id int,
	tradetime timestamp,
	sell numeric(15,2),
	buy numeric(15,2),
	lowest_sell numeric(15,2),
	highest_buy numeric(15,2),
	created timestamp without time zone default now()
);

-- many entryes of historic data per id

CREATE TABLE ee_api_data (
	id int,
	tradetime timestamp,
	sell numeric(15,2),
	buy numeric(15,2),
	lowest_sell numeric(15,2),
	highest_buy numeric(15,2),
	entered timestamp without time zone default now()
);
	
