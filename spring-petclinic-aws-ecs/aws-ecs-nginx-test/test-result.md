## apply 後の通信確認方法：

nginx-test-2 のタスクに exec で入り、nginx-test に HTTP リクエストを送ります。

```sh
# nginx-test-2 のタスクIDを確認
aws ecs list-tasks --cluster nginx-test --service-name nginx-test-2-service

# タスクに exec で接続
aws ecs execute-command --cluster nginx-test \
  --task <task-id> \
  --container nginx-test-2 \
  --interactive --command "/bin/bash"

# コンテナ内から nginx-test に疎通確認
curl http://nginx-test:80
```

Service Connect が機能していれば http://nginx-test:80 で nginx-test のレスポンスが返ってきます。

## 準備

SessionManagerのインストール

```
# Ubuntuの場合
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
rm session-manager-plugin.deb
```


## 結果

### nginx-test-2からnginx-testへの接続

```sh
# タスクに exec で接続
aws ecs execute-command --cluster nginx-test \
  --task $(aws ecs list-tasks --cluster nginx-test --service-name nginx-test-2-service --query "taskArns[0]" --output text) \
  --container nginx-test-2 \
  --interactive --command "/bin/bash"

# コンテナ内から nginx-test に疎通確認
curl http://nginx-test:80
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
以下略

```

### nginx-testからnginx-test-2への接続

```sh
aws ecs execute-command --cluster nginx-test \
  --task $(aws ecs list-tasks --cluster nginx-test --service-name nginx-test-service --query "taskArns[0]" --output text) \
  --container nginx-test \
  --interactive --command "/usr/bin/curl http://nginx-test-2:80"
Starting session with SessionId: ecs-execute-command-pqo8b8hz3bvsjvv3bh3l56n8ku
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
以下略
```