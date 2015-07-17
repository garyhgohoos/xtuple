CREATE OR REPLACE FUNCTION _trialbalaltertrigger()
  RETURNS trigger AS $$
-- Copyright (c) 1999-2015 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF(TG_OP='DELETE') THEN
    RAISE EXCEPTION 'You may not delete Trial Balance Transactions.';
  END IF;

  IF (SELECT period_closed FROM period WHERE period_id=NEW.trialbal_period_id) THEN
    RAISE EXCEPTION 'You may not alter Trial Balance records in a closed Period.';
  END IF;
  
  RETURN NEW;
END;
$$   LANGUAGE plpgsql;

SELECT dropIfExists('TRIGGER', 'trialbalaltertrigger');
CREATE TRIGGER trialbalaltertrigger BEFORE INSERT OR UPDATE OR DELETE
  ON trialbal FOR EACH ROW EXECUTE PROCEDURE _trialbalaltertrigger();
