--Function: fintrack.collectrsdata()

--DROP FUNCTION fintrack.collectrsdata();

CREATE OR REPLACE FUNCTION fintrack.collectrsdata()
RETURNS void AS
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
  Created:         05.Sep.2018, DanielC  - 13034
  Description:     Collects data for performance check
  Parameters:      n/a                    
  Returns:         n/a
  Used:            FinTP/BASE/RE
***********************************************/

	v_row					fincfg.routingschemas%rowtype;
    v_noroutingrules		integer;
	v_rmcount 				integer;
    v_actionslow 			integer;
    v_actionsmedium 		integer;
    v_wsdatacheck			integer;
    v_actionshigh			integer;
    v_validationslow		integer;
    v_validationsmedium 	integer;
    v_validationshigh		integer;
    v_serviceoptlow			integer;
    v_serviceoptmedium		integer;
    v_serviceopthigh		integer;
    v_update				character varying;
    v_details				character varying;

BEGIN

	-- counting all trx and completing it in details
	select count(*) into v_rmcount from findata.routedmessages;
    v_details := 'Live data routing messages count: ' || v_rmcount::text;
    
    truncate fintrack.routingschemaanalysis;
    
    for v_row in (select * from fincfg.routingschemas) loop
    
    	-- couting routing rules
    	select count(*) into v_noroutingrules from fincfg.routingrules
        where routingschemaid = v_row.id;
    
    /* Counting all Actions */
        
        -- low actions
    	select count(*) into v_actionslow from fincfg.routingrules
        where routingschemaid = v_row.id
        and (action in ('Aggregate', 'Complete') or action like 'SendReply%' or action like 'ChangeHoldStatus%' or action like 'MoveTo%');
        
        -- moderate actions and WSdata check
    	select count(*) into v_actionsmedium from fincfg.routingrules
        where routingschemaid = v_row.id
        and (action like 'Enrich%' or action like 'ChangeValueDate%' or action like 'TransformMessage%');
        
        select count(*) into v_wsdatacheck from fincfg.routingrules
        where routingschemaid = v_row.id
        and action like 'TransformMessage%WSdata%';
        
        if (v_wsdatacheck > 0) then
        	v_details := v_details || '; This Routing schema uses Web Service calls.';
        end if;
        
        -- high actions
    	v_actionshigh := 0;
        
    /* Counting all Validations */    
    
    	-- low validations
    	select count(*) into v_validationslow from fincfg.routingrules
        where routingschemaid = v_row.id
        and ((messagecondition is not null and messagecondition != '') or (functioncondition in ('isAck()', 'isNack()', 'IsReply()')));
        
        -- moderate validations
    	select count(*) into v_validationsmedium from fincfg.routingrules
        where routingschemaid = v_row.id
        and (functioncondition like 'Validate%');
        
        -- high validations
        v_validationshigh := 0;
    
    /* Counting all Services */ 
    	
        -- low services
    	select count(x.*) into v_serviceoptlow 
        from 
        	(select rr.routingschemaid 
             from fincfg.routingrules as rr, fincfg.queues as q, fincfg.servicemaps as sr 
             where rr.routingschemaid = v_row.id and rr.queueid = q.id and q.exitpoint = sr.id
             and sr.exitpoint like '%.xslt%'
            ) x;
             
        -- mediocre services
        select count(x.*) into v_serviceoptmedium
        from
        	(select rr.routingschemaid
             from fincfg.routingrules as rr, fincfg.queues as q, fincfg.servicemaps as sr
             where rr.routingschemaid = v_row.id and rr.queueid = q.id and q.exitpoint = sr.id
             and (sr.duplicatecheck = 1 or sr.exitpoint like '%S=%')
            ) x;
            
       	-- high services
        v_serviceopthigh := 0;
        
        v_update := current_date::text;
        
        insert into fintrack.routingschemaanalysis
        values(v_row.id, v_row.name, v_noroutingrules, v_actionslow, v_actionsmedium, v_actionshigh, v_validationslow, v_validationsmedium, 
              v_validationshigh, v_serviceoptlow, v_serviceoptmedium, v_serviceopthigh, v_update, v_details);
 
    end loop;

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

ALTER FUNCTION fintrack.collectrsdata()
  OWNER TO fintrack;