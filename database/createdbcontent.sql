echo Creating database objects...

--fintrack schema

\echo fintrack:tables

\i fincfg/tables/queueactions.sql
\i fincfg/tables/tracestatus.sql
\i fincfg/tables/routingschemaanalysis.sql
\i fincfg/tables/routingjobstmpstop.sql
\i fincfg/tables/routingjobstmpstart.sql
\i fincfg/tables/routingjobsstmint.sql
\i fincfg/tables/overallperformance.sql
\i fincfg/tables/liveperformance.sql
\i fincfg/tables/componentperformance.sql



\echo fintrack:functions

\i fincfg/functions/stoptrace.sql
\i fincfg/functions/starttrace.sql
\i fincfg/functions/collectrsdata.sql
\i fincfg/functions/collectrjliveperformance.sql
\i fincfg/functions/collectoverallperformance.sql
\i fincfg/functions/collectcomponentperformance.sql