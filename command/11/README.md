# 第11章

## プライベートリポジトリの作成

```shell
gh repo create gh-oidc --private --clone --add-readme
cd gh-oidc
```


## AWSにおけるOpenID Connectの利用準備

ココから先はAWS CloudShellでの作業です。

### AWS CLIのバージョン確認

```shell
aws --version
```

### AWSアカウントIDの取得

```shell
aws sts get-caller-identity --query Account --output text
```

## OpenID Connect Provider

```shell
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 1234567890123456789012345678901234567890
```


## IAMロール

### 利用するリポジトリ

「`OWNER`」と「`REPO`」はご自身の環境にあわせて変更してください。

```shell
export GITHUB_REPOSITORY=<OWNER>/<REPO>
```

### Identity ProviderのURL

```shell
export PROVIDER_URL=token.actions.githubusercontent.com
```

### AWSアカウントID

```shell
export AWS_ID=$(aws sts get-caller-identity --query Account --output text)
```

### IAMロール名

```shell
export ROLE_NAME=github-actions
```


#### Assume Roleポリシーを定義したJSONファイルの作成

```shell
cat <<EOF > assume_role_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ID}:oidc-provider/${PROVIDER_URL}"
      },
      "Condition": {
        "StringLike": {
          "${PROVIDER_URL}:sub": "repo:${GITHUB_REPOSITORY}:*"
        }
      }
    }
  ]
}
EOF
```

#### IAMロールの作成

```shell
aws iam create-role \
  --role-name $ROLE_NAME \
  --assume-role-policy-document file://assume_role_policy.json
```

#### IAMポリシーのアタッチ

```shell
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/IAMReadOnlyAccess
```


## OpenID ConnectによるAWS連携

ココから先はローカル環境での作業です。

### AWSアカウントIDのSecrets登録

```shell
gh secret set AWS_ID --body "<AWSアカウントID>"
```


### IAMロール名のSecrets登録

```shell
gh secret set ROLE_NAME --body "<IAMロール名>"
```
