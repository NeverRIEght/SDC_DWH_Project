docker exec ^
  -e PGPASSWORD="oltp_password" ^
  oltp ^
  bash -c "for f in /opt/etl_scripts/*.sql; do psql -h localhost -U oltp_user -d oltp_db -f \"$f\" || exit 1; done"