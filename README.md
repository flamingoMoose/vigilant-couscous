# Hyperledger Fabric Network Project

This repository contains a Hyperledger Fabric network configuration for cross-platform development (Windows, Mac, Linux).

## Prerequisites

- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Install Docker Compose](https://docs.docker.com/compose/install/)
- **Git**: [Install Git](https://git-scm.com/downloads)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd <your-repository-directory>
```

### 2. Install Hyperledger Fabric Binaries

Run the following script to download Fabric binaries and Docker images:

```bash
# For Mac/Linux
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.5 0.4.25

# For Windows (using PowerShell)
curl -sSL https://bit.ly/2ysbOFE -o bootstrap.sh
bash bootstrap.sh 2.5.0 1.5.5 0.4.25
```

This will create a `fabric-samples` directory with all required binaries.

### 3. Set Environment Variables

Create a `.env` file based on the sample provided:

```bash
cp .env.sample .env
# get from Yusri
```

### 4. Set Up Network

#### For Mac/Linux:

```bash
# Make the script executable
chmod +x scripts/setup-network.sh
# Run the setup script
./scripts/setup-network.sh
```

#### For Windows:

```powershell
# Run the PowerShell setup script
.\network-setup.ps1
```

### 5. Verify Network Status

#### For Mac/Linux:

```bash
# Run the status check script
./scripts/check-network.sh
```

#### For Windows:

```powershell
# Run the batch file for status check
.\network-status.bat
```

## Directory Structure

- `chaincode/`: Chaincode source code
- `configtx/`: Channel configuration files
- `docker/`: Docker Compose configuration
- `organizations/`: Organization definitions
- `scripts/`: Utility scripts

## Platform-Specific Notes

### Windows

- Use PowerShell for running scripts
- Avoid using Git Bash due to path translation issues
- WSL2 is recommended for better Docker performance

### Mac/Linux

- Ensure all scripts have execute permissions (`chmod +x scripts/*.sh`)
- Docker may require sudo privileges depending on your setup

## Troubleshooting

### Common Issues

1. **Docker Error: No space left on device**
   - Clear unused Docker volumes: `docker volume prune -f`
   - Clear unused images: `docker image prune -f`

2. **Path Issues in Windows**
   - Make sure paths use forward slashes (/) in configuration files
   - Avoid using spaces in directory paths

3. **Permission Issues on Mac/Linux**
   - Run `chmod -R 755 crypto-config` if you encounter permission errors

4. **Connection Errors**
   - Check if all containers are running: `docker ps`
   - Verify network connectivity: Run the network status script

### Getting Help

If you encounter any issues:
1. Check Docker logs: `docker logs <container-name>`
2. Run the network status script to verify all components are working

## License

