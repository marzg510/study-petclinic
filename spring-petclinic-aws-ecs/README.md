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
```

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


