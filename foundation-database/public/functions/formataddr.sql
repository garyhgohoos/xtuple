
CREATE OR REPLACE FUNCTION formatAddr(pAddrId INTEGER) RETURNS TEXT AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _return       TEXT;

BEGIN
  -- US conventions
  SELECT formatAddr(addr_line1, addr_line2, addr_line3,
                    (COALESCE(addr_city,'') || ', ' || COALESCE(addr_state,'') || ' ' || COALESCE(addr_postalcode,'')),
                    addr_country) INTO _return
  FROM addr
  WHERE (addr_id=pAddrId);

  RETURN _return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION formatAddr(pId INTEGER,
                                      pType TEXT) RETURNS TEXT AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _return       TEXT;

BEGIN
  -- US conventions
  IF (pType = 'addr') THEN
    SELECT formatAddr(addr_line1, addr_line2, addr_line3,
                      (COALESCE(addr_city,'') || ', ' || COALESCE(addr_state,'') || ' ' || COALESCE(addr_postalcode,'')),
                      addr_country) INTO _return
    FROM addr
    WHERE (addr_id=pId);
  ELSEIF (pType = 'qubill') THEN
    SELECT formatAddr(quhead_billtoaddress1, quhead_billtoaddress2, quhead_billtoaddress3,
                      (COALESCE(quhead_billtocity,'') || ', ' || COALESCE(quhead_billtostate,'') || ' ' || COALESCE(quhead_billtozip,'')),
                      quhead_billtocountry) INTO _return
    FROM quhead
    WHERE (quhead_id=pId);
  ELSEIF (pType = 'quship') THEN
    SELECT formatAddr(quhead_shiptoaddress1, quhead_shiptoaddress2, quhead_shiptoaddress3,
                      (COALESCE(quhead_shiptocity,'') || ', ' || COALESCE(quhead_shiptostate,'') || ' ' || COALESCE(quhead_shiptozipcode,'')),
                      quhead_shiptocountry) INTO _return
    FROM quhead
    WHERE (quhead_id=pId);
  ELSEIF (pType = 'sobill') THEN
    SELECT formatAddr(cohead_billtoaddress1, cohead_billtoaddress2, cohead_billtoaddress3,
                      (COALESCE(cohead_billtocity,'') || ', ' || COALESCE(cohead_billtostate,'') || ' ' || COALESCE(cohead_billtozipcode,'')),
                      cohead_billtocountry) INTO _return
    FROM cohead
    WHERE (cohead_id=pId);
  ELSEIF (pType = 'soship') THEN
    SELECT formatAddr(cohead_shiptoaddress1, cohead_shiptoaddress2, cohead_shiptoaddress3,
                      (COALESCE(cohead_shiptocity,'') || ', ' || COALESCE(cohead_shiptostate,'') || ' ' || COALESCE(cohead_shiptozipcode,'')),
                      cohead_shiptocountry) INTO _return
    FROM cohead
    WHERE (cohead_id=pId);
  ELSEIF (pType = 'invcbill') THEN
    SELECT formatAddr(invchead_billto_address1, invchead_billto_address2, invchead_billto_address3,
                      (COALESCE(invchead_billto_city,'') || ', ' || COALESCE(invchead_billto_state,'') || ' ' || COALESCE(invchead_billto_zipcode,'')),
                      invchead_billto_country) INTO _return
    FROM invchead
    WHERE (invchead_id=pId);
  ELSEIF (pType = 'invcship') THEN
    SELECT formatAddr(invchead_shipto_address1, invchead_shipto_address2, invchead_shipto_address3,
                      (COALESCE(invchead_shipto_city,'') || ', ' || COALESCE(invchead_shipto_state,'') || ' ' || COALESCE(invchead_shipto_zipcode,'')),
                      invchead_shipto_country) INTO _return
    FROM invchead
    WHERE (invchead_id=pId);
  ELSEIF (pType = 'cmbill') THEN
    SELECT formatAddr(cmhead_billtoaddress1, cmhead_billtoaddress2, cmhead_billtoaddress3,
                      (COALESCE(cmhead_billtocity,'') || ', ' || COALESCE(cmhead_billtostate,'') || ' ' || COALESCE(cmhead_billtozip,'')),
                      cmhead_billtocountry) INTO _return
    FROM cmhead
    WHERE (cmhead_id=pId);
  ELSEIF (pType = 'cmship') THEN
    SELECT formatAddr(cmhead_shipto_address1, cmhead_shipto_address2, cmhead_shipto_address3,
                      (COALESCE(cmhead_shipto_city,'') || ', ' || COALESCE(cmhead_shipto_state,'') || ' ' || COALESCE(cmhead_shipto_zipcode,'')),
                      cmhead_shipto_country) INTO _return
    FROM cmhead
    WHERE (cmhead_id=pId);
  ELSEIF (pType = 'tosrc') THEN
    SELECT formatAddr(tohead_srcaddress1, tohead_srcaddress2, tohead_srcaddress3,
                      (COALESCE(tohead_srccity,'') || ', ' || COALESCE(tohead_srcstate,'') || ' ' || COALESCE(tohead_srcpostalcode,'')),
                      tohead_srccountry) INTO _return
    FROM tohead
    WHERE (tohead_id=pId);
  ELSEIF (pType = 'todest') THEN
    SELECT formatAddr(tohead_destaddress1, tohead_destaddress2, tohead_destaddress3,
                      (COALESCE(tohead_destcity,'') || ', ' || COALESCE(tohead_deststate,'') || ' ' || COALESCE(tohead_destpostalcode,'')),
                      tohead_destcountry) INTO _return
    FROM tohead
    WHERE (tohead_id=pId);
  ELSEIF (pType = 'povend') THEN
    SELECT formatAddr(pohead_vendaddress1, pohead_vendaddress2, pohead_vendaddress3,
                      (COALESCE(pohead_vendcity,'') || ', ' || COALESCE(pohead_vendstate,'') || ' ' || COALESCE(pohead_vendzipcode,'')),
                      pohead_vendcountry) INTO _return
    FROM pohead
    WHERE (pohead_id=pId);
  ELSEIF (pType = 'poship') THEN
    SELECT formatAddr(pohead_shiptoaddress1, pohead_shiptoaddress2, pohead_shiptoaddress3,
                      (COALESCE(pohead_shiptocity,'') || ', ' || COALESCE(pohead_shiptostate,'') || ' ' || COALESCE(pohead_shiptozipcode,'')),
                      pohead_shiptocountry) INTO _return
    FROM pohead
    WHERE (pohead_id=pId);
  ELSE
    _return := ' ';
  END IF;

  RETURN _return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION formatAddr(f_addr1 TEXT,
                                      f_addr2 TEXT,
                                      f_addr3 TEXT,
                                      csz TEXT,
                                      line INTEGER) RETURNS TEXT AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  RETURN formatAddr(f_addr1, f_addr2, f_addr3, csz, '', line);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION formatAddr(f_addr1 TEXT,
                                      f_addr2 TEXT,
                                      f_addr3 TEXT,
                                      csz TEXT,
                                      country TEXT,
                                      line INTEGER) RETURNS TEXT AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  i int:=0;

BEGIN

  IF (LENGTH(TRIM(both from f_addr1)) > 0) THEN
    i:=i+1;
  END IF;

  IF (i=line) THEN
    RETURN f_addr1;
  END IF;

  IF (LENGTH(TRIM(both from f_addr2)) > 0)  THEN
    i:=i+1;
  END IF;

  IF (i=line) THEN
    RETURN f_addr2;
  END IF;

  IF (LENGTH(TRIM(both from f_addr3)) > 0) THEN
    i:=i+1;
  END IF;

  IF (i=line) THEN
    RETURN f_addr3;
  END IF;

  IF (LENGTH(TRIM(both from csz)) > 0) THEN
    i:=i+1;
  END IF;

  IF (i=line) THEN
    RETURN csz;
  END IF;

  IF (LENGTH(TRIM(both from country)) > 0) THEN
    i:=i+1;
  END IF;

  IF (i=line) THEN
    RETURN country;
  END IF;

  RETURN ' ';

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION formatAddr(f_addr1 TEXT,
                                      f_addr2 TEXT,
                                      f_addr3 TEXT,
                                      csz TEXT,
                                      country TEXT) RETURNS TEXT AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  addr TEXT:='';

BEGIN

  IF (LENGTH(TRIM(both from f_addr1)) > 0) THEN
    addr:=f_addr1;
  END IF;

  IF (LENGTH(TRIM(both from f_addr2)) > 0)  THEN
        IF (LENGTH(TRIM(both from addr)) > 0) THEN
                addr:=addr || E'\n';
        END IF;
    addr:=addr || f_addr2;
  END IF;

  IF (LENGTH(TRIM(both from f_addr3)) > 0)  THEN
        IF (LENGTH(TRIM(both from addr)) > 0) THEN
                addr:=addr || E'\n';
        END IF;
    addr:=addr || f_addr3;
  END IF;

  IF (LENGTH(TRIM(both from csz)) > 0)  THEN
        IF (LENGTH(TRIM(both from addr)) > 0) THEN
                addr:=addr || E'\n';
        END IF;
    addr:=addr || csz;
  END IF;

  IF (LENGTH(TRIM(both from country)) > 0)  THEN
        IF (LENGTH(TRIM(both from addr)) > 0) THEN
                addr:=addr || E'\n';
        END IF;
    addr:=addr || country;
  END IF;

  RETURN addr;

END;
$$ LANGUAGE plpgsql;

