CREATE OR REPLACE FUNCTION xt.parsemetasql(metasql text, options text default '{}')
  RETURNS text AS
$BODY$

  var sql = '';

  /**
   * Call the parser with this functions parameters.
   */
  try {
    sql += XT.MetaSQL.parser.parse(metasql, JSON.parse(options));
  } catch (err) {
    plv8.elog(ERROR, 'Cannot parse MetaSQL. ERROR: ', err);
  }

  return sql;
$BODY$
  LANGUAGE plv8;