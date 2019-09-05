-- FUNCTION: fintrack.collectoverallperformance(integer)

-- DROP FUNCTION fintrack.collectoverallperformance(integer);

CREATE OR REPLACE FUNCTION fintrack.collectoverallperformance(
	inuserid integer)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

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
  Created:         01.Feb.2019 - DanielC - 13036
  Description:     Component performance report
  Parameters:      inuserid - the user who required the report                   
  Returns:         n/a
  Used:            FinTP/BASE/RE
***********************************************/

v_timenow         timestamp without time zone;
area              character varying;
v_processingtime  integer;
v_nooftrx         integer;
v_idletime        integer;
v_procrate        numeric(8,2);
v_nooferrevents   integer;
v_noofmngevents   integer;
v_intervals       text default '';
v_prechour        text;
v_precnosec       double precision;
xdate             fintrack.date_secno_pair;

BEGIN

	v_timenow := current_timestamp::timestamp(0);
    
    for area in select distinct(findata.getbusinessareabyid(correlationid)) as businessareas from findata.status where insertdate::date = v_timenow::date
    loop
    	if (area is not null) then
        	-- calculate processingtime and the total number or processed messages
            select count(distinct(date_part('second', insertdate))), count(distinct(correlationid))
            into  v_processingtime, v_nooftrx 
            from findata.status 
            where trim(type) = 'Info' and insertdate::date = v_timenow::date and service != -1 and findata.getbusinessareabyid(correlationid) = area;
            
            
            
            -- calculate idletime and processing rate
            v_idletime := 24 * 60 * 60 - v_processingtime;
            if (v_nooftrx = 0) then
                v_procrate := 0;
            else
                v_procrate := (v_nooftrx::numeric) / (v_processingtime::numeric);
            end if;

        	-- calculate number of events for Error/Management
            select coalesce(sum(case when trim(type) = 'Error' or trim(type) = 'Warning'  then 1 else 0 end), 0),
               	   coalesce(sum(case when trim(type) = 'Management' then 1 else 0 end), 0)
            into v_nooferrevents, v_noofmngevents
            from findata.status
            where insertdate::date = v_timenow::date and service != -1 and findata.getbusinessareabyid(correlationid) = area;
            
 			--calculate intervals
        	v_intervals := '';
        	v_precnosec := 0;
        	v_prechour := '';

        	for xdate in select substring(cast(insertdate as character varying), 12, 8) as insdate,
	   							 extract(hour from insertdate)*60*60 + extract(minute from insertdate)*60 + trunc(extract(second from insertdate)) as conv
								 from findata.status
                                 where insertdate::date = v_timenow::date and service != -1  and findata.getbusinessareabyid(correlationid) = area and trim(type) = 'Info'
                                 order by conv           
            loop
                if (xdate.conv - v_precnosec > 1) then
                    if (v_precnosec = 0) then
                        v_intervals := v_intervals || xdate.insdate || '-';
                    else
                        v_intervals := v_intervals || v_prechour || '; ';
                        v_intervals := v_intervals || xdate.insdate || '-';
                    end if;
                end if;  

                v_prechour := xdate.insdate;
                v_precnosec := xdate.conv;
            end loop;
            
            v_intervals := v_intervals || v_prechour || '; ';
       
          	-- insert results
          	insert into fintrack.overallperformance
          	values (v_timenow::date, to_char(v_timenow::time, 'HH24:MI:SS'), area, v_idletime, v_processingtime, v_procrate, v_nooftrx, v_nooferrevents, v_noofmngevents, v_intervals, inuserid);
        
        end if; 
    end loop;
    
    -- stop trace
    v_idletime := fintrack.stoptrace(inuserid);
    
    RETURN to_char(v_timenow, 'YYYY-MM-DD HH24:MI:SS');

EXCEPTION
WHEN OTHERS THEN
   RAISE EXCEPTION 'Unexpected error occured while configuring queue: %', SQLERRM;
END;

$BODY$;

ALTER FUNCTION fintrack.collectoverallperformance(integer)
    OWNER TO fintrack;

