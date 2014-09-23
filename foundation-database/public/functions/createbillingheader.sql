CREATE OR REPLACE FUNCTION createbillingheader(pShipheadid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _cobmiscid          INTEGER;
  _r                  RECORD;
  _miscApplied        NUMERIC := 0.0;
  _freight            NUMERIC;
  _freighttypeid      INTEGER;
  _invcDate           DATE;
  _schedDate          DATE;
  _shipDate           DATE;
  _shipVia            TEXT;
  _tax                NUMERIC;

BEGIN

  --  Fetch shiphead/cohead
  SELECT * INTO _r
  FROM shiphead JOIN cohead ON (cohead_id=shiphead_order_id)
  WHERE (shiphead_id=pShipheadid);

  --  Check for an existing cobmisc
  SELECT cobmisc_id INTO _cobmiscid
  FROM cobmisc
  WHERE (cobmisc_shiphead_id=pShipheadid);

  IF (FOUND) THEN
    RETURN _cobmiscid;
  END IF;

  --  Find misc charges that have already been applied for the S/O
  SELECT COALESCE(SUM(cobmisc_misc), 0.0) INTO _miscApplied
  FROM cobmisc
  WHERE (cobmisc_cohead_id=_r.cohead_id);

  --  Check for a valid shipdate
  _shipDate := _r.shiphead_shipdate;

  --  Schema shouldn't allow, but we'll try for now
  IF (_shipDate IS NULL) THEN
    SELECT MAX(shipitem_shipdate) INTO _shipDate
    FROM shipitem
    WHERE (shipitem_shiphead_id=pShipheadid);

    --  How about a transaction date
    IF (_shipDate IS NULL) THEN
      SELECT COALESCE(MAX(shipitem_transdate), CURRENT_DATE) INTO _shipDate
      FROM shipitem
      WHERE (shipitem_shiphead_id=pShipheadid);
    END IF;
  END IF;

  --  Get the earliest schedule date for this order.
  SELECT MIN(coitem_scheddate) INTO _schedDate
    FROM coitem
   WHERE ((coitem_status <> 'X') AND (coitem_cohead_id=_r.cohead_id));

  IF (_schedDate IS NULL) THEN
    _schedDate := _shipDate;
  END IF;

  --  Find a Shipping-Entered freight charge
  SELECT SUM(currToCurr(shiphead_freight_curr_id, _r.cohead_curr_id,
                        shiphead_freight, CURRENT_DATE)), shiphead_shipvia
         INTO _freight, _shipVia
  FROM (
  SELECT shiphead_id, shiphead_freight_curr_id, shiphead_freight, shiphead_shipvia
  FROM shiphead JOIN shipitem ON (shipitem_shiphead_id=shiphead_id AND NOT shipitem_invoiced)
  WHERE ((shiphead_order_type='SO')
    AND  (shiphead_id=pShipheadid))
  GROUP BY shiphead_id, shiphead_freight_curr_id, shiphead_freight, shiphead_shipvia) AS data
  GROUP BY shiphead_shipvia;

  --  Nope, use the cohead freight charge
  IF (_freight IS NULL) THEN
    _freight	   := _r.cohead_freight;
  END IF;

  --  Finally, look for a Shipping-Entered Ship Via
  _shipVia := COALESCE(_r.shiphead_shipvia, _r.cohead_shipvia);

  --Determine any tax
  SELECT getFreightTaxTypeId() INTO _freighttypeid;
  SELECT SUM(COALESCE(taxdetail_tax, 0.00)) INTO _tax
  FROM calculatetaxdetail(_r.cohead_taxzone_id,
                          _freighttypeid,
                          _r.cohead_orderdate,
                          _r.cohead_curr_id,
                          _freight);

  --  Determine if we are using the _shipDate or _schedDate or current_date for the _invcDate
  IF( fetchMetricText('InvoiceDateSource')='scheddate') THEN
    _invcDate := _schedDate;
  ELSIF( fetchMetricText('InvoiceDateSource')='shipdate') THEN
    _invcDate := _shipDate;
  ELSE
    _invcDate := current_date;
  END IF;

  SELECT NEXTVAL('cobmisc_cobmisc_id_seq') INTO _cobmiscid;

  INSERT INTO cobmisc
    (cobmisc_id, cobmisc_cohead_id, cobmisc_shipvia, cobmisc_freight, cobmisc_misc, cobmisc_payment,
     cobmisc_notes,cobmisc_shipdate ,cobmisc_invcdate,cobmisc_posted ,cobmisc_misc_accnt_id,
     cobmisc_misc_descrip,cobmisc_closeorder,cobmisc_curr_id,
     cobmisc_taxtype_id,cobmisc_taxzone_id, cobmisc_shiphead_id)
  SELECT
     _cobmiscid, _r.cohead_id,_shipVia, _freight,
     CASE WHEN (_r.cohead_misc - _miscApplied = 0.0) THEN 0.0
          ELSE (_r.cohead_misc - _miscApplied) END, 0,
     _r.cohead_ordercomments, _shipDate, _invcDate, FALSE, _r.cohead_misc_accnt_id,
     _r.cohead_misc_descrip, NOT(cust_backorder), _r.cohead_curr_id,
     _r.cohead_taxtype_id, _r.cohead_taxzone_id, _r.shiphead_id
  FROM custinfo
  WHERE (cust_id=_r.cohead_cust_id);

  RETURN _cobmiscid;

END;
$$ LANGUAGE plpgsql VOLATILE;
