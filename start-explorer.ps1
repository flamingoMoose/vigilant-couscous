docker-compose -f explorer/docker-compose.yaml up -d

docker-compose logs -f explorer.mynetwork.com

Write-Host "Once logs looks fine, run http://localhost:8080 to access the Hyperledger Fabric Explorer"
Write-Host "id: exploreradmin\npassword: exploreradminpw"