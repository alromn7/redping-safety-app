# Node.js Installation Commands for Linux

## For Ubuntu/Debian systems:
```bash
# Update package index
sudo apt update

# Install Node.js and npm
sudo apt install nodejs npm

# Verify installation
node --version
npm --version
```

## For CentOS/RHEL/Rocky Linux:
```bash
# Install Node.js and npm
sudo yum install nodejs npm
# OR for newer versions:
sudo dnf install nodejs npm

# Verify installation
node --version
npm --version
```

## For Amazon Linux:
```bash
# Install Node.js and npm
sudo yum install nodejs npm

# Verify installation
node --version
npm --version
```

## Alternative: Install Latest Version via NodeSource Repository

### Ubuntu/Debian:
```bash
# Download and install NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Install Node.js
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### CentOS/RHEL:
```bash
# Download and install NodeSource repository
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -

# Install Node.js
sudo yum install -y nodejs

# Verify installation
node --version
npm --version
```

## After Installation:
```bash
# Now you can run your original command
npm install --production

# Or if you need to install in a specific directory
cd /path/to/your/project
npm install --production
```

## Troubleshooting:
```bash
# Check if npm is in PATH
which npm
echo $PATH

# If npm is installed but not in PATH, you might need to:
export PATH=$PATH:/usr/bin
# Or wherever Node.js was installed

# Check Node.js installation location
whereis node
whereis npm
```