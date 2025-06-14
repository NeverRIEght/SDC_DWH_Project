docker exec -e \
PGPASSWORD="olap_password" \
olap \
bash -c \
'for f in /opt/etl_scripts/*.sql; \
do psql -h localhost -U olap_user -d olap_db -f "$f" || exit 1; done'