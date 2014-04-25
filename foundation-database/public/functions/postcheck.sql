CREATE OR REPLACE FUNCTION postCheck(INTEGER, INTEGER) RETURNS INTEGER AS $$
-- Copyright (c) 1999-2014 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  pcheckid              ALIAS FOR $1;
  _journalNumber        INTEGER := $2;
  _amount_base          NUMERIC := 0;
  _credit_glaccnt       INTEGER;
  _exchGain             NUMERIC := 0;
  _exchGainTmp          NUMERIC := 0;
  _gltransNote          TEXT;
  _p                    RECORD;
  _r                    RECORD;
  _t                    RECORD;
  _tax                  RECORD;
  _sequence             INTEGER;
  _apdiscountid         INTEGER := -1;
  _test                 INTEGER;
  _cm                   BOOLEAN;
  _amount_check         NUMERIC := 0;

BEGIN

  _cm := FALSE;

  SELECT fetchGLSequence() INTO _sequence;
  IF (_journalNumber IS NULL) THEN
    _journalNumber := fetchJournalNumber('AP-CK');
  END IF;

  SELECT checkhead.*,
         checkhead_amount / checkhead_curr_rate AS checkhead_amount_base,
         bankaccnt_accnt_id AS bankaccntid INTO _p
  FROM checkhead
   JOIN bankaccnt ON (checkhead_bankaccnt_id=bankaccnt_id)
  WHERE (checkhead_id=pcheckid);

  IF (FOUND) THEN
    IF (_p.checkhead_recip_type = 'V') THEN
      SELECT
        vend_number AS checkrecip_number,
        vend_name AS checkrecip_name,
        findAPAccount(vend_id) AS checkrecip_accnt_id,
        'A/P'::text AS checkrecip_gltrans_source
        INTO _t
      FROM vendinfo
      WHERE (vend_id=_p.checkhead_recip_id);
    ELSIF (_p.checkhead_recip_type = 'C') THEN
      SELECT
        cust_number AS checkrecip_number,
        cust_name AS checkrecip_name,
        findARAccount(cust_id) AS checkrecip_accnt_id,
        'A/R'::text AS checkrecip_gltrans_source
        INTO _t
      FROM custinfo
      WHERE (cust_id=_p.checkhead_recip_id); 
    ELSIF (_p.checkhead_recip_type = 'T') THEN
      SELECT
        taxauth_code AS checkrecip_number,
        taxauth_name AS checkrecip_name,
        taxauth_accnt_id AS checkrecip_accnt_id,
        'G/L'::text AS checkrecip_gltrans_source
        INTO _t
      FROM taxauth
      WHERE (taxauth_id=_p.checkhead_recip_id);
    ELSE
      RETURN -11;
    END IF;
  ELSE
    RETURN -11;
  END IF;

  IF (_p.checkhead_posted) THEN
    RETURN -10;
  END IF;

  IF (_p.checkhead_recip_type = 'C') THEN
    SELECT checkitem_id FROM checkitem INTO _test
    WHERE (checkitem_checkhead_id=pcheckid)
    LIMIT 1;
    IF (FOUND) THEN
      _cm := TRUE;
    END IF;
  END IF;

  _gltransNote := _t.checkrecip_number || '-' || _t.checkrecip_name;

  IF (_p.checkhead_misc AND NOT _cm) THEN
    IF (COALESCE(_p.checkhead_expcat_id, -1) < 0) THEN
      IF (_p.checkhead_recip_type = 'V') THEN
	PERFORM createAPCreditMemo( _p.checkhead_recip_id, _journalNumber,
				    CAST(fetchAPMemoNumber() AS text), '',
				    _p.checkhead_checkdate, _p.checkhead_amount,
				    _gltransNote || ' ' || _p.checkhead_notes,
				    -1, _p.checkhead_checkdate,
				    -1, _p.checkhead_curr_id );
	_credit_glaccnt := findAPPrepaidAccount(_p.checkhead_recip_id);

      ELSIF (_p.checkhead_recip_type = 'C') THEN
	PERFORM createARDebitMemo(NULL, _p.checkhead_recip_id, NULL,
	  			     fetchARMemoNumber(), '',
				     _p.checkhead_checkdate, _p.checkhead_amount,
				     _gltransNote || ' ' || _p.checkhead_notes,
                                     -1, -1, -1, _p.checkhead_checkdate, -1, NULL, 0,
				     _p.checkhead_curr_id );
        _credit_glaccnt := findPrepaidAccount(_p.checkhead_recip_id);
      ELSIF (_p.checkhead_recip_type = 'T') THEN
	-- TODO: should we create a credit memo for the tax authority? how?
	_credit_glaccnt := _t.checkrecip_accnt_id;

      END IF; -- recip type

    ELSE
      IF (_cm) THEN
        _credit_glaccnt := findARAccount(_p.checkhead_recip_id);
      ELSE
        SELECT expcat_exp_accnt_id INTO _credit_glaccnt
        FROM expcat
        WHERE (expcat_id=_p.checkhead_expcat_id);
        IF (NOT FOUND) THEN
          RETURN -12;
        END IF;
      END IF;
    END IF;

    IF (COALESCE(_credit_glaccnt, -1) < 0) THEN
      RETURN -13;
    END IF;

    PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source, 'CK',
				CAST(_p.checkhead_number AS TEXT),
				_credit_glaccnt,
				round(_p.checkhead_amount_base, 2) * -1,
				_p.checkhead_checkdate, _gltransNote, pcheckid );

    _amount_base := _p.checkhead_amount_base;

  ELSE
    FOR _r IN SELECT checkitem_amount, checkitem_discount,
                     CASE WHEN (checkitem_apopen_id IS NOT NULL AND apopen_doctype='C') THEN
                            checkitem_amount / apopen_curr_rate * -1.0
                          WHEN (checkitem_apopen_id IS NOT NULL) THEN
                            checkitem_amount / apopen_curr_rate
                          ELSE
                            currToBase(checkitem_curr_id,
                                       checkitem_amount,
                                       COALESCE(checkitem_docdate, _p.checkhead_checkdate)) 
                     END AS checkitem_amount_base,
                     currTocurr(checkitem_curr_id, _p.checkhead_curr_id,
                                CASE WHEN (checkitem_apopen_id IS NOT NULL AND apopen_doctype='C') THEN
                                          checkitem_amount * -1.0
                                     ELSE checkitem_amount END,
                                  _p.checkhead_checkdate) AS amount_check,
                     apopen_id, apopen_doctype, apopen_docnumber,
                     aropen_id, aropen_doctype, aropen_docnumber,
                     checkitem_curr_id, checkitem_curr_rate, apopen_curr_rate,
                     COALESCE(checkitem_docdate, _p.checkhead_checkdate) AS docdate
              FROM (checkitem LEFT OUTER JOIN
		    apopen ON (checkitem_apopen_id=apopen_id)) LEFT OUTER JOIN
		    aropen ON (checkitem_aropen_id=aropen_id)
              WHERE (checkitem_checkhead_id=pcheckid) LOOP

      _exchGainTmp := 0;
      IF (_r.apopen_id IS NOT NULL) THEN
	--  take the discount if specified before we do anything else
        IF(_r.checkitem_discount > 0.0) THEN
          SELECT createAPDiscount(_r.apopen_id, _r.checkitem_discount) INTO _apdiscountid;
        END IF;

        UPDATE apopen

        SET apopen_paid = round(apopen_paid + _r.checkitem_amount, 2),
            apopen_open = round(apopen_amount, 2) >
			  round(apopen_paid + _r.checkitem_amount, 2),
            apopen_closedate = CASE WHEN (round(apopen_amount, 2) <=
			                  round(apopen_paid + _r.checkitem_amount, 2)) THEN _p.checkhead_checkdate END
        WHERE (apopen_id=_r.apopen_id);

	--  Post the application
        INSERT INTO apapply
        ( apapply_vend_id, apapply_postdate, apapply_username,
          apapply_source_apopen_id, apapply_source_doctype, apapply_source_docnumber,
          apapply_target_apopen_id, apapply_target_doctype, apapply_target_docnumber,
          apapply_journalnumber, apapply_amount, apapply_curr_id, apapply_checkhead_id )
        VALUES
        ( _p.checkhead_recip_id, _p.checkhead_checkdate, getEffectiveXtUser(),
          -1, 'K', _p.checkhead_number,
          _r.apopen_id, _r.apopen_doctype, _r.apopen_docnumber,
          _journalNumber, _r.checkitem_amount, _r.checkitem_curr_id, _p.checkhead_id );

        IF (fetchMetricBool('CashBasedTax')) THEN
          -- Cash based tax distributions
          IF (_r.apopen_doctype = 'V') THEN
            -- Voucher
            -- first, debit the tax liability clearing account
            -- and credit the tax liability distribution account
            -- for each tax code
            FOR _tax IN SELECT docnumber, vendname,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               currToBase(currid, ROUND(SUM(taxhist_tax),2), taxhist_docdate) AS taxbasevalue
                        FROM (SELECT _r.apopen_docnumber AS docnumber, vend_name AS vendname,
                                     apopen_curr_id AS currid,
                                     tax_sales_accnt_id, tax_dist_accnt_id,
                                     taxhist_tax, taxhist_docdate
                              FROM apopen JOIN vohead ON (vohead_number=_r.apopen_docnumber)
                                          JOIN vendinfo ON (vend_id=apopen_vend_id)
                                          JOIN voheadtax ON (taxhist_parent_id=vohead_id)
                                          JOIN tax ON (tax_id=taxhist_tax_id)
                              WHERE (apopen_id=_r.apopen_id)
                              UNION
                              SELECT _r.apopen_docnumber AS docnumber, vend_name AS vendname,
                                     apopen_curr_id AS currid,
                                     tax_sales_accnt_id, tax_dist_accnt_id,
                                     taxhist_tax, taxhist_docdate
                              FROM apopen JOIN vohead ON (vohead_number=_r.apopen_docnumber)
                                          JOIN vendinfo ON (vend_id=apopen_vend_id)
                                          JOIN voitem ON (voitem_vohead_id=vohead_id)
                                          JOIN voitemtax ON (taxhist_parent_id=voitem_id)
                                          JOIN tax ON (tax_id=taxhist_tax_id)
                              WHERE (apopen_id=_r.apopen_id)) AS data
                        GROUP BY docnumber, vendname, currid,
                                 tax_sales_accnt_id, tax_dist_accnt_id, taxhist_docdate
            LOOP
              PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source, 'CK', _tax.docnumber,
                                          _tax.tax_dist_accnt_id, 
                                          _tax.taxbasevalue,
                                          _p.checkhead_checkdate, _tax.vendname );
              PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source, 'CK', _tax.docnumber,
                                          _tax.tax_sales_accnt_id, 
                                          (_tax.taxbasevalue * -1.0),
                                          _p.checkhead_checkdate, _tax.vendname );
            END LOOP;

            -- second, create a taxpay row for each taxhist
            FOR _tax IN SELECT *,
                               currToBase(taxhist_curr_id, ROUND(taxhist_tax,2), taxhist_docdate) AS taxbasevalue
                        FROM (SELECT taxhist_id, taxhist_curr_id, taxhist_tax, taxhist_docdate
                              FROM apopen JOIN vohead ON (vohead_number=apopen_docnumber)
                                          JOIN voheadtax ON (taxhist_parent_id=vohead_id)
                              WHERE (apopen_id=_r.apopen_id)
                              UNION
                              SELECT taxhist_id, taxhist_curr_id, taxhist_tax, taxhist_docdate
                              FROM apopen JOIN vohead ON (vohead_number=apopen_docnumber)
                                          JOIN voitem ON (voitem_vohead_id=vohead_id)
                                          JOIN voitemtax ON (taxhist_parent_id=voitem_id)
                              WHERE (apopen_id=_r.apopen_id)) AS data
            LOOP
              INSERT INTO taxpay
              ( taxpay_taxhist_id, taxpay_apply_id, taxpay_distdate, taxpay_tax )
              VALUES
              ( _tax.taxhist_id, _r.apopen_id, _p.checkhead_checkdate, _tax.taxbasevalue );
            END LOOP;
          END IF;
        END IF;

      END IF; -- if check item's apopen_id is not null

      IF (_r.aropen_id IS NOT NULL) THEN

        UPDATE aropen
        SET aropen_paid = round(aropen_paid + _r.checkitem_amount, 2),
            aropen_open = round(aropen_amount, 2) >
			  round(aropen_paid + _r.checkitem_amount, 2),
            aropen_closedate = CASE WHEN (round(aropen_amount, 2) <=
			                  round(aropen_paid + _r.checkitem_amount, 2)) THEN _p.checkhead_checkdate END
        WHERE (aropen_id=_r.aropen_id);

	--  Post the application
        INSERT INTO arapply
        ( arapply_cust_id, arapply_postdate, arapply_distdate, arapply_username,
          arapply_source_aropen_id, arapply_source_doctype, arapply_source_docnumber,
          arapply_target_aropen_id, arapply_target_doctype, arapply_target_docnumber,
          arapply_journalnumber, arapply_applied, arapply_curr_id )
        VALUES
        ( _p.checkhead_recip_id, _p.checkhead_checkdate, _p.checkhead_checkdate, getEffectiveXtUser(),
          _r.aropen_id,_r.aropen_doctype, _r.aropen_docnumber,
          -1, 'K',_p.checkhead_number ,
          _journalNumber, _r.checkitem_amount, _r.checkitem_curr_id );

        -- TODO: don't think there is a need to do anything for A/R items
        --IF (fetchMetricBool('CashBasedTax')) THEN
        IF (false) THEN
          -- Cash based tax distributions
          IF (_r.aropen_doctype = 'C') THEN
            -- Debit Memo
            -- first, debit the tax liability clearing account
            -- and credit the tax liability distribution account
            -- for each tax code
            FOR _tax IN SELECT docnumber, custname,
                               tax_sales_accnt_id, tax_dist_accnt_id,
                               currToBase(currid, ROUND(SUM(taxhist_tax),2), taxhist_docdate) AS taxbasevalue
                        FROM (SELECT _r.aropen_docnumber AS docnumber, cust_name AS custname,
                                     aropen_curr_id AS currid,
                                     tax_sales_accnt_id, tax_dist_accnt_id,
                                     taxhist_tax, taxhist_docdate
                              FROM aropen JOIN custinfo ON (cust_id=aropen_cust_id)
                                          JOIN cohist ON (cohist_invcnumber=aropen_docnumber AND cohist_doctype='C')
                                          JOIN cohisttax ON (taxhist_parent_id=cohist_id)
                                          JOIN tax ON (tax_id=taxhist_tax_id)
                              WHERE (aropen_id=_r.aropen_id)
                              -- include taxes associated with C/M created by discount
                              -- taxhist_tax is negative which will reduce summary
                              UNION
                              SELECT _r.aropen_docnumber AS docnumber, cust_name AS custname,
                                     aropen_curr_id AS currid,
                                     tax_sales_accnt_id, tax_dist_accnt_id,
                                     taxhist_tax, taxhist_docdate
                              FROM aropen JOIN custinfo ON (cust_id=aropen_cust_id)
                                          JOIN cohist ON (cohist_invcnumber=aropen_docnumber AND cohist_doctype='C')
                                          JOIN cohisttax ON (taxhist_parent_id=cohist_id)
                                          JOIN tax ON (tax_id=taxhist_tax_id)
                              WHERE (aropen_id=_apdiscountid)) AS data
                        GROUP BY docnumber, custname, currid,
                                 tax_sales_accnt_id, tax_dist_accnt_id, taxhist_docdate
            LOOP
              PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source, 'CK', _tax.docnumber,
                                          _tax.tax_dist_accnt_id, 
                                          _tax.taxbasevalue,
                                          _p.checkhead_checkdate, _tax.custname );
              PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source, 'CK', _tax.docnumber,
                                          _tax.tax_sales_accnt_id, 
                                          (_tax.taxbasevalue * -1.0),
                                          _p.checkhead_checkdate, _tax.custname );
            END LOOP;

            -- second, create a taxpay row for each taxhist
            FOR _tax IN SELECT *,
                               currToBase(taxhist_curr_id, ROUND(taxhist_tax,2), taxhist_docdate) AS taxbasevalue
                        FROM (SELECT cohisttax.*
                              FROM aropen JOIN cohist ON (cohist_invcnumber=aropen_docnumber AND cohist_doctype='D')
                                          JOIN cohisttax ON (taxhist_parent_id=cohist_id)
                              WHERE (aropen_id=_r.aropen_id)
                              -- include taxes associated with C/M created by discount
                              UNION
                              SELECT cohisttax.*
                              FROM aropen JOIN cohist ON (cohist_invcnumber=aropen_docnumber AND cohist_doctype='C')
                                          JOIN cohisttax ON (taxhist_parent_id=cohist_id)
                              WHERE (aropen_id=_apdiscountid)) AS data
            LOOP
              INSERT INTO taxpay
              ( taxpay_taxhist_id, taxpay_apply_id, taxpay_distdate, taxpay_tax )
              VALUES
              ( _tax.taxhist_id, _r.aropen_id, _p.cashrcpt_distdate, _tax.taxbasevalue );
            END LOOP;
          END IF;
        END IF;

      END IF; -- if check item's aropen_id is not null

      IF (_r.apopen_id IS NOT NULL) THEN
        SELECT apCurrGain(_r.apopen_id,_r.checkitem_curr_id, _r.checkitem_amount,
                        _p.checkhead_checkdate)
              INTO _exchGainTmp;
      ELSIF (_r.aropen_id IS NOT NULL) THEN
        SELECT arCurrGain(_r.aropen_id,_r.checkitem_curr_id, _r.checkitem_amount,
                        _p.checkhead_checkdate)
              INTO _exchGainTmp;
      END IF;
      _exchGain := _exchGain + _exchGainTmp;

      PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source,
                                  'CK', CAST(_p.checkhead_number AS TEXT),
                                  _t.checkrecip_accnt_id,
                                  round(_r.checkitem_amount_base, 2) * -1.0,
                                  _p.checkhead_checkdate, _gltransNote, pcheckid );
      IF (_exchGainTmp <> 0) THEN
	PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source,
                                   'CK', CAST(_p.checkhead_number AS TEXT),
                                   getGainLossAccntId(_t.checkrecip_accnt_id),
                                   round(_exchGainTmp,2),
                                   _p.checkhead_checkdate, _gltransNote, pcheckid );
      END IF;

      _amount_check := (_amount_check + _r.amount_check);
      _amount_base := (_amount_base + _r.checkitem_amount_base);

    END LOOP;

    IF( (_amount_check - _p.checkhead_amount) <> 0.0 ) THEN 
      _exchGainTmp := currToBase(_p.checkhead_curr_id,
                                 _amount_check - _p.checkhead_amount,
                                 _p.checkhead_checkdate);
      _exchGain := _exchGain + _exchGainTmp;
    END IF;
    --  ensure that the check balances, attribute rounding errors to gain/loss
    IF round(_amount_base, 2) - round(_exchGain, 2) <> round(_p.checkhead_amount_base, 2) THEN
      IF round(_amount_base - _exchGain, 2) = round(_p.checkhead_amount_base, 2) THEN
	PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source,
				    'CK',
				    CAST(_p.checkhead_number AS TEXT),
                                    getGainLossAccntId(_p.bankaccntid),
				    round(_amount_base, 2) -
				      round(_exchGain, 2) -
				      round(_p.checkhead_amount_base, 2),
				    _p.checkhead_checkdate, _gltransNote, pcheckid );
      ELSE
	RAISE EXCEPTION 'checkhead_id % does not balance (% - % <> %)', pcheckid,
	      _amount_base, _exchGain, _p.checkhead_amount_base;
      END IF;
    END IF;
  END IF;

  PERFORM insertIntoGLSeries( _sequence, _t.checkrecip_gltrans_source, 'CK',
			      CAST(_p.checkhead_number AS TEXT),
                              _p.bankaccntid,
			      round(_p.checkhead_amount_base, 2),
                              _p.checkhead_checkdate, _gltransNote, pcheckid );

  PERFORM postGLSeries(_sequence, _journalNumber);

  UPDATE checkhead
  SET checkhead_posted=TRUE,
      checkhead_journalnumber=_journalNumber
  WHERE (checkhead_id=pcheckid);

  RETURN _journalNumber;

END;
$$ LANGUAGE 'plpgsql';
