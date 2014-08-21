server {
  listen 80;
  index index.html;
  autoindex off;
  server_name localhost:8000;
  server_name_in_redirect on;
  port_in_redirect on;

  root /blog/public/;

  location / {
     try_files $uri $uri/ =404;
  }

  location ~ /\. {
      access_log off;
      log_not_found off;
      deny all;
  }
      
  location ~ ~$ {
      access_log off;
      log_not_found off;
      deny all;
  }

  location = /robots.txt {
      access_log off;
      log_not_found off;
  }

  location = /favicon.ico {
      access_log off;
      log_not_found off;
  }

  location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff)(\?ver=[0-9.]+)?$ {
      expires 5h;
  }

}
