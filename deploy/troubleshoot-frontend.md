# Frontend VM Troubleshooting – Step by Step

VM public IP: `35.208.57.254`

---

## Step 1: Is the container running?

**On the frontend VM:**

```bash
docker ps
```

**Expected:** `recordtec-frontend` listed with status `Up`.

**If not running:**
```bash
docker ps -a
docker logs recordtec-frontend
```

---

## Step 2: Does it respond locally on the VM?

**On the frontend VM:**

```bash
curl -I http://localhost:80
```

**Expected:** `HTTP/1.1 200 OK` or `HTTP/1.1 304`.

**If port 80:**
```bash
curl -I http://localhost:8080
```

---

## Step 3: Which port is the container using?

**On the frontend VM:**

```bash
docker port recordtec-frontend
```

**Expected:** `80/tcp -> 0.0.0.0:80` or `80/tcp -> 0.0.0.0:8080`.

---

## Step 4: GCP firewall – is port 80 allowed?

**From your laptop:**

```bash
gcloud compute firewall-rules list --filter="allowed.ports:80"
```

**Expected:** A rule allowing `tcp:80` from `0.0.0.0/0` to the frontend.

**If missing, create:**
```bash
gcloud compute firewall-rules create allow-http \
  --network=my-poc-vpc \
  --allow=tcp:80,tcp:8080 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=frontend
```

---

## Step 5: Does the VM have the firewall target tag?

**From your laptop:**

```bash
gcloud compute instances describe vm-frontend --zone=us-central1-a --format="get(tags.items)"
```

**Expected:** `frontend` in the list.

**If missing:**
```bash
gcloud compute instances add-tags vm-frontend --zone=us-central1-a --tags=frontend
```

---

## Step 6: Test from your laptop

```bash
curl -I http://35.208.57.254
```

**If using port 8080:**
```bash
curl -I http://35.208.57.254:8080
```

---

## Step 7: Try in the browser

- **Port 80:** http://35.208.57.254  
- **Port 8080:** http://35.208.57.254:8080  

Use `http://` (not `https://`).
