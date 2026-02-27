# Study Pet Clinic 

## Environment

```sh
# sudo apt install openjdk-25-jre-headless
# sudo apt remove openjdk-25-jre-headless
sudo apt install openjdk-17-jre-headless

```

## Spring Pet Clinic

https://github.com/spring-projects/spring-petclinic

### Run Locally

```sh
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
./mvnw spring-boot:run
```

Welcome
- http://localhost:8080/

これはOK

### with MySQL

```
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:9.5
./mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

## Pet Clinic microservice

https://github.com/spring-petclinic/spring-petclinic-microservices

- Discovery Server - http://localhost:8761
- Config Server - http://localhost:8888
- AngularJS frontend (API Gateway) - http://localhost:8080
- Customers, Vets, Visits and GenAI Services - random port, check Eureka Dashboard
- Tracing Server (Zipkin) - http://localhost:9411/zipkin/ (we use openzipkin)
- Admin Server (Spring Boot Admin) - http://localhost:9090
- Grafana Dashboards - http://localhost:3030
- Prometheus - http://localhost:9091

### 最終的には

```sh
git clone https://github.com/spring-petclinic/spring-petclinic-microservices.git
docker compose up
```

### with MySQL

#### docker

docker-compose.yaml更新

```sh
docker compose up -d
```

### with docker compose

```sh
bash ./mvnw clean install -P buildDocker
failed to fetch metadata: fork/exec /usr/local/lib/docker/cli-plugins/docker-buildx: no such file or directory

DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

unknown flag: --load

Usage:  docker build [OPTIONS] PATH | URL | -

Run 'docker build --help' for more information
[ERROR] Command execution failed.
org.apache.commons.exec.ExecuteException: Process exited with an error: 125 (Exit value: 125)
    at org.apache.commons.exec.DefaultExecutor.executeInternal (DefaultExecutor.java:404)
    at org.apache.commons.exec.DefaultExecutor.execute (DefaultExecutor.java:166)
    at org.codehaus.mojo.exec.ExecMojo.executeCommandLine (ExecMojo.java:881)
    at org.codehaus.mojo.exec.ExecMojo.executeCommandLine (ExecMojo.java:841)
    at org.codehaus.mojo.exec.ExecMojo.execute (ExecMojo.java:447)
```

### run_all

```sh
./scripts/run_all.sh
```

### Gemini

```
./mvnw clean install -DskipTests
docker-compose up
```
### Java

```sh
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64/"
../mvnw spring-boot:run
```


#### 起動順

>サポートサービス（ConfigサーバーとDiscoveryサーバー）は、他のアプリケーション（Customers、Vets、Visits、API）よりも先に起動する必要があります。Tracingサーバー、Adminサーバー、Grafana、Prometheusの起動は任意です。

```
cd spring-petclinic-config-server && ../mvnw spring-boot:run
cd spring-petclinic-discovery-server && ../mvnw spring-boot:run
cd spring-petclinic-api-gateway && ../mvnw spring-boot:run
cd spring-petclinic-customers-service && ../mvnw spring-boot:run
cd spring-petclinic-vets-service && ../mvnw spring-boot:run
cd spring-petclinic-visits-service && ../mvnw spring-boot:run
cd spring-petclinic-admin-server && ../mvnw spring-boot:run
spring-petclinic-genai-service

../mvnw spring-boot:run
```

### minikube

```sh
minikube image load spring-petclinic-microservices-grafana-server
minikube image load spring-petclinic-microservices-prometheus-server
```

```sh
k create ns petclinic
k apply -f config-server.yaml -n petclinic
k apply -f discovery-server.yaml -n petclinic
k apply -f grafana-server.yaml -n petclinic
k apply -f prometheus-server.yaml -n petclinic
k apply -f api-gateway.yaml -n petclinic
k apply -f tracing-server.yaml -n petclinic
k apply -f mysql.yaml -n petclinic
k apply -f customers-service.yaml -n petclinic
k apply -f vets-service.yaml -n petclinic
k apply -f visits-service.yaml -n petclinic

```sh
# kubectl port-forward -n petclinic svc/config-server 8888:8888 &
kubectl port-forward -n petclinic svc/discovery-server 8761:8761 &
kubectl port-forward -n petclinic svc/api-gateway 8080:8080 &
kubectl port-forward -n petclinic svc/grafana-server 3030:3030 &
kubectl port-forward -n petclinic svc/prometheus-server 9091:9090 &
kubectl port-forward -n petclinic svc/tracing-server 9411:9411 &
jobs
fg
fg %1
```

servers

http://localhost:9091
http://localhost:9411


### minikube with MySQL

ConfigMap
```sh
kubectl -n petclinic create configmap petclinic-config --from-file=config/
```

Secret
```sh
k -n petclinic create secret generic mysql-secret --from-env-file=config/mysql.env
```


#### Add to Prometheus

```
# 1. minikubeのDockerデーモンに接続
eval $(minikube docker-env)

# 2. イメージをリビルド
docker build -t spring-petclinic-microservices-prometheus-server ../spring-petclinic-microservices-mysql/docker/prometheus/

# 3. Podを再起動（イメージを再読み込み）
kubectl rollout restart deployment prometheus-server -n petclinic
```
