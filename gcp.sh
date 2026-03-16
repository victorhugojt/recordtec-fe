#!/bin/bash
# GCP setup for recordtec: frontend (public) + backend (private) with NAT
# Run from your laptop. Edit variables as needed.
#
# Modes:
#   gcp.sh           - Full setup (network, NAT, firewall, frontend, backend)
#   gcp.sh backend  - Backend only (NAT + backend VM, keeps existing frontend)
#   gcp.sh teardown - Delete backend VM only (keeps frontend, NAT, network)

set -e

# --- Variables (edit as needed) ---
REGION=us-central1
ZONE=us-central1-a
VPC=my-poc-vpc
PUB_SUBNET=public-subnet
PRIV_SUBNET=private-subnet
PUB_RANGE=10.10.0.0/24
PRIV_RANGE=10.10.1.0/24
MY_PUBLIC_IP=181.58.39.222

# --- Teardown: backend only (keeps frontend) ---
if [[ "${1:-}" == "teardown" ]]; then
  echo ">>> Deleting backend VM only (frontend kept)..."
  gcloud compute instances delete vm-backend --zone=$ZONE --quiet 2>/dev/null || true
  echo ">>> Teardown complete."
  exit 0
fi

# --- Backend-only mode: NAT + backend (skips frontend) ---
BACKEND_ONLY=false
[[ "${1:-}" == "backend" ]] && BACKEND_ONLY=true

# --- 1. Network & Subnets (skip if backend-only) ---
if [[ "$BACKEND_ONLY" != "true" ]]; then
  echo ">>> Creating network and subnets..."
  gcloud compute networks create $VPC --subnet-mode=custom 2>/dev/null || true
  gcloud compute networks subnets create $PUB_SUBNET --network=$VPC --region=$REGION --range=$PUB_RANGE 2>/dev/null || true
  gcloud compute networks subnets create $PRIV_SUBNET --network=$VPC --region=$REGION --range=$PRIV_RANGE --enable-private-ip-google-access 2>/dev/null || true
fi

# --- 2. Cloud NAT (enables backend to reach internet for apt, docker) ---
echo ">>> Creating Cloud NAT for private subnet..."
gcloud compute routers create nat-router --network=$VPC --region=$REGION 2>/dev/null || true
gcloud compute routers nats create nat-config \
  --router=nat-router \
  --region=$REGION \
  --nat-custom-subnet-ip-ranges=$PRIV_SUBNET \
  --auto-allocate-nat-external-ips 2>/dev/null || true

# --- 3. Firewall Rules (skip if backend-only) ---
if [[ "$BACKEND_ONLY" != "true" ]]; then
  echo ">>> Creating firewall rules..."
  gcloud compute firewall-rules create ${VPC}-allow-internal \
    --network=$VPC --allow=tcp:0-65535,udp:0-65535,icmp --source-ranges=10.10.0.0/16 2>/dev/null || true
  gcloud compute firewall-rules create ${VPC}-allow-http \
    --network=$VPC --allow=tcp:80,tcp:443 --source-ranges=0.0.0.0/0 --target-tags=frontend 2>/dev/null || true
  [[ -z "$MY_PUBLIC_IP" ]] && { echo "Error: MY_PUBLIC_IP is not set"; exit 1; }
  gcloud compute firewall-rules create ${VPC}-allow-ssh \
    --network=$VPC --allow=tcp:22 --source-ranges="${MY_PUBLIC_IP}/32" --target-tags=admin-ssh 2>/dev/null || true
fi

# --- 4. Frontend VM (skip if backend-only) ---
if [[ "$BACKEND_ONLY" != "true" ]]; then
  echo ">>> Creating frontend VM..."
  gcloud compute instances create vm-frontend \
    --zone=$ZONE --machine-type=e2-micro --subnet=$PUB_SUBNET \
    --tags=frontend,admin-ssh --image-family=debian-11 --image-project=debian-cloud --boot-disk-size=10GB
fi

# --- 5. Backend VM (private subnet, no external IP, standard Debian) ---
echo ">>> Creating backend VM..."
gcloud compute instances create vm-backend \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=$PRIV_SUBNET \
  --no-address \
  --tags=backend,admin-ssh \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB

# --- Summary ---
echo ""
echo ">>> Done. Backend (internal) IP:"
echo "  gcloud compute instances describe vm-backend --zone=$ZONE --format=\"get(networkInterfaces[0].networkIP)\""
echo ""
echo "Add frontend's SSH key to backend, then restart:"
echo "  gcloud compute instances add-metadata vm-backend --zone=$ZONE --metadata=ssh-keys=\"USER:FRONTEND_PUBLIC_KEY\""
echo "  gcloud compute instances stop vm-backend --zone=$ZONE && gcloud compute instances start vm-backend --zone=$ZONE"


   ssh victor.h.jimenez.t@gmail.com@34.171.37.204

gcloud compute instances add-metadata vm-backend \
     --zone=us-central1-a \
     --metadata=ssh-keys="victor.h.jimenez.t@gmail.com:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINWHAPv9KcDZLTPnUK6P2C/6/uF1xZatCCj8MHzmWEf2 victor.h.jimenez.t@gmail.com@vm-frontend"


scp backend-image.tar victor.h.jimenez.t@gmail.com@10.10.1.4:/tmp/

curl http://10.10.1.4:8000/health

curl http://10.10.1.4:8000/generes

docker login ghcr.io -u victorhugojt -p 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

echo "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" | docker login ghcr.io -u victorhugojt --password-stdin