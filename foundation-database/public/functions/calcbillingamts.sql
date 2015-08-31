CREATE OR REPLACE FUNCTION calcCobillAmt(pCobillid INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _amount NUMERIC := 0.0;

BEGIN

  SELECT COALESCE(round((cobill_qty * coitem_qty_invuomratio) *
                        (coitem_price / coitem_price_invuomratio), 2), 0.0) INTO _amount
  FROM cobill JOIN coitem ON (coitem_id=cobill_coitem_id)
  WHERE (cobill_id=pCobillid);

  RETURN _amount;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calcCobillTax(pCobillid INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _amount NUMERIC := 0.0;

BEGIN

  SELECT COALESCE(calculateTax(cobmisc_taxzone_id,
                               cobill_taxtype_id,
                               cobmisc_shipdate,
                               cobmisc_curr_id,
                               calcCobillAmt(cobill_id)), 0.0) INTO _amount
  FROM cobill JOIN cobmisc ON (cobmisc_id=cobill_cobmisc_id)
  WHERE (cobill_id=pCobillid);

  RETURN _amount;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calcCobmiscAmt(pCobmiscid INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _amount NUMERIC := 0.0;

BEGIN

  SELECT SUM(COALESCE(calcCobillAmt(cobill_id), 0.0)) INTO _amount
  FROM cobmisc JOIN cobill ON (cobmisc_id=cobill_cobmisc_id)
  WHERE (cobmisc_id=pCobmiscid);

  RETURN _amount;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calcCobmiscTax(pCobmiscid INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _amount NUMERIC := 0.0;

BEGIN

  SELECT SUM(
         COALESCE(calculateTax(cobmisc_taxzone_id,
                               cobill_taxtype_id,
                               cobmisc_shipdate,
                               cobmisc_curr_id,
                               calcCobillAmt(cobill_id)), 0.0)
            ) INTO _amount
  FROM cobmisc JOIN cobill ON (cobmisc_id=cobill_cobmisc_id)
  WHERE (cobmisc_id=pCobmiscid);

  RETURN _amount;

END;
$$ LANGUAGE plpgsql;
