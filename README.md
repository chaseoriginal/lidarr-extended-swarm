# lidarr-extended-swarm

Music track identification and management for Plex libraries.

## Stack

- **Host**: ore-dock-110-1
- **Stack**: `lidarr-extended-swarm`
- **Image**: linuxserver/lidarr:nightly
- **Config**: named volumes `lidarr.config`, `lidarr.custom-services`, `lidarr.custom-cont-init.d`

## Ports

| Port | Published | Protocol |
|------|----------|----------|
| 8686 | 8686 | TCP |

## Deploy

```bash
ssh ore-dock-110-1
cd /data/compose/lidarr-extended-swarm
set -a && source .env && docker stack deploy -c docker-compose.yml --with-registry-auth lidarr-extended-swarm && set +a
```
