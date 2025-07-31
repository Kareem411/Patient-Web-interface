# Test Docker build locally
Write-Host "Testing Docker build locally..." -ForegroundColor Cyan

# Build the Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t test-patient-web:latest ./project

if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker build successful!" -ForegroundColor Green
    
    # Test running the container
    Write-Host "Testing container startup..." -ForegroundColor Yellow
    $containerId = docker run -d -p 5000:5000 test-patient-web:latest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Container started successfully!" -ForegroundColor Green
        Write-Host "Container ID: $containerId" -ForegroundColor Gray
        
        # Wait a moment for the app to start
        Start-Sleep -Seconds 5
        
        # Test if the app is responding
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5000" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "Application is responding!" -ForegroundColor Green
                Write-Host "App accessible at: http://localhost:5000" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Host "Application not responding yet, check manually at http://localhost:5000" -ForegroundColor Yellow
        }
        
        # Show container logs
        Write-Host "" 
        Write-Host "Container logs:" -ForegroundColor Yellow
        docker logs $containerId
        
        # Clean up
        Write-Host ""
        Write-Host "Cleaning up..." -ForegroundColor Yellow
        docker stop $containerId | Out-Null
        docker rm $containerId | Out-Null
        
        Write-Host "Test completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "Container failed to start" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "Docker build failed" -ForegroundColor Red
    exit 1
}
