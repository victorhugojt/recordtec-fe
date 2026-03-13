BACKEND_HOST=10.10.1.4 docker run -d -p 80:80 --name recordtec-frontend --restart unless-stopped ghcr.io/victorhugojt/recordtec-fe:2a6f35c

gcloud compute instances add-metadata vm-backend \
  --zone=us-central1-a \
  --metadata=ssh-keys="victor.h.jimenez.t@gmail.com:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIs+SRMhTtERusZddV42WyPC1dIzdUkSsrI3lm58/hxJ victor.jimenez@vm-frontend"


gcloud compute ssh --zone "us-central1-a" "vm-frontend" --project "project-2c268745-0c2f-477a-b6a"


gcloud compute instances describe vm-frontend --zone=us-central1-a --format=json