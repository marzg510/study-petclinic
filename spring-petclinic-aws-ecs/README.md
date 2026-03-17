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

