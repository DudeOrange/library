#!/bin/bash



docker exec postgres_db psql -U user -d postgres -c "alter system set logging_collector = 'on';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_rotation_size = '10MB';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_truncate_on_rotation = 'on';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_connections = 'on';"
docker exec postgres_db psql -U user -d postgres -c "alter system set log_disconnections = 'on';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_statement = 'all';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_line_prefix = '%t; %u; %r; %%';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_min_messages = 'info';"

docker exec postgres_db psql -U user -d postgres -c "alter system set log_min_duration_statement = '2000';"

echo "All configured"


