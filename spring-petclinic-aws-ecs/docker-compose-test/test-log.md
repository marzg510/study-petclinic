```sh
$ docker compose up -d
[+] up 1/1
 ✔ Container docker-compose-test-nginx-1 Started                                                                                                      0.3s
$ docker ps -a
CONTAINER ID   IMAGE                               COMMAND                  CREATED         STATUS         PORTS                                     NAMES
10bc05e5b13a   public.ecr.aws/nginx/nginx:latest   "/docker-entrypoint.…"   3 seconds ago   Up 2 seconds   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   docker-compose-test-nginx-1
$ curl http://localhost:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy,
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
$ curl http://nginx:80
curl: (6) Could not resolve host: nginx
$ docker compose down
[+] down 2/2
 ✔ Container docker-compose-test-nginx-1 Removed                                                                                                      0.4s
 ✔ Network docker-compose-test_default   Removed                                                                                                      0.3s
$ docker compose up -d
[+] up 3/3
 ✔ Network docker-compose-test_default    Created                                                                                                     0.0s
 ✔ Container docker-compose-test-nginx2-1 Started                                                                                                     0.3s
 ✔ Container docker-compose-test-nginx-1  Started                                                                                                     0.3s
$ docker ps -a
CONTAINER ID   IMAGE                               COMMAND                  CREATED         STATUS         PORTS                                     NAMES
b429c8799e9b   public.ecr.aws/nginx/nginx:latest   "/docker-entrypoint.…"   4 seconds ago   Up 3 seconds   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   docker-compose-test-nginx-1
79326502b6fb   public.ecr.aws/nginx/nginx:latest   "/docker-entrypoint.…"   4 seconds ago   Up 3 seconds   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   docker-compose-test-nginx2-1
$ docker compose exec -it nginx bash
root@b429c8799e9b:/# ping nginx
bash: ping: command not found
root@b429c8799e9b:/# curl http://nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy,
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
root@b429c8799e9b:/# curl http://nginx2
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, nginx is successfully installed and working.
Further configuration is required for the web server, reverse proxy,
API gateway, load balancer, content cache, or other features.</p>

<p>For online documentation and support please refer to
<a href="https://nginx.org/">nginx.org</a>.<br/>
To engage with the community please visit
<a href="https://community.nginx.org/">community.nginx.org</a>.<br/>
For enterprise grade support, professional services, additional
security features and capabilities please refer to
<a href="https://f5.com/nginx">f5.com/nginx</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
root@b429c8799e9b:/# exit
exit
$ docker compose down
[+] down 3/3
 ✔ Container docker-compose-test-nginx2-1 Removed                                                                                                     0.4s
 ✔ Container docker-compose-test-nginx-1  Removed                                                                                                     0.5s
 ✔ Network docker-compose-test_default    Removed                                                                                                     0.3s
$