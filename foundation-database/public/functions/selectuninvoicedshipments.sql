CREATE OR REPLACE FUNCTION selectUninvoicedShipments(pWarehousid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r RECORD;
  _recordCounter INTEGER := 0;

BEGIN

--  Grab all of the uninvoiced/unbilled shipitem records
  FOR _r IN SELECT DISTINCT shiphead_id
            FROM shiphead JOIN shipitem ON (shipitem_shiphead_id=shiphead_id)
                          JOIN coitem ON (coitem_id=shipitem_orderitem_id)
                          JOIN itemsite ON (itemsite_id=coitem_itemsite_id)
                          LEFT OUTER JOIN cobill ON (cobill_shipitem_id=shipitem_id)
            WHERE ( (shiphead_order_type='SO')
              AND   (coitem_status <> 'C')
              AND   ( (pWarehousid = -1) OR (itemsite_warehous_id=pWarehousid) )
              AND   (shiphead_shipped)
              AND   (NOT shipitem_invoiced)
              AND   (cobill_id IS NULL) )
  LOOP

    PERFORM selectUninvoicedShipment(_r.shiphead_id);

    _recordCounter := _recordCounter + 1;

  END LOOP;

  RETURN _recordCounter;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION selectUninvoicedShipments(pWarehousid INTEGER,
                                                     pCusttypeid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r RECORD;
  _recordCounter INTEGER := 0;

BEGIN

--  Grab all of the uninvoiced/unbilled shipitem records
  FOR _r IN SELECT DISTINCT shiphead_id
            FROM shiphead JOIN shipitem ON (shipitem_shiphead_id=shiphead_id)
                          JOIN coitem ON (coitem_id=shipitem_orderitem_id)
                          JOIN itemsite ON (itemsite_id=coitem_itemsite_id)
                          JOIN cohead ON (cohead_id=coitem_cohead_id)
                          JOIN custinfo ON (cust_id=cohead_cust_id)
                          LEFT OUTER JOIN cobill ON (cobill_shipitem_id=shipitem_id)
            WHERE ( (shiphead_order_type='SO')
              AND   (coitem_status <> 'C')
              AND   (coitem_cohead_id=cohead_id)
              AND   (cust_custtype_id=pCusttypeid)
              AND   ( (pWarehousid = -1) OR (itemsite_warehous_id=pWarehousid) )
              AND   (shiphead_shipped)
              AND   (NOT shipitem_invoiced)
              AND   (cobill_id IS NULL) )
  LOOP

    PERFORM selectUninvoicedShipment(_r.shiphead_id);

    _recordCounter := _recordCounter + 1;

  END LOOP;

  RETURN _recordCounter;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION selectUninvoicedShipments(pWarehousid INTEGER,
                                                     pCusttype TEXT) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r RECORD;
  _recordCounter INTEGER := 0;

BEGIN

--  Grab all of the uninvoiced shipitem records
  FOR _r IN SELECT DISTINCT shiphead_id
            FROM shiphead JOIN shipitem ON (shipitem_shiphead_id=shiphead_id)
                          JOIN coitem ON (coitem_id=shipitem_orderitem_id)
                          JOIN itemsite ON (itemsite_id=coitem_itemsite_id)
                          JOIN cohead ON (cohead_id=coitem_cohead_id)
                          JOIN custinfo ON (cust_id=cohead_cust_id)
                          JOIN custtype ON (custtype_id=cust_custtype_id)
                          LEFT OUTER JOIN cobill ON (cobill_shipitem_id=shipitem_id)
            WHERE ( (shiphead_order_type='SO')
              AND   (coitem_status <> 'C')
              AND   (coitem_cohead_id=cohead_id)
              AND   ( (pWarehousid = -1) OR (itemsite_warehous_id=pWarehousid) )
              AND   (custtype_code ~ pCusttype)
              AND   (shiphead_shipped)
              AND   (NOT shipitem_invoiced)
              AND   (cobill_id IS NULL) )
  LOOP

    PERFORM selectUninvoicedShipment(_r.shiphead_id);

    _recordCounter := _recordCounter + 1;

  END LOOP;

  RETURN _recordCounter;

END;
$$ LANGUAGE plpgsql;
