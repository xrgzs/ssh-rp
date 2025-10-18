# SSH-RP (SSH Reverse Proxy)

A SSH-based reverse proxy solution for secure port forwarding.

This project provides Docker containers for easy deployment. It is currently experimental. Do not use it in production.

## Prerequisites

Generate an SSH key pair for authentication:

```bash
ssh-keygen -t rsa -f ./id_rsa -N "" -C "sshrp"
```

You would get two files: `id_rsa` and `id_rsa.pub`. The `id_rsa` should be placed in the client side. And the `id_rsa.pub` should be placed on the server side.

## Server Setup

### Using Docker CLI

```bash
mkdir -p /opt/ssr-rp

cd /opt/ssr-rp

docker run -d \
  --name ssh-rp \
  --restart always \
  -p 2222:22 \
  -p 8080:8080 \
  -v ./id_rsa.pub:/home/sshrp/.ssh/authorized_keys \
  -v ./ssh-config:/etc/ssh \
  ghcr.io/xrgzs/ssh-rp:latest
```

### Using Docker Compose

```yaml
services:
  ssh-rp-server:
    image: ghcr.io/xrgzs/ssh-rp:latest
    container_name: ssh-rp-server
    restart: always
    ports:
      - "2222:22"
      - "8080:8080"
    volumes:
      - ./id_rsa.pub:/home/sshrp/.ssh/authorized_keys
      - ./ssh-config:/etc/ssh
```

## Client Setup

Forward local port `80` to remote port `8080` :

### Using SSH Command

Clients can reach internal network services (NAT traversal) with almost no extra software — SSH is built in.

Note: the command below disables SSH host key verification using two `-o` options. To avoid potential MITM attacks, remove those two `-o` options and ensure the server's SSH host key (public key) does not change.

```bash
ssh -N -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./id_rsa -R ":8080:127.0.0.1:80" -p 2222 "sshrp@ssh-rp-server"
```

### Using Docker Compose

```yaml
services:
  ssh-rp-client:
    image: ghcr.io/xrgzs/ssh-rp-client:latest
    container_name: ssh-rp-client
    restart: always
    network_mode: host
    command: >
      -N
      -o StrictHostKeyChecking=no
      -o UserKnownHostsFile=/dev/null
      -i /data/id_rsa
      -R ":8080:127.0.0.1:80"
      -p 2222
      "sshrp@ssh-rp-server"
    volumes:
      - ./id_rsa:/data/id_rsa
      - ./.ssh:/root/.ssh
```

## Testing

Verify the connection:

```bash
curl "ssh-rp-server:8080"
```
