--Function: fintrack.collectrjliveperformance(intime integer, inuserid integer)

--DROP FUNCTION fintrack.collectrjliveperformance(intime integer, inuserid integer);

CREATE OR REPLACE FUNCTION fintrack.collectrjliveperformance
(
  IN  intime    integer,
  IN  inuserid  integer
)
RETURNS integer AS
$$
DECLARE

/*
* FinTP - Financial Transactions Processing Application
* Copyright (C) 2013 Business Information Systems (Allevo) S.R.L.
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>
* or contact Allevo at : 031281 Bucuresti, 23C Calea Vitan, Romania,
* phone +40212554577, office@allevo.ro <office@allevo.ro>, www.allevo.ro.
*/
/************************************************
  Change history:  
  Created:         04.Oct.2018, DanielC  - 13037
  Description:     Live performance report
  Parameters:      intime - the given number of seconds (<= 60)                    
  Returns:         inuserid - the user who required the report
  Used:            FinTP/BASE/RE
***********************************************/

	v_initnojobs integer;
    v_finnojobs integer;
    v_procnojobs integer;
    v_joblistinit text default '';
    v_joblistfin text default '';
    v_joblistproc text default '';
    v_starttime text;
    v_stoptime text;
    v_timeinterval character varying default '';
    v_aux integer;
    v_queues character varying;
    v_jobsbypr integer;
    v_noerr integer;
    

BEGIN
    
    delete from fintrack.routingjobstmpstart;
    delete from fintrack.routingjobstmpstop;
    delete from fintrack.routingjobsstmint;

    select substring(timeofday() from 11 for 9) into v_starttime;
    
	-- copy in start RJ and enable trigger
    insert into fintrack.routingjobstmpstart select * from findata.routingjobs;
    
    --wait given time
    PERFORM pg_sleep(intime);
    
    -- call stop
    v_aux := fintrack.stoptrace(inuserid);
    select substring(timeofday() from 11 for 9) into v_stoptime;
    alter table findata.routingjobs disable trigger trackerwatcher;
    
    -- copy in stop RJ and disable trigger
    insert into fintrack.routingjobstmpstop select * from findata.routingjobs;
    
    v_timeinterval := v_starttime || ' - ' || v_stoptime;
    
    -- initial/final/processed number of jobs
    select count(*) into v_initnojobs from fintrack.routingjobstmpstart;
    select count(*) into v_finnojobs from fintrack.routingjobstmpstop;
    select count(*) into v_procnojobs from fintrack.routingjobsstmint;
    
    /* list of jobs from start */
    for v_aux in select distinct priority from fintrack.routingjobstmpstart group by priority
    loop
       v_joblistinit := v_joblistinit || 'Priority: '|| v_aux::text || ' - ';
       
       -- total jobs with this priority
       select count(*) into v_jobsbypr from fintrack.routingjobstmpstart where priority = v_aux;
       v_joblistinit := v_joblistinit || 'No of jobs: ' || v_jobsbypr::text || ' - Queues: [ ';
       
       -- list of queues for this priority
       for v_queues in select distinct routingpoint from fintrack.routingjobstmpstart where priority = v_aux group by routingpoint
       loop
       		v_joblistinit := v_joblistinit || v_queues || ' ';
       end loop;
       v_joblistinit := v_joblistinit || ']<br>';
    end loop;
    
    
    /* list of jobs from stop */
    for v_aux in select distinct priority from fintrack.routingjobstmpstop group by priority
    loop
       v_joblistfin := v_joblistfin || 'Priority: '|| v_aux::text || ' - ';
       
       -- total jobs with this priority
       select count(*) into v_jobsbypr from fintrack.routingjobstmpstop where priority = v_aux;
       v_joblistfin := v_joblistfin || 'No of jobs: ' || v_jobsbypr::text || ' - Queues: [ ';
       
       -- list of queues for this priority
       for v_queues in select distinct routingpoint from fintrack.routingjobstmpstop where priority = v_aux group by routingpoint
       loop
       		v_joblistfin := v_joblistfin || v_queues || ' ';
       end loop;
       v_joblistfin := v_joblistfin || ']<br>';
    end loop;
    
    
    /* list of processed jobs */
    for v_aux in select distinct priority from fintrack.routingjobsstmint group by priority
    loop
       v_joblistproc := v_joblistproc || 'Priority: '|| v_aux::text || ' - ';
       
       -- total jobs with this priority
       select count(*) into v_jobsbypr from fintrack.routingjobsstmint where priority = v_aux;
       v_joblistproc := v_joblistproc || 'No of jobs: ' || v_jobsbypr::text || ' - Queues: [ ';
       
       -- list of queues for this priority
       for v_queues in select distinct routingpoint from fintrack.routingjobsstmint where priority = v_aux group by routingpoint
       loop
       		v_joblistproc := v_joblistproc || v_queues || ' ';
       end loop;
       v_joblistproc := v_joblistproc || ']<br>';
    end loop;
       
    -- number of error events
    select count(*) into v_noerr from findata.status
    where service = 3 and type = 'Error';
    
    -- add data
    insert into fintrack.liveperformance
    values(current_date, v_timeinterval, v_initnojobs, v_finnojobs, v_procnojobs, v_joblistinit, v_joblistfin, v_joblistproc, v_noerr);
    
    select id into v_aux from fintrack.liveperformance where reportdate = current_date and timestampsinterval = v_timeinterval;
    
    RETURN v_aux;
    
EXCEPTION
WHEN OTHERS THEN
   RAISE EXCEPTION 'Unexpected error occured while configuring queue: %', SQLERRM;
END;
$$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION fintrack.collectrjliveperformance(intime integer, inuserid integer)
  OWNER TO fintrack;