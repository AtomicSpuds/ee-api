--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7
-- Dumped by pg_dump version 12.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

--
-- Name: ee_api_data; Type: TABLE; Schema: public; Owner: ee_api
--

CREATE TABLE public.ee_api_data (
    id bigint,
    tradetime timestamp without time zone,
    sell numeric(15,2),
    buy numeric(15,2),
    lowest_sell numeric(15,2),
    highest_buy numeric(15,2),
    entered timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ee_api_data OWNER TO ee_api;

--
-- Name: ee_api_names; Type: TABLE; Schema: public; Owner: ee_api
--

CREATE TABLE public.ee_api_names (
    id bigint,
    name character varying,
    created timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ee_api_names OWNER TO ee_api;

--
-- Name: ee_api_summary; Type: TABLE; Schema: public; Owner: ee_api
--

CREATE TABLE public.ee_api_summary (
    id bigint,
    tradetime timestamp without time zone,
    sell numeric(15,2),
    buy numeric(15,2),
    lowest_sell numeric(15,2),
    highest_buy numeric(15,2),
    created timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ee_api_summary OWNER TO ee_api;

--
-- Name: ee_api_data ee_api_data_id_key; Type: CONSTRAINT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_data
    ADD CONSTRAINT ee_api_data_id_key UNIQUE (id);


--
-- Name: ee_api_names ee_api_names_id_key; Type: CONSTRAINT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_names
    ADD CONSTRAINT ee_api_names_id_key UNIQUE (id);


--
-- Name: ee_api_summary ee_api_summary_id_key; Type: CONSTRAINT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_summary
    ADD CONSTRAINT ee_api_summary_id_key UNIQUE (id);


--
-- Name: ee_api_data_time; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_data_time ON public.ee_api_data USING btree (tradetime);


--
-- Name: ee_api_names_nameidx; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_names_nameidx ON public.ee_api_names USING btree (name);


--
-- Name: ee_api_summary_timeidx; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_summary_timeidx ON public.ee_api_summary USING btree (tradetime);


--
-- PostgreSQL database dump complete
--

