-- Table: fintrack.componentperformance

-- DROP TABLE fintrack.componentperformance;

CREATE TABLE fintrack.componentperformance
(
    reportdate date,
    timestamps character varying(50) COLLATE pg_catalog."default",
    componentname character varying(100) COLLATE pg_catalog."default",
    componentthread character varying(50) COLLATE pg_catalog."default",
    componentcategory character varying(100) COLLATE pg_catalog."default",
    idletime integer,
    processingtime integer,
    processingrate numeric,
    noofevents integer,
    nooferrorevents integer,
    noofmanagementevents integer,
    processingtimeintervals text COLLATE pg_catalog."default",
    userid integer,
    id integer NOT NULL DEFAULT nextval('fintrack.liveperformance_id_seq'::regclass),
    CONSTRAINT componentperformance_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE fintrack.componentperformance
    OWNER to fintrack;

GRANT ALL ON TABLE fintrack.componentperformance TO fintrack;

GRANT ALL ON TABLE fintrack.componentperformance TO finuiuser;