-- Table: fintrack.overallperformance

-- DROP TABLE fintrack.overallperformance;

CREATE TABLE fintrack.overallperformance
(
    reportdate date,
    timestamps character varying(50) COLLATE pg_catalog."default",
    businessarea character varying(100) COLLATE pg_catalog."default",
    idletime integer,
    processingtime integer,
    processingrate numeric,
    nooftrx integer,
    nooferrorevents integer,
    noofmanagementevents integer,
    processingtimeintervals text COLLATE pg_catalog."default",
    userid integer,
    id integer NOT NULL DEFAULT nextval('fintrack.liveperformance_id_seq'::regclass),
    CONSTRAINT overallperformance_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE fintrack.overallperformance
    OWNER to fintrack;

GRANT ALL ON TABLE fintrack.overallperformance TO fintrack;

GRANT ALL ON TABLE fintrack.overallperformance TO finuiuser;