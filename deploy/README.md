# GCP Deployment Guide

## Architecture

- **Public subnet**: VM with Nginx + Vue frontend (this app)
- **Private subnet**: VM with Docker + backend

## Frontend VM (Public Subnet) – Manual Nginx

### Files to Upload

Upload the **contents of the `dist/` folder** (built output) to the VM. Do not upload the full project.

**Build locally first:**
```bash
npm run build
```

This creates `dist/` with:
- `index.html`
- `assets/` (JS and CSS bundles)

### Deployment Steps

1. **Build the app** (on your machine):
   ```bash
   npm run build
   ```

2. **Copy files to the VM** (replace with your VM's external IP or hostname):
   ```bash
   scp -r dist/* user@<FRONTEND_VM_IP>:/tmp/recordtec-fe/
   ```

3. **On the frontend VM**, install Nginx and set up:
   ```bash
   sudo apt update
   sudo apt install -y nginx
   sudo mkdir -p /var/www/recordtec-fe
   sudo cp -r /tmp/recordtec-fe/* /var/www/recordtec-fe/
   sudo chown -R www-data:www-data /var/www/recordtec-fe
   ```

4. **Copy and customize the Nginx config**:
   - Edit `deploy/nginx.conf` and replace `10.0.1.10` with your backend VM's **private IP**
   - Copy to the VM:
     ```bash
     scp deploy/nginx.conf user@<FRONTEND_VM_IP>:/tmp/
     ```
   - On the VM:
     ```bash
     sudo cp /tmp/nginx.conf /etc/nginx/sites-available/recordtec
     sudo ln -sf /etc/nginx/sites-available/recordtec /etc/nginx/sites-enabled/
     sudo rm -f /etc/nginx/sites-enabled/default
     sudo nginx -t && sudo systemctl reload nginx
     ```

### Nginx Config Notes

- **Backend IP**: Update `proxy_pass http://10.0.1.10:8000/` in `deploy/nginx.conf` with your backend VM's private IP and port
- **Port**: Backend uses port 8000 by default; change if your backend listens on another port

---

## Alternative: Docker Compose

See `docker-compose.yml` and `Dockerfile` for containerized deployment.

---

## Backend VM (Private Subnet)

- Deploy your backend with Docker as planned
- Ensure the backend listens on `0.0.0.0` (not just 127.0.0.1) so it accepts connections from the frontend VM
- The frontend VM must have network connectivity to the backend VM's private IP (same VPC)

## Firewall Rules (Detailed)

GCP firewall rules are **stateful** and apply to VMs by **network tag** or **target**. By default, GCP allows all egress and blocks most ingress. You need to explicitly allow:

### Rule 1: Allow HTTP to Frontend VM (Public Access)

| Field | Value |
|-------|-------|
| **Name** | `allow-http-frontend` |
| **Direction** | Ingress |
| **Action** | Allow |
| **Target** | All instances in network, or use tag `frontend` |
| **Source** | `0.0.0.0/0` (any IP on the internet) |
| **Protocol/Port** | `tcp:80` |

**Purpose:** Lets users reach the app via `http://<VM_IP>`.

**Create via gcloud:**
```bash
gcloud compute firewall-rules create allow-http-frontend \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0
```

**Create via Console:** VPC network → Firewall → Create firewall rule → Ingress, TCP 80, Source 0.0.0.0/0.

---

### Rule 2: Allow SSH to Frontend VM (Optional, for Admin)

| Field | Value |
|-------|-------|
| **Name** | `allow-ssh` |
| **Direction** | Ingress |
| **Action** | Allow |
| **Target** | All instances, or tag `frontend` |
| **Source** | `0.0.0.0/0` or your IP only (recommended) |
| **Protocol/Port** | `tcp:22` |

**Purpose:** SSH into the frontend VM for admin and deployment.

**Create via gcloud:**
```bash
gcloud compute firewall-rules create allow-ssh \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=0.0.0.0/0
```

**Security tip:** Restrict `source-ranges` to your IP only (e.g. `--source-ranges=YOUR_IP/32`).

---

### Rule 3: Allow Backend Port from Frontend VM Only

| Field | Value |
|-------|-------|
| **Name** | `allow-backend-from-frontend` |
| **Direction** | Ingress |
| **Action** | Allow |
| **Target** | All instances, or tag `backend` |
| **Source** | Public subnet CIDR (e.g. `10.0.1.0/24`) |
| **Protocol/Port** | `tcp:8000` |

**Purpose:** Only the frontend VM can reach the backend on port 8000. Internet cannot reach the backend directly.

**Create via gcloud:**
```bash
gcloud compute firewall-rules create allow-backend-from-frontend \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:8000 \
  --source-ranges=10.0.1.0/24
```

Replace `10.0.1.0/24` with your public subnet CIDR.

---

### Rule 4: Allow SSH to Backend VM (Optional)

If the backend VM has no external IP, you typically reach it via SSH tunneling (e.g. through a bastion host or IAP). If you use a bastion in the public subnet:

| Field | Value |
|-------|-------|
| **Name** | `allow-ssh-to-backend` |
| **Direction** | Ingress |
| **Action** | Allow |
| **Target** | Tag `backend` |
| **Source** | Public subnet CIDR `10.0.1.0/24` |
| **Protocol/Port** | `tcp:22` |

**Purpose:** SSH into the backend VM from the frontend VM (or bastion host).

---

### Summary

| Rule | Purpose |
|------|---------|
| `allow-http-frontend` | Internet → Frontend VM:80 |
| `allow-ssh` | Internet → Frontend VM:22 (optional) |
| `allow-backend-from-frontend` | Frontend subnet → Backend VM:8000 |
| `allow-ssh-to-backend` | Frontend subnet → Backend VM:22 (optional) |

**Default behavior:** GCP allows all egress and blocks ingress unless a rule allows it. These rules open only the ports you need.

---

## Network Checklist

- [ ] VPC created with public and private subnets
- [ ] Frontend VM has external IP (or use Cloud NAT for outbound)
- [ ] Firewall: allow ingress 80 (HTTP) to frontend VM
- [ ] Firewall: allow ingress 8000 from frontend subnet to backend VM
- [ ] Firewall: allow SSH (22) if you need remote access
- [ ] Backend VM has no external IP (private only)
