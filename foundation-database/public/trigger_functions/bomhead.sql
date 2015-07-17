CREATE OR REPLACE FUNCTION _bomheadTrigger() RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _revid INTEGER;
  _check TEXT;
  _cmnttypeid INTEGER;
BEGIN
-- Privilege Checks
  IF (NOT checkPrivilege('MaintainBOMs')) THEN
    RAISE EXCEPTION 'You do not have privileges to maintain Bills of Material.';
  END IF;

--  Cache the cmnttype_id for ChangeLog
    SELECT cmnttype_id INTO _cmnttypeid
    FROM cmnttype
    WHERE (cmnttype_name='ChangeLog');
    IF (FOUND) THEN
      IF (TG_OP = 'INSERT') THEN
        PERFORM postComment(_cmnttypeid, 'BMH', NEW.bomhead_id, 'Created');

      ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.bomhead_revision <> NEW.bomhead_revision) THEN
          PERFORM postComment(_cmnttypeid, 'BMH', NEW.bomhead_id, 'Revision Updated from '||
                                       OLD.bomhead_revision||' to '||NEW.bomhead_revision);
        ELSE                                      
          PERFORM postComment(_cmnttypeid, 'BMH', NEW.bomhead_id, 'Updated');
        END IF;  
      END IF;
    END IF;  

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS bomheadTrigger ON bomhead;
CREATE TRIGGER bomheadTrigger AFTER INSERT OR UPDATE OR DELETE ON bomhead FOR EACH ROW EXECUTE PROCEDURE _bomheadTrigger();
