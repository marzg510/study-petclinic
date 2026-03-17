# Spring Petclinic on AWS ECS

## AWS CLI

docker run --rm -it public.ecr.aws/aws-cli/aws-cli command
docker run --rm -it public.ecr.aws/aws-cli/aws-cli help
docker run --rm -it -v ~/.aws:/root/.aws public.ecr.aws/aws-cli/aws-cli configure get region
docker run --rm -it -v ~/.aws:/root/.aws public.ecr.aws/aws-cli/aws-cli s3 ls

alias aws='docker run --rm -it -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} -v ~/.aws:/root/.aws -v $(pwd):/aws -w /aws public.ecr.aws/aws-cli/aws-cli'
aws configure
aws configure get region
aws sts get-caller-identity
aws s3 ls
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)


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

### Create Cluster

```sh
aws ecs create-cluster --cluster-name config-server --tag key=project,value=petclinic --capacity-providers FARGATE
aws ecs delete-cluster --cluster config-server
```

### Create Task Definition

```
aws ecs register-task-definition --cli-input-yaml file://config-server-task-definition.yaml
aws ecs register-task-definition --cli-input-yaml task-definition.yaml

```

