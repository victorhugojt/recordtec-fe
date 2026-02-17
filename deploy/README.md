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

## Network Checklist

- [ ] VPC created with public and private subnets
- [ ] Frontend VM has external IP (or use Cloud NAT for outbound)
- [ ] Firewall: allow ingress 80 (HTTP) to frontend VM
- [ ] Firewall: allow ingress 8000 from frontend VM's subnet to backend VM (or use VPC internal firewall rules)
- [ ] Backend VM has no external IP (private only)
