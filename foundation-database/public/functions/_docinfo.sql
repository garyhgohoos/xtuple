CREATE OR REPLACE FUNCTION _docinfo() RETURNS SETOF _docinfo AS $f$
-- Copyright (c) 1999-2015 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
-- Return all document associations, optionally limited to the given document type
DECLARE
  _current      TEXT := '';
  _row          _docinfo%rowtype;
  _desc         record;
  _crm          record;
  _rev          TEXT := $$SELECT '' AS revnumber, '' AS revname, '' AS revdesc,
                                 -1 AS revid,     '' AS revtype$$;
  _reverseQ     TEXT := $$SELECT %s AS revnumber, %s AS revname, %s AS revdesc,
                                 %s AS revid,     '%s' AS revtype
                            FROM %s %s$$;
  _docassQ      TEXT := $$SELECT docass_id AS id,
                                %s AS target_number,
                                %s AS target_type,
                                %s AS target_id,
                                %s AS source_type,
                                %s AS source_id,
                                %s AS name, %s AS description,
                                docass_purpose AS purpose
                           FROM docass JOIN %s ON docass_target_id = %s
                           %s %s
                          WHERE docass_target_type = '%s'
                         UNION ALL
                         SELECT docass_id AS id,
                                revnumber AS target_number,
                                %s AS target_type,
                                %s AS target_id,
                                %s AS source_type,
                                %s AS source_id,
                                revname AS name, revdesc AS description,
                                CASE
                                  WHEN docass_purpose = 'A' THEN 'C'
                                  WHEN docass_purpose = 'C' THEN 'A'
                                  ELSE docass_purpose
                                END AS purpose
                           FROM docass JOIN %s ON docass_target_id = %s
                           JOIN rev ON revid = docass_source_id AND revtype = docass_source_type
                           %s
                          WHERE docass_target_type = '%s'
                       $$;

  _crmIdField       TEXT := '';
  _crmChildIdField  TEXT := '';
BEGIN
  -- TODO: normalize image, url, and file into docass
  _current := $$SELECT imageass_id AS id,
                       image_id::text AS target_number,
                       'IMG' AS target_type,
                       imageass_image_id AS target_id,
                       imageass_source AS source_type,
                       imageass_source_id AS source_id,
                       image_name AS name, image_descrip AS description,
                       imageass_purpose AS purpose
                  FROM imageass
                  JOIN image ON imageass_image_id=image_id
              $$;

  _current := _current || ' UNION ALL ' ||
              $$SELECT url_id AS id,
                       url_id::text AS target_number,
                       'URL' AS target_type,
                       url_id AS target_id,
                       url_source AS source_type,
                       url_source_id AS source_id,
                       url_title AS name, url_url AS description,
                       'S' AS doc_purpose
                  FROM url
                 WHERE (url_stream IS NULL)
              $$;

  _current := _current || ' UNION ALL ' ||
              $$SELECT url_id AS id,
                       url_id::text AS target_number,
                       'FILE' AS target_type,
                       url_id AS target_id,
                       url_source AS source_type,
                       url_source_id AS source_id,
                       url_title AS name, url_url AS description,
                       'S' AS doc_purpose
                  FROM url
                 WHERE (url_stream IS NOT NULL)
              $$;

  SELECT source.* INTO _crm
    FROM source
   WHERE source_docass = 'CRMA';   -- must match populate_source.sql

  FOR _desc IN SELECT source.*
                 FROM source
                 JOIN pg_class c on source_table = relname
                 JOIN pg_namespace n on relnamespace = n.oid
                 JOIN regexp_split_to_table(buildSearchPath(), E',\\s*') sp
                      on nspname = sp
                WHERE relkind = 'r'
  LOOP
    _rev := _rev || ' UNION ALL ' ||
            format(_reverseQ,
                   _desc.source_number_field, _desc.source_name_field,
                   _desc.source_desc_field,   _desc.source_key_field,
                   _desc.source_docass,       _desc.source_table,
                   _desc.source_joins);
    _current := _current || ' UNION ALL ' ||
                format(_docassQ,
                       _desc.source_number_field,
                       'docass_target_type',      'docass_target_id',
                       'docass_source_type',      'docass_source_id',
                       _desc.source_name_field,
                       _desc.source_desc_field,   _desc.source_table,
                       _desc.source_key_field,    _desc.source_joins,
                       '',                        _desc.source_docass,
                       'docass_source_type',      'docass_source_id',
                       'docass_target_type',      'docass_target_id',
                       _desc.source_table,        _desc.source_key_field,
                       _desc.source_joins,        _desc.source_docass);

    -- must match populate_source.sql
    IF _desc.source_docass IN ('C', 'V', 'EMP', 'PSPCT', 'SR', 'USR', 'TAXAUTH')  THEN
      /* for each type of CRM Account child (e.g. customer, vendor),
         - return all CRM Account child doc associations as belonging to the CRM Account
         - return all CRM Account document associations as belonging to the child
       */
      CASE _desc.source_docass
        WHEN 'C'       THEN _crmIdField := 'crmacct_cust_id';      _crmChildIdField := 'cust_id';
        WHEN 'V'       THEN _crmIdField := 'crmacct_vend_id';      _crmChildIdField := 'vend_id';
        WHEN 'EMP'     THEN _crmIdField := 'crmacct_emp_id';       _crmChildIdField := 'emp_id';
        WHEN 'PSPCT'   THEN _crmIdField := 'crmacct_prospect_id';  _crmChildIdField := 'prospect_id';
        WHEN 'SR'      THEN _crmIdField := 'crmacct_salesrep_id';  _crmChildIdField := 'salesrep_id';
        WHEN 'USR'     THEN _crmIdField := 'crmacct_usr_username'; _crmChildIdField := 'usr_username';
        WHEN 'TAXAUTH' THEN _crmIdField := 'crmacct_taxauth_id';   _crmChildIdField := 'taxauth_id';
      END CASE;

      _current := _current || ' UNION ALL ' ||
                  format(_docassQ,
                         _crm.source_number_field,
                         '$$' || _crm.source_docass || '$$', _crm.source_key_field,
                         'docass_source_type',      'docass_source_id',
                         _desc.source_name_field,
                         _desc.source_desc_field,   _desc.source_table,
                         _desc.source_key_field,    _desc.source_joins,
                         format('JOIN crmacct ON %s = %s', _crmIdField, _crmChildIdField),
                         _desc.source_docass,
                         'docass_source_type',      'docass_source_id',
                         '$$' || _crm.source_docass || '$$', _crm.source_key_field,
                         _desc.source_table,               _desc.source_key_field,
                         format('JOIN crmacct ON %s = %s', _crmIdField, _crmChildIdField),
                         _desc.source_docass);

    END IF;
  END LOOP;

  _current := 'WITH rev AS (' || _rev || ') ' || _current;

  FOR _row IN EXECUTE(_current) LOOP
    RETURN NEXT _row;
  END LOOP;

  RETURN;
END
$f$ LANGUAGE plpgsql;
