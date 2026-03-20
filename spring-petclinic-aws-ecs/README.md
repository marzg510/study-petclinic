# Spring Petclinic on AWS ECS

## AWS CLI

Config

```sh
aws configure
aws configure get region
aws sts get-caller-identity
aws s3 ls
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

## Terraform

### [tfenv](https://github.com/tfutils/tfenv) 

```sh
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
tfenv --version
tfenv use latest
```

### Terraform Install

```sh
tfenv install
terraform --version
```

### Hello World

make main.tf

```sh
terraform init
terraform apply
terraform destroy
```

## config-server

config-server.tf
http://config-server:8888

```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name config-server --query "taskArns[0]" --output text) \
  --container spring-petclinic-config-server  \
  --interactive --command "/usr/bin/curl http://api-gateway:8080"

```

configディレクトリにconfigファイルを配置し、gitリポジトリから参照させるように設定。
設定確認
spring.cloud.discovery.client.simple.instances が含まれていれば成功です。
```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name config-server --query "taskArns[0]" --output text) \
  --container spring-petclinic-config-server \
  --interactive --command "/usr/bin/curl http://localhost:8888/api-gateway/docker"
```

## api-gateway

初期ホームの画面を持っているので起動する必要がある

api-gateway.tf
http://api-gateway:8080

config-serverへの接続テスト
```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name api-gateway --query "taskArns[0]" --output text) \
  --container spring-petclinic-api-gateway  \
  --interactive --command "/usr/bin/curl http://config-server:8888"

```
※AWS Consoleから、サービスー＞タスクでコンテナへ辿り　Cloud Shellから接続でもできるが、コピペやカーソルキーでのコマンド履歴呼び出しがうまく効かないのでメインで使うのはやめた方がいい

```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name api-gateway --query "taskArns[0]" --output text) \
  --container spring-petclinic-api-gateway  \
  --interactive --command "/bin/bash"

```


強制デプロイ
```sh
aws ecs update-service --cluster petclinic --service api-gateway --force-new-deployment
```

## customers-service

customers-service.tf
http://customers-service:8081

```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name customers-service --query "taskArns[0]" --output text) \
  --container spring-petclinic-customers-service  \
  --interactive --command "/usr/bin/curl http://config-server:8888"

```

API gatewayからcustomersへの接続
```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name api-gateway --query "taskArns[0]" --output text) \
  --container spring-petclinic-api-gateway  \
  --interactive --command "/usr/bin/curl http://customers-service:8081/owners"

```

Bash
```sh
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name customers-service --query "taskArns[0]" --output text) \
  --container spring-petclinic-customers-service  \
  --interactive --command "/bin/bash"
```

Logs
```sh
aws logs get-log-events \
  --log-group-name /ecs/spring-petclinic-customers-service \
  --log-stream-name $(aws logs describe-log-streams \
    --log-group-name /ecs/spring-petclinic-customers-service \
    --order-by LastEventTime --descending \
    --query "logStreams[0].logStreamName" --output text) \
  --query "events[*].message"
```
aws ecs execute-command --cluster petclinic \
  --task $(aws ecs list-tasks --cluster petclinic --service-name customers-service --query "taskArns[0]" --output text) \
  --container spring-petclinic-customers-service  \
  --interactive --command "/usr/bin/curl -s localhost:8081/actuator/health"

curl -s localhost:8081/actuator/health | python3 -m json.tool

curl http://localhost:8081/owners

強制デプロイ
```sh
aws ecs update-service --cluster petclinic --service customers-service --force-new-deployment
```


## ,vets,visits




# ここから下は古い！！

## api-gateway


## Cluster

```sh
aws ecs create-cluster --cluster-name petclinic --tag key=project,value=petclinic --capacity-providers FARGATE
# aws ecs delete-cluster --cluster petclinic
```

## Service Discovery(Cloud Map)

```sh
aws servicediscovery create-private-dns-namespace \
    --name petclinic.local \
    --vpc vpc-2636c543
```

## config-server

### Push Image

```sh
# 東京リージョンに “my-app” という名前のリポジトリを作成する例
aws ecr create-repository \
    --repository-name springcommunity/spring-petclinic-config-server \
    --region ap-northeast-1 \
    --tags Key=project,Value=petclinic

aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com
docker build -t spring-petclinic/config-server .

docker tag springcommunity/spring-petclinic-config-server:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/springcommunity/spring-petclinic-config-server:latest

docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/springcommunity/spring-petclinic-config-server:latest

```

### Create Task Definition

```sh
aws ecs register-task-definition --cli-input-yaml file://config-server-task-definition.yaml
```

```sh
aws ecs register-task-definition \
    --family spring-petclinic-config-server \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu "256" \
    --memory "512" \
    --execution-role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole" \
    --container-definitions '[
        {
            "name": "spring-petclinic-config-server",
            "image": "springcommunity/spring-petclinic-config-server:latest",
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 8888,
                    "protocol": "tcp"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/spring-petclinic-config-server",
                    "awslogs-region": "ap-northeast-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]'
 
```

#### Terraform

既存リソースのインポート
```
terraform import aws_ecs_cluster.main petclinic
terraform apply
```

削除
```
terraform destroy
```

タスクのパブリックIP取得
```sh
TASK_ARN=$(aws ecs list-tasks --cluster nginx-test --service-name nginx --query 'taskArns[0]' --output text)

ENI_ID=$(aws ecs describe-tasks --cluster nginx-test --tasks $TASK_ARN \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text)

aws ec2 describe-network-interfaces \
  --network-interface-ids $ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```


## discovery-server

ECS でのサービス間通信には AWS Cloud Map（ECS Service Discovery）を使います

petclinic.tfにサービスディスカバリの設定を追加する


## Grafana, Prometeus

今回はCloudWatch
tfにCloudWatch Conteiner Insightsの設定を追加する

ほかの選択としてはAMG,AMPがある
Amazon Maneged Service for Prometheus(AMP)
Amazon Managed Grafana(AMG)

ECSで起動する手もあるが、動的IPへの追随が難しい

## API Gateway

ALBを使うことにする（Claude曰く、API GatewayはVPCリンクが必要になる）
alb.tf

フロントエンドUIの部分は、とりあえずECSでそのまま動かす
api-gateway.tf

いじった点
- config-serverのサービス名変更
- eurekaの無効化

うまく行かない時は強制デプロイも試す
```sh
aws ecs update-service --cluster petclinic --service api-gateway --force-new-deployment
```

ALBのDNS名でブラウザからアクセス

terraform output alb_dns_name

## customers,vets,visits


## Tracing Server

サービスが動き出してからにする
後回し


k apply -f customers-service.yaml -n petclinic
k apply -f vets-service.yaml -n petclinic
k apply -f visits-service.yaml -n petclinic


