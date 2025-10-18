FROM alpine:3

# Install OpenSSH and configure user in a single layer
RUN apk add --no-cache openssh-server && \
    mkdir -p /run/sshd /home/sshrp/.ssh && \
    adduser -D -h /home/sshrp -s /bin/false sshrp && \
    passwd -u sshrp && \
    chown -R sshrp:sshrp /home/sshrp && \
    chmod 700 /home/sshrp/.ssh

# Note: SSH host keys and configuration will be generated at runtime by entrypoint.sh
# to ensure each container has unique keys and allow dynamic configuration

# Copy and configure entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

# Use entrypoint to generate keys at runtime and start sshd
ENTRYPOINT ["/entrypoint.sh"]