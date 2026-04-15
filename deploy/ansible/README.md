# Deploying recordtec-fe with Ansible

This repo does **not** embed the backend IP. Pass it at deploy time.

## Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `recordtec_backend_host` | Private IP or DNS of the API VM | `10.10.1.4` |
| `recordtec_backend_port` | API port | `8000` (default in template) |

Set in `group_vars/all.yml`, `host_vars/`, or extra vars.

---

## Option A: Docker image (recommended)

The image reads **`BACKEND_HOST`** and **`BACKEND_PORT`** at container start (see `deploy/nginx.conf.template` + `deploy/docker-entrypoint.sh`).

```yaml
# Example task — adapt module names to your collection (community.docker, etc.)
- name: Run recordtec frontend container
  community.docker.docker_container:
    name: recordtec-frontend
    image: "ghcr.io/{{ github_owner }}/recordtec-fe:{{ recordtec_image_tag | default('latest') }}"
    state: started
    restart_policy: unless-stopped
    ports:
      - "80:80"
    env:
      BACKEND_HOST: "{{ recordtec_backend_host }}"
      BACKEND_PORT: "{{ recordtec_backend_port | default('8000') | string }}"
```

Pull the image first (login to GHCR if private):

```yaml
- name: Log in to GHCR
  community.docker.docker_login:
    registry_url: ghcr.io
    username: "{{ ghcr_username }}"
    password: "{{ ghcr_token }}"
```

---

## Option B: Static files + Nginx on the VM (no Docker)

1. Build or copy `dist/` to `/var/www/recordtec-fe` on the frontend VM.
2. Render `deploy/ansible/templates/nginx-recordtec.conf.j2` to `/etc/nginx/sites-available/recordtec` and enable the site.

```yaml
- name: Nginx site for recordtec-fe
  ansible.builtin.template:
    src: nginx-recordtec.conf.j2   # copy template into your Ansible role, or use files from a checkout
    dest: /etc/nginx/sites-available/recordtec
    mode: "0644"
  notify: Reload nginx
```

Path note: copy `nginx-recordtec.conf.j2` into your Ansible repo (e.g. `roles/recordtec-fe/templates/`) or reference this repo as a submodule and point `src` to the file under `files/`.

---

## Local / Compose

Use a `.env` file (see `.env.example` in the project root) or:

```bash
export BACKEND_HOST=10.10.1.4
docker compose up -d --build
```

---

## Summary

| Deploy | How backend is set |
|--------|--------------------|
| Docker | `-e BACKEND_HOST=...` or `env:` in Ansible |
| Compose | `.env` or `environment:` with `BACKEND_HOST` |
| Host Nginx | Jinja vars `recordtec_backend_host` / `recordtec_backend_port` |
