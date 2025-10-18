# SSH-RP (SSH Reverse Proxy)

A SSH-based reverse proxy solution for secure port forwarding.

## Prerequisites

Generate an SSH key pair for authentication:

```bash
ssh-keygen -t rsa -f ./id_rsa -N "" -C "sshrp"
```

## Server Setup

### Using Docker CLI

```bash
docker run -d \
  --name ssh-rp \
  --restart always \
  -p 2222:22 \
  -p 8080:8080 \
  -v ./id_rsa.pub:/home/sshrp/.ssh/authorized_keys:ro \
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
      - ./id_rsa.pub:/home/sshrp/.ssh/authorized_keys:ro
      - ./ssh-config:/etc/ssh
```

## Client Setup

Forward local port `80` to remote port `8080` :

### Using SSH Command

```bash
ssh -N -f -L "8080:localhost:80" -p 2222 "sshrp@ssh-rp-server"
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
      -i /data/id_rsa
      -L ":8080:127.0.0.1:80"
      -p 2222
      "sshrp@ssh-rp-server"
    volumes:
      - ./id_rsa:/data/id_rsa:ro
```

## Testing

Verify the connection:

```bash
curl "ssh-rp-server:8080"
```
