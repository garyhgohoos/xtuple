CREATE OR REPLACE FUNCTION itemInvPriceRat(pItemid INTEGER) RETURNS NUMERIC STABLE AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _fromUomid INTEGER;
  _toUomid   INTEGER;
  _ratio     NUMERIC := 1.0;

BEGIN

  IF(pItemid IS NULL) THEN
    RETURN 1.0;
  END IF;

  SELECT item_inv_uom_id, item_price_uom_id
    INTO _fromUomid, _toUomid
    FROM item
   WHERE (item_id=pItemid);

  IF(NOT FOUND) THEN
    RAISE EXCEPTION 'No item record found for item_id %', pItemid;
  END IF;

  IF(_fromUomid = _toUomid) THEN
    RETURN 1.0;
  END IF;

  -- Return the ratio as inventory / price
  -- Check item specific uom conversion
  SELECT CASE WHEN(itemuomconv_from_uom_id=_fromUomid) THEN itemuomconv_from_value / itemuomconv_to_value
              ELSE itemuomconv_to_value / itemuomconv_from_value
         END
    INTO _ratio
    FROM itemuomconv
   WHERE((((itemuomconv_from_uom_id=_fromUomid) AND (itemuomconv_to_uom_id=_toUomid))
       OR ((itemuomconv_from_uom_id=_toUomid) AND (itemuomconv_to_uom_id=_fromUomid)))
     AND (itemuomconv_item_id=pItemid));

  IF(NOT FOUND) THEN
    -- Check global uom conversion
    SELECT CASE WHEN(uomconv_from_uom_id=_fromUomid) THEN uomconv_from_value / uomconv_to_value
                ELSE uomconv_to_value / uomconv_from_value
           END
      INTO _ratio
      FROM uomconv
     WHERE((((uomconv_from_uom_id=_fromUomid) AND (uomconv_to_uom_id=_toUomid))
         OR ((uomconv_from_uom_id=_toUomid) AND (uomconv_to_uom_id=_fromUomid))));

    IF(NOT FOUND) THEN
      RAISE EXCEPTION 'No itemuomconv record found for item_id %, invuom_id %, priceuom_id %', pItemid, _fromUomid, _toUomid;
    END IF;
  END IF;
  
  RETURN _ratio;
END;
$$ LANGUAGE plpgsql;
