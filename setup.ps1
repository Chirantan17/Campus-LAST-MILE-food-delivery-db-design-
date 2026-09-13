Write-Host "Starting PostGIS container..." -ForegroundColor Green
docker compose up -d

Write-Host "Waiting for PostgreSQL to accept connections..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Applying Schema..." -ForegroundColor Green
Get-Content sql/01_schema.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Seeding Data..." -ForegroundColor Green
Get-Content sql/02_seed.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Executing M4 Spatiotemporal Queries..." -ForegroundColor Green
Get-Content sql/03_spatiotemporal_queries.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Executing M5 Performance Analysis..." -ForegroundColor Green
Get-Content sql/05_performance.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Executing M6 Investigation Queries..." -ForegroundColor Green
Get-Content sql/06_investigation.sql | docker exec -i campus_spatial_db psql -U postgres -d campus_delivery

Write-Host "Spatiotemporal Database Pipeline Complete!" -ForegroundColor Cyan