CREATE OR REPLACE FUNCTION deleteUOMConv(pUomconvid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _r             RECORD;
  _fromuomid     INTEGER;
  _touomid       INTEGER;
  _invuomid      INTEGER;
  _itemid        INTEGER;

BEGIN
  SELECT uomconv_from_uom_id, uomconv_to_uom_id
          INTO _fromuomid, _touomid
  FROM uomconv
  WHERE (uomconv_id=pUomconvid);

  FOR _r IN
   SELECT item_id, item_inv_uom_id
   FROM item
  LOOP
    IF EXISTS(SELECT *
              FROM uomusedforitem(_r.item_id)
              WHERE ((uom_id IN (_fromuomid, _touomid))
                 AND (uom_id != _r.item_inv_uom_id)) ) THEN
      IF NOT EXISTS(SELECT *
                    FROM itemuomconv
                    WHERE (itemuomconv_item_id=_r.item_id)
                      AND (itemuomconv_from_uom_id IN (_fromuomid, _touomid))
                      AND (itemuomconv_to_uom_id IN (_fromuomid, _touomid))) THEN
        RETURN -1;
      END IF;
    END IF;
  END LOOP;

  DELETE FROM uomconv WHERE uomconv_id=pUomconvid;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;
