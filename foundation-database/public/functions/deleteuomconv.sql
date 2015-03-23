CREATE OR REPLACE FUNCTION deleteUOMConv(pUomconvid INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  DELETE FROM uomconv WHERE uomconv_id=pUomconvid;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;
