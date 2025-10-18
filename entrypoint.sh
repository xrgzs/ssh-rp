#!/bin/sh
set -e

# ============================================================
# SSH Reverse Proxy Server Initialization Script
# ============================================================

# ------------------------------------------------------------
# Generate SSH Host Keys
# ------------------------------------------------------------
generate_host_keys() {
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        echo "[INFO] Generating SSH host keys..."
        ssh-keygen -A
        echo "[INFO] Host keys generated successfully"
    else
        echo "[INFO] SSH host keys already exist"
    fi
    
    # Ensure proper permissions
    chmod 600 /etc/ssh/ssh_host_* 2>/dev/null || true
}

# ------------------------------------------------------------
# Configure SSH Server
# ------------------------------------------------------------
configure_sshd() {
    if [ -f /etc/ssh/sshd_config.configured ]; then
        echo "[INFO] SSH server already configured"
        return
    fi
    
    echo "[INFO] Configuring SSH server..."
    
    # Backup original configuration
    [ -f /etc/ssh/sshd_config ] && \
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    # Create secure configuration
    cat > /etc/ssh/sshd_config << 'EOF'
# Logging
LogLevel VERBOSE

# Network
Port 22
AddressFamily any

# Authentication
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3

# Port Forwarding
AllowTcpForwarding yes
GatewayPorts yes
PermitTunnel no

# Security - Disable Interactive Access
PermitTTY no
X11Forwarding no
AllowAgentForwarding no
PermitUserEnvironment no
ForceCommand /bin/false

# Session Management
ClientAliveInterval 60
ClientAliveCountMax 3
MaxSessions 10
EOF
    
    chmod 600 /etc/ssh/sshd_config
    touch /etc/ssh/sshd_config.configured
    
    echo "[INFO] SSH server configured successfully"
}

# ------------------------------------------------------------
# Validate Authorized Keys
# ------------------------------------------------------------
validate_authorized_keys() {
    local auth_keys="/home/sshrp/.ssh/authorized_keys"
    
    if [ ! -f "$auth_keys" ]; then
        echo "[WARNING] No authorized_keys file found at $auth_keys"
        echo "[WARNING] Please mount your public key to $auth_keys"
        return 1
    fi
    
    echo "[INFO] Found authorized_keys at $auth_keys"
    
    # Attempt to set permissions if writable
    if [ -w "$auth_keys" ]; then
        if chmod 600 "$auth_keys" 2>/dev/null; then
            echo "[INFO] Permissions set to 600 on $auth_keys"
        else
            echo "[WARNING] Failed to set permissions on $auth_keys"
        fi
    else
        echo "[INFO] File is read-only (mounted with :ro flag)"
    fi
}

# ------------------------------------------------------------
# Start SSH Daemon
# ------------------------------------------------------------
start_sshd() {
    echo "[INFO] Testing SSH server configuration..."
    if ! /usr/sbin/sshd -t; then
        echo "[ERROR] SSH configuration test failed"
        exit 1
    fi
    
    echo "[INFO] Starting SSH server..."
    exec /usr/sbin/sshd -D -e
}

# ============================================================
# Main Execution
# ============================================================
main() {
    generate_host_keys
    configure_sshd
    validate_authorized_keys
    start_sshd
}

main "$@"