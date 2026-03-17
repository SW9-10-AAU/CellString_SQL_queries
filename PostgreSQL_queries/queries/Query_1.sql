EXPLAIN (ANALYZE, BUFFERS)
SELECT
  n.nspname AS schema,
  o.oprname AS name,
  pg_catalog.pg_get_function_identity_arguments(o.oprcode) AS signature,
  o.oprleft::regtype AS leftarg,
  o.oprright::regtype AS rightarg
FROM pg_operator o
JOIN pg_namespace n ON n.oid = o.oprnamespace
WHERE o.oprname = '&&';
