FROM alpine:3

# Install OpenSSH and required tools
RUN apk add --no-cache openssh-server shadow && \
    rm -rf /var/cache/apk/*

# Create required directories and non-root user 'sshrp'
# The sshd daemon must still run as root in the container to bind port 22,
# but we'll disable root login and use the 'sshrp' user for SSH access.
RUN mkdir -p /run/sshd && \
    adduser -D -h /home/sshrp -s /bin/false sshrp && \
    mkdir -p /home/sshrp/.ssh && \
    chown -R sshrp:sshrp /home/sshrp && \
    chmod 700 /home/sshrp/.ssh

# Note: SSH host keys and configuration will be generated at runtime by entrypoint.sh
# to ensure each container has unique keys and allow dynamic configuration

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

# Use entrypoint to generate keys at runtime and start sshd
ENTRYPOINT ["/entrypoint.sh"]