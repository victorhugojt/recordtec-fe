# Backend VM Setup – Step-by-Step Guide

Backend VM with Debian, Cloud NAT (for apt/docker), and SSH from frontend.

---

## Quick Start (Frontend Already Running)

**From your laptop** — keeps your existing frontend with Nginx:

```bash
# 1. Delete old backend (if any)
./gcp.sh teardown

# 2. Create NAT + backend only (frontend untouched)
./gcp.sh backend
```

---

## gcp.sh Modes

| Command | What it does |
|---------|--------------|
| `./gcp.sh backend` | NAT + backend VM only. **Keeps frontend.** |
| `./gcp.sh teardown` | Delete backend VM only. **Keeps frontend.** |
| `./gcp.sh` | Full setup (network, NAT, firewall, frontend, backend) |

---

## What `./gcp.sh backend` Creates

| Resource | Purpose |
|----------|---------|
| **Cloud NAT** | Backend can reach internet (apt, docker pull) |
| **vm-backend** | Debian, private subnet, no external IP |

---

## After gcp.sh: Add SSH Key to Backend

1. **Get backend IP:**
   ```bash
   gcloud compute instances describe vm-backend --zone=us-central1-a --format="get(networkInterfaces[0].networkIP)"
   ```

2. **Add frontend's key** (so frontend can SCP/SSH to backend):
   - On frontend: `cat ~/.ssh/id_ed25519.pub` (create with `ssh-keygen` if needed)
   - From laptop:
   ```bash
   gcloud compute instances add-metadata vm-backend \
     --zone=us-central1-a \
     --metadata=ssh-keys="victor.h.jimenez.t@gmail.com:PASTE_FRONTEND_PUBLIC_KEY"
   ```

3. **Restart backend** (metadata applies at boot):
   ```bash
   gcloud compute instances stop vm-backend --zone=us-central1-a
   gcloud compute instances start vm-backend --zone=us-central1-a
   ```

4. **Test SSH from frontend:**
   ```bash
   ssh victor.h.jimenez.t@gmail.com@<BACKEND_IP>
   ```

---

## Install Docker on Backend

**On the backend VM** (after SSH from frontend). NAT provides internet access:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

**Verify:** `docker --version`

---

## Troubleshooting

| Issue | Check |
|-------|-------|
| `Permission denied (publickey)` | Add the **frontend's** key (from `cat ~/.ssh/id_ed25519.pub` on frontend) |
| Backend can't reach internet | NAT takes a few minutes. Check: `gcloud compute routers nats list --router=nat-router --region=us-central1` |
| Wrong backend IP | `gcloud compute instances describe vm-backend --zone=us-central1-a --format="get(networkInterfaces[0].networkIP)"` |
