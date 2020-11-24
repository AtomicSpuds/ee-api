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
    volume numeric(15,2),
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
-- Name: ee_api_tagem; Type: TABLE; Schema: public; Owner: ee_api
--

CREATE TABLE public.ee_api_tagem (
    id integer NOT NULL,
    tagid integer,
    nameid bigint,
    created timestamp with time zone DEFAULT now()
);


ALTER TABLE public.ee_api_tagem OWNER TO ee_api;

--
-- Name: ee_api_tagem_id_seq; Type: SEQUENCE; Schema: public; Owner: ee_api
--

CREATE SEQUENCE public.ee_api_tagem_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ee_api_tagem_id_seq OWNER TO ee_api;

--
-- Name: ee_api_tagem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ee_api
--

ALTER SEQUENCE public.ee_api_tagem_id_seq OWNED BY public.ee_api_tagem.id;


--
-- Name: ee_api_tags; Type: TABLE; Schema: public; Owner: ee_api
--

CREATE TABLE public.ee_api_tags (
    id integer NOT NULL,
    tag text,
    created timestamp with time zone DEFAULT now()
);


ALTER TABLE public.ee_api_tags OWNER TO ee_api;

--
-- Name: ee_api_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: ee_api
--

CREATE SEQUENCE public.ee_api_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ee_api_tags_id_seq OWNER TO ee_api;

--
-- Name: ee_api_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ee_api
--

ALTER SEQUENCE public.ee_api_tags_id_seq OWNED BY public.ee_api_tags.id;


--
-- Name: ee_api_urlstatus; Type: TABLE; Schema: public; Owner: ee_api
--

CREATE TABLE public.ee_api_urlstatus (
    id integer NOT NULL,
    url text,
    contlen integer,
    conttype text,
    expires timestamp without time zone,
    lastmod timestamp with time zone,
    expectct text,
    created timestamp with time zone DEFAULT now()
);


ALTER TABLE public.ee_api_urlstatus OWNER TO ee_api;

--
-- Name: ee_api_urlstatus_id_seq; Type: SEQUENCE; Schema: public; Owner: ee_api
--

CREATE SEQUENCE public.ee_api_urlstatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ee_api_urlstatus_id_seq OWNER TO ee_api;

--
-- Name: ee_api_urlstatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ee_api
--

ALTER SEQUENCE public.ee_api_urlstatus_id_seq OWNED BY public.ee_api_urlstatus.id;


--
-- Name: ee_api_tagem id; Type: DEFAULT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_tagem ALTER COLUMN id SET DEFAULT nextval('public.ee_api_tagem_id_seq'::regclass);


--
-- Name: ee_api_tags id; Type: DEFAULT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_tags ALTER COLUMN id SET DEFAULT nextval('public.ee_api_tags_id_seq'::regclass);


--
-- Name: ee_api_urlstatus id; Type: DEFAULT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_urlstatus ALTER COLUMN id SET DEFAULT nextval('public.ee_api_urlstatus_id_seq'::regclass);


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
-- Name: ee_api_tagem ee_api_tagem_id_key; Type: CONSTRAINT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_tagem
    ADD CONSTRAINT ee_api_tagem_id_key UNIQUE (id);


--
-- Name: ee_api_tags ee_api_tags_id_key; Type: CONSTRAINT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_tags
    ADD CONSTRAINT ee_api_tags_id_key UNIQUE (id);


--
-- Name: ee_api_urlstatus ee_api_urlstatus_id_key; Type: CONSTRAINT; Schema: public; Owner: ee_api
--

ALTER TABLE ONLY public.ee_api_urlstatus
    ADD CONSTRAINT ee_api_urlstatus_id_key UNIQUE (id);


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
-- Name: ee_api_tagem_nameid; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_tagem_nameid ON public.ee_api_tagem USING btree (nameid);


--
-- Name: ee_api_tagem_tagid; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_tagem_tagid ON public.ee_api_tagem USING btree (tagid);


--
-- Name: ee_api_tags_tag; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_tags_tag ON public.ee_api_tags USING btree (tag);


--
-- Name: ee_api_url_url; Type: INDEX; Schema: public; Owner: ee_api
--

CREATE INDEX ee_api_url_url ON public.ee_api_urlstatus USING btree (url);


--
-- PostgreSQL database dump complete
--

