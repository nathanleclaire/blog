server {
  server_name nathanleclaire.com;
  index index.html;
  autoindex off;

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
