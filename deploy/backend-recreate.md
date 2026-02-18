# Recreate Backend VM – Step-by-Step (Learning Guide)

Run each step from your laptop. Validate before moving to the next.

---

## Step 1: Verify Network Exists

```bash
gcloud compute networks list --filter="name=my-poc-vpc"
```

**Expected:** One row with `my-poc-vpc`. If empty, the VPC was deleted — you’d need to recreate it (not covered here).

---

## Step 2: Verify Private Subnet Exists

```bash
gcloud compute networks subnets list --network=my-poc-vpc --filter="name=private-subnet"
```

**Expected:** One row with `private-subnet` in region `us-central1`.

---

## Step 3: Create Cloud NAT (if not exists)

```bash
# Create router (required for NAT)
gcloud compute routers create nat-router \
  --network=my-poc-vpc \
  --region=us-central1
```

**If you see:** `Already exists` — skip and continue.

**Validate:**
```bash
gcloud compute routers list --filter="name=nat-router"
```

---

## Step 4: Add NAT Configuration

```bash
gcloud compute routers nats create nat-config \
  --router=nat-router \
  --region=us-central1 \
  --nat-custom-subnet-ip-ranges=private-subnet \
  --auto-allocate-nat-external-ips
```

**If you see:** `Already exists` — skip and continue.

**Validate:**
```bash
gcloud compute routers nats list --router=nat-router --region=us-central1
```

**Expected:** One row with `nat-config` and status `RUNNING`.

---

## Step 5: Verify Firewall Rules

```bash
gcloud compute firewall-rules list --filter="network:my-poc-vpc" --format="table(name,allowed,sourceRanges)"
```

**Expected:** Rules including:

- `my-poc-vpc-allow-internal` — allows traffic within `10.10.0.0/16`
- `my-poc-vpc-allow-http` — allows HTTP/HTTPS to frontend
- `my-poc-vpc-allow-ssh` — allows SSH from your IP

**If `allow-internal` is missing:**

```bash
gcloud compute firewall-rules create my-poc-vpc-allow-internal \
  --network=my-poc-vpc \
  --allow=tcp:0-65535,udp:0-65535,icmp \
  --source-ranges=10.10.0.0/16
```

**Validate:**

```bash
gcloud compute firewall-rules describe my-poc-vpc-allow-internal
```

---

## Step 6: Create Backend VM

```bash
gcloud compute instances create vm-backend \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --subnet=private-subnet \
  --no-address \
  --tags=backend \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB
```

**Validate:**

```bash
gcloud compute instances list --filter="name=vm-backend"
```

**Expected:** One row with `vm-backend` and status `RUNNING`.

---

## Step 7: Get Backend Private IP

```bash
gcloud compute instances describe vm-backend \
  --zone=us-central1-a \
  --format="get(networkInterfaces[0].networkIP)"
```

**Expected:** `10.10.1.x` (e.g. `10.10.1.2`). Save this IP.

---

## Step 8: Add Frontend SSH Key to Backend

**8a. On the frontend VM**, get the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

If missing, create it:

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Copy the full line (starts with `ssh-ed25519`).

**8b. On your laptop**, add it to the backend (replace `PASTE_KEY_HERE` with that line):

```bash
gcloud compute instances add-metadata vm-backend \
  --zone=us-central1-a \
  --metadata=ssh-keys="victor.h.jimenez.t@gmail.com:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqxyuxHXSObMNo8Zzy9l9+DvRQJ/wJBw7kPvthQGny7 victor.jimenez@LATAM-9QYQM0.local"
```

**Validate:**

```bash
gcloud compute instances describe vm-backend \
  --zone=us-central1-a \
  --format="yaml(metadata.items)"
```

**Expected:** `ssh-keys` entry with your key.

---

## Step 9: Restart Backend (metadata applies at boot)

```bash
gcloud compute instances stop vm-backend --zone=us-central1-a
gcloud compute instances start vm-backend --zone=us-central1-a
```

**Wait 60 seconds**, then validate:

```bash
gcloud compute instances list --filter="name=vm-backend"
```

**Expected:** Status `RUNNING`.

---

## Step 10: Test SSH from Frontend to Backend

**On the frontend VM** (SSH from laptop first):

```bash
ssh victor.h.jimenez.t@gmail.com@10.10.1.4
```

Replace `<BACKEND_IP>` with the IP from Step 7.

**Expected:** Shell prompt on the backend.

---

## Step 11: Install Docker on Backend

**On the backend VM** (after SSH from frontend):

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

**Validate:**

```bash
docker --version
```

---

## Troubleshooting

| Issue | Check |
|-------|-------|
| `Permission denied (publickey)` | Ensure you added the **frontend’s** key, not your laptop’s. Restart backend after adding metadata. |
| `apt` fails (no internet) | Ensure NAT is running. Wait a few minutes after creating NAT. |
| Wrong backend IP | Re-run Step 7 to get the current IP. |
