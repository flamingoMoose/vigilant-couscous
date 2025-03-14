cd explorer 

docker compose -f explorer/docker-compose.yaml up -d

docker compose logs -f explorer.mynetwork.com

Write-Host "Once logs looks fine, run http://localhost:8080 to access the Hyperledger Fabric Explorer" -ForegroundColor Blue
Write-Host "username: exploreradmin"
Write-Host "password: exploreradminpw"