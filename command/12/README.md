# 第12章

## AWS Copilotによるプロビジョニング

ココから先はAWS CloudShellでの作業です。

### AWS Copilotのバージョン確認

```shell
copilot --version
```

### AWS Copilotで使用する値を環境変数へセット

```shell
export APP_NAME=demo
export SVC_NAME=example
export ENV_NAME=test
```


### マニフェストファイルの作成

```shell
copilot app init $APP_NAME
copilot svc init --name $SVC_NAME --app $APP_NAME \
  --image nginx --port 80 --svc-type "Load Balanced Web Service"
```


## テスト環境の構築

### リソースの作成

```shell
copilot env init --name $ENV_NAME --app $APP_NAME \
  --profile default --default-config
copilot env deploy --name $ENV_NAME
copilot svc deploy --name $SVC_NAME --env $ENV_NAME
```

### curlによる動作確認

URLはご自身のものと差し替えてください。

```shell
curl -I http://demo-xxx.ap-northeast-1.elb.amazonaws.com
```


## デプロイメントIAMロール

### ポリシードキュメントの作成

```shell
cat <<EOF > policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    }
  ]
}
EOF
```

### IAMポリシーの新規作成

```shell
export POLICY_NAME=deploy-${APP_NAME}-${SVC_NAME}
aws iam create-policy --policy-name $POLICY_NAME \
  --policy-document file://policy.json
```

### IAMロールへ作成したIAMポリシーをアタッチ

```shell
export ROLE_NAME=github-actions
export AWS_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam attach-role-policy --role-name $ROLE_NAME \
  --policy-arn "arn:aws:iam::${AWS_ID}:policy/${POLICY_NAME}"
```


## デプロイ情報の取得

### ECSクラスター名の取得

```shell
aws ecs list-clusters --output text \
  --query "clusterArns[?contains(@, '${APP_NAME}-${ENV_NAME}')]" \
  | cut -d/ -f2
```

### ECSサービス名の取得

`--cluster`フラグの値は、手前で取得したECSクラスター名に差し替えてください。

```shell
aws ecs list-services --cluster "<ECSクラスター名>" --output text \
  --query "serviceArns[?contains(@, '${APP_NAME}-${ENV_NAME}')]" \
  | cut -d/ -f3
```

### タスク定義名の取得

```shell
aws ecs list-task-definitions --status ACTIVE --sort DESC --output text \
  --query "taskDefinitionArns[?contains(@, '${APP_NAME}-${ENV_NAME}')]" \
  | cut -d/ -f2 | cut -d: -f1
```

### ECRリポジトリURIの取得

```shell
aws ecr describe-repositories --output text \
  --query "repositories[?contains(repositoryUri, '$APP_NAME')].repositoryUri"
```

### コンテナ名の取得

```shell
echo $SVC_NAME
```


## デプロイ情報の登録

ココから先はローカル環境での作業です。

```shell
gh variable set ECS_CLUSTER_NAME --body "<ECSクラスター名>"
gh variable set ECS_SERVICE_NAME --body "<ECSサービス名>"
gh variable set TASK_DEFINITION_NAME --body "<タスク定義名>"
gh variable set ECR_REPOSITORY_URI --body "<ECRリポジトリURI>"
gh variable set CONTAINER_NAME --body "<コンテナ名>"
```


## デプロイの実行

### デプロイワークフローの実行

```shell
gh workflow run deploy.yml
```

### デプロイの実行結果を確認

URLはご自身のものと差し替えてください。

```shell
curl http://demo-xxxx.ap-northeast-1.elb.amazonaws.com
```


## 本番環境の構築

ココから先はAWS CloudShellでの作業です。

```shell
export ENV_NAME=prod
```


## Environmentsによるデプロイ情報の管理

ココから先はローカル環境での作業です。

```shell
export ENV_NAME=prod
gh variable set ECS_CLUSTER_NAME --body "<ECSクラスター名>" --env $ENV_NAME
gh variable set ECS_SERVICE_NAME --body "<ECSサービス名>" --env $ENV_NAME
gh variable set TASK_DEFINITION_NAME --body "<タスク定義名>" --env $ENV_NAME
```

## 複数環境向けデプロイワークフロー

### テスト環境

```shell
gh workflow run deploy.yml -f environment-name=test
```

### 本番環境

```shell
gh workflow run deploy.yml -f environment-name=prod
```


## 実行環境の後始末

ココから先はAWS CloudShellでの作業です。

### AWS Copilotで作成したリソースの削除

```shell
copilot app delete --yes
```

### OpenID Connect Providerの削除

```shell
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn \
  arn:aws:iam::${AWS_ID}:oidc-provider/token.actions.githubusercontent.com
```
