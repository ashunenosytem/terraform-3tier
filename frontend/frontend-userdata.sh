#!/bin/bash
set -ex

exec > /var/log/user-data.log 2>&1
echo "===== Frontend user-data started ====="

# ---- Install Docker & Git (NO yum update) ----
yum install -y docker git

systemctl start docker
systemctl enable docker

# Docker socket permission (Amazon Linux quirk)
chmod 666 /var/run/docker.sock || true

# ---- Clone application ----
cd /root
git clone https://github.com/Ashutosh-Ahirwar/ExpenseTracker.git
cd ExpenseTracker/frontend/expense-tracker

# ---- Use relative API paths ----
sed -i 's|https://expensetrackern.onrender.com||g' src/utils/apiPaths.js

# ---- NGINX CONFIG (backend IP from Terraform) ----
cat <<EOF > nginx.conf
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://${backend_private_ip}:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# ---- Dockerfile ----
cat <<'EOF' > Dockerfile
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# ---- Build & Run ----
docker build -t expense-frontend .

docker run -d \
  --restart always \
  --name expense-frontend \
  -p 80:80 \
  expense-frontend

echo "===== Frontend user-data completed ====="
