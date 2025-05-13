FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

n# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

FROM nginx:alpine

WORKDIR /usr/share/nginx/html

# Copy static files
COPY index.html .
COPY login.html .
COPY register.html .
COPY reset-password.html .
COPY style.css .
COPY auth.js .

# Copy Nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]