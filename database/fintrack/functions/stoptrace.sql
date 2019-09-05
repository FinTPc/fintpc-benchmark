--Function: fintrack.stoptrace(inuserid integer)

--DROP FUNCTION fintrack.stoptrace(inuserid integer);

CREATE OR REPLACE FUNCTION fintrack.stoptrace
(
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
  Created:         03.Oct.2018, DanielC  - 13037
  Description:     Collects data for performance check
  Parameters:      inuserid - the user who start tracing                    
  Returns:         n/a
  Used:            FinTP/BASE/RE
***********************************************/


BEGIN
    
   update fintrack.tracestatus
   set date = current_timestamp, userid = inUserId
   where status = 'STOP';
   
   RETURN 0;

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

ALTER FUNCTION fintrack.stoptrace(inuserid integer)
  OWNER TO fintrack;