
SELECT dropIfExists('view', 'globaluomconv');
CREATE VIEW globaluomconv AS
  SELECT DISTINCT * FROM (
  SELECT 0                        AS itemuomconv_seq,
         itemuomconv_id           AS itemuomconv_id,
         itemuomconv_item_id      AS itemuomconv_item_id,
         itemuomconv_from_uom_id  AS itemuomconv_from_uom_id,
         itemuomconv_from_value   AS itemuomconv_from_value,
         itemuomconv_to_uom_id    AS itemuomconv_to_uom_id,
         itemuomconv_to_value     AS itemuomconv_to_value,
         itemuomconv_fractional   AS itemuomconv_fractional
  FROM itemuomconv
  UNION ALL
  SELECT 1                        AS itemuomconv_seq,
         uomconv_id               AS itemuomconv_id,
         NULL                     AS itemuomconv_item_id,
         uomconv_from_uom_id      AS itemuomconv_from_uom_id,
         uomconv_from_value       AS itemuomconv_from_value,
         uomconv_to_uom_id        AS itemuomconv_to_uom_id,
         uomconv_to_value         AS itemuomconv_to_value,
         uomconv_fractional       AS itemuomconv_fractional
  FROM uomconv
  WHERE (COALESCE(uomconv_global, FALSE))
  ) AS data
  ORDER BY itemuomconv_seq;

REVOKE ALL ON TABLE globaluomconv FROM PUBLIC;
GRANT  ALL ON TABLE globaluomconv TO GROUP xtrole;

COMMENT ON VIEW globaluomconv IS 'Union of itemuomconv and global uomconv for use by widgets and stored procedures';
