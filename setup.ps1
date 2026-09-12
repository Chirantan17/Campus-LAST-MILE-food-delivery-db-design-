Write-Host "Starting PostGIS container..." -ForegroundColor Green
docker compose up -d

Write-Host "Waiting for PostgreSQL to accept connections..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "Applying Schema..." -ForegroundColor Green
Get-Content sql/01_schema.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Seeding Data..." -ForegroundColor Green
Get-Content sql/03_seed.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Executing Queries..." -ForegroundColor Green
Get-Content sql/02_queries.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Spatiotemporal Database Setup Complete!" -ForegroundColor Cyan