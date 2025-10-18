#!/bin/sh
set -e

# Generate host keys if they don't exist (first run)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

# Ensure proper permissions on host keys
chmod 600 /etc/ssh/ssh_host_* 2>/dev/null || true

# Generate sshd_config if it doesn't exist or is the default
if [ ! -f /etc/ssh/sshd_config.configured ]; then
    echo "Configuring SSH server..."
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null || true
    
    # Create secure sshd configuration
    cat > /etc/ssh/sshd_config << 'EOF'
LogLevel VERBOSE

# Network
Port 22
AddressFamily any

# Authentication
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
AuthorizedKeysFile      .ssh/authorized_keys

# Forwarding
AllowTcpForwarding yes
GatewayPorts yes
PermitTunnel no

# Security - Disable interactive access
PermitTTY no
X11Forwarding no
AllowAgentForwarding no
PermitUserEnvironment no

# Force command to prevent shell access
ForceCommand /bin/false

# Session
ClientAliveInterval 60
ClientAliveCountMax 3
MaxAuthTries 3
MaxSessions 10
EOF
    
    # Set proper permissions
    chmod 600 /etc/ssh/sshd_config
    
    # Mark as configured
    touch /etc/ssh/sshd_config.configured
fi

# Check if authorized_keys exists at /home/sshrp/.ssh/authorized_keys
if [ -f /home/sshrp/.ssh/authorized_keys ]; then
    echo "Found authorized_keys at /home/sshrp/.ssh/authorized_keys"
    # Note: If mounted as read-only, SSH will still work as long as permissions are correct
    # SSH requires the file to be readable by root (since sshd runs as root)
    # We only warn if we can't verify permissions, but don't fail
    if [ -w /home/sshrp/.ssh/authorized_keys ]; then
        echo "Set permissions on /home/sshrp/.ssh/authorized_keys"
        if ! chmod 600 /home/sshrp/.ssh/authorized_keys; then
            echo "WARNING: Failed to set permissions on /home/sshrp/.ssh/authorized_keys"
        fi
    else
        echo "Note: /home/sshrp/.ssh/authorized_keys is read-only (mounted with :ro flag)"
    fi
else
    echo "WARNING: No authorized_keys file found at /home/sshrp/.ssh/authorized_keys"
    echo "Please mount your public key to /home/sshrp/.ssh/authorized_keys"
fi

# Test sshd configuration
echo "Testing sshd configuration..."
/usr/sbin/sshd -t

# Start sshd
echo "Starting SSH server..."
exec /usr/sbin/sshd -D -e
