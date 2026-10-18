FROM nginx:latest

ARG NGINX_CONFIG=default.conf

COPY index.html /usr/share/nginx/html/index.html
COPY ${NGINX_CONFIG} /etc/nginx/conf.d/default.conf
