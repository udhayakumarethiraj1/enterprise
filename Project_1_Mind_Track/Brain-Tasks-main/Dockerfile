FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy Vite build output to nginx
COPY dist /usr/share/nginx/html

# Replace default nginx config inline
RUN printf '%s\n' \
'server {' \
'    listen 3000;' \
'    listen [::]:3000;' \
'    server_name localhost;' \
'' \
'    location / {' \
'        root /usr/share/nginx/html;' \
'        index index.html;' \
'        try_files $uri $uri/ /index.html;' \
'    }' \
'}' \
> /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000

# Run nginx
CMD ["nginx", "-g", "daemon off;"]

