CREATE OR REPLACE FUNCTION _shiptoinfoBeforeTrigger () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  -- Timestamps
  IF (TG_OP = 'INSERT') THEN
    NEW.shipto_created := now();
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.shipto_lastupdated := now();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS shiptoinfoBeforeTrigger ON shiptoinfo;
CREATE TRIGGER shiptoinfoBeforeTrigger BEFORE INSERT OR UPDATE ON shiptoinfo
 FOR EACH ROW EXECUTE PROCEDURE _shiptoinfoBeforeTrigger();

CREATE OR REPLACE FUNCTION _shiptoinfoAfterTrigger () RETURNS TRIGGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN

  IF (NEW.shipto_default) THEN
    UPDATE shiptoinfo
    SET shipto_default = false
    WHERE ((shipto_cust_id=NEW.shipto_cust_id)
    AND (shipto_id <> NEW.shipto_id));
  END IF;

  IF (fetchMetricBool('CustomerChangeLog')) THEN
    IF (TG_OP = 'INSERT') THEN
      PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, 'Created');

    ELSIF (TG_OP = 'UPDATE') THEN
      IF (OLD.shipto_name <> NEW.shipto_name) THEN
        PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To Name'),
                            COALESCE(OLD.shipto_name, ''), COALESCE(NEW.shipto_name, ''));
      END IF;
      IF (OLD.shipto_shipvia <> NEW.shipto_shipvia) THEN
        PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To ShipVia'),
                            COALESCE(OLD.shipto_shipvia, ''), COALESCE(NEW.shipto_shipvia, ''));
      END IF;
      IF (COALESCE(OLD.shipto_taxzone_id, -1) <> COALESCE(NEW.shipto_taxzone_id, -1)) THEN
        PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To Tax Zone'),
                            COALESCE((SELECT taxzone_code FROM taxzone WHERE taxzone_id=OLD.shipto_taxzone_id), 'None'), 
                            COALESCE((SELECT taxzone_code FROM taxzone WHERE taxzone_id=NEW.shipto_taxzone_id), 'None'));
      END IF;
      IF (OLD.shipto_shipzone_id <> NEW.shipto_shipzone_id) THEN
        PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To Shipping Zone'),
                            COALESCE((SELECT shipzone_name FROM shipzone WHERE shipzone_id=OLD.shipto_shipzone_id), 'None'),
                            COALESCE((SELECT shipzone_name FROM shipzone WHERE shipzone_id=NEW.shipto_shipzone_id), 'None'));
      END IF;
      IF (OLD.shipto_salesrep_id <> NEW.shipto_salesrep_id) THEN
        PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To Sales Rep'),
                            (SELECT salesrep_name FROM salesrep WHERE salesrep_id=OLD.shipto_salesrep_id),
                            (SELECT salesrep_name FROM salesrep WHERE salesrep_id=NEW.shipto_salesrep_id));
      END IF;
      IF (OLD.shipto_active <> NEW.shipto_active) THEN
        IF (NEW.shipto_active) THEN
          PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To Activated'));
        ELSE
          PERFORM postComment('ChangeLog', 'C', NEW.shipto_cust_id, (NEW.shipto_name || ': Ship To Deactivated'));
        END IF;
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS shiptoinfoAfterTrigger ON shiptoinfo;
CREATE TRIGGER shiptoinfoAfterTrigger AFTER INSERT OR UPDATE ON shiptoinfo FOR EACH ROW EXECUTE PROCEDURE _shiptoinfoAfterTrigger();

