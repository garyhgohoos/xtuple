CREATE OR REPLACE FUNCTION qtyReserved(pItemsiteid INTEGER) RETURNS NUMERIC AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/EULA for the full text of the software license.
DECLARE
  _qty NUMERIC;

BEGIN

  -- returns qty reserved in inv uom
  SELECT COALESCE(SUM(coitem_qtyreserved * coitem_qty_invuomratio),0) INTO _qty
    FROM itemsite JOIN coitem ON (coitem_itemsite_id=itemsite_id)
   WHERE(itemsite_id=pItemsiteid);

  RETURN _qty;
END;
$$ LANGUAGE plpgsql;
