CREATE OR REPLACE FUNCTION _docinfo() RETURNS SETOF _docinfo AS $f$
-- Copyright (c) 1999-2015 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
-- Return all document associations, optionally limited to the given document type
DECLARE
  _current      TEXT := '';
  _row          _docinfo%rowtype;
  _desc         record;

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

  FOR _desc IN SELECT source.*
                 FROM source
                 JOIN pg_class c on source_table = relname
                 JOIN pg_namespace n on relnamespace = n.oid
                 JOIN regexp_split_to_table(buildSearchPath(), E',\\s*') sp
                      on nspname = sp
                WHERE relkind = 'r'
  LOOP
    _current := _current || ' UNION ALL ' ||
                format($$SELECT docass_id AS id,
                                %s AS target_number,
                                docass_target_type AS target_type,
                                docass_target_id AS target_id,
                                docass_source_type AS source_type,
                                docass_source_id AS source_id,
                                %s AS name, %s AS description,
                                docass_purpose AS purpose
                           FROM docass JOIN %s ON docass_target_id = %s
                           %s
                          WHERE docass_target_type = '%s'
                         UNION ALL
                         SELECT docass_id AS id,
                                %s AS target_number,
                                docass_source_type AS target_type,
                                docass_source_id AS target_id,
                                docass_target_type AS source_type,
                                docass_target_id AS source_id,
                                %s AS name, %s AS description,
                                CASE 
                                  WHEN docass_purpose = 'A' THEN 'C'
                                  WHEN docass_purpose = 'C' THEN 'A'
                                  ELSE docass_purpose
                                END AS purpose
                           FROM docass JOIN %s ON docass_source_id = %s
                           %s
                          WHERE docass_source_type = '%s'
                       $$,
                       _desc.source_number_field, _desc.source_name_field, _desc.source_desc_field, _desc.source_table, _desc.source_key_field, _desc.source_joins, _desc.source_name,
                       _desc.source_number_field, _desc.source_name_field, _desc.source_desc_field, _desc.source_table, _desc.source_key_field, _desc.source_joins, _desc.source_name);
  END LOOP;

  FOR _row IN EXECUTE(_current) LOOP
    RETURN NEXT _row;
  END LOOP;

  RETURN;
END
$f$ LANGUAGE plpgsql;
