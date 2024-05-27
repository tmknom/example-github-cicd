#!/usr/bin/env bash

base64url() {
  openssl enc -base64 -A | tr '+/' '-_' | tr -d '='
}

sign() {
  openssl dgst -binary -sha256 -sign <(printf '%s' "${PRIVATE_KEY}")
}

# JWTの生成
header="$(printf '{"alg":"RS256","typ":"JWT"}' | base64url)"
now="$(date '+%s')"
iat="$((now - 60))"
exp="$((now + (3 * 60)))"
template='{"iss":"%s","iat":%s,"exp":%s}'
payload="$(printf "${template}" "${APP_ID}" "${iat}" "${exp}" | base64url)"
signature="$(printf '%s' "${header}.${payload}" | sign | base64url)"
jwt="${header}.${payload}.${signature}"

# Installation APIの実行
repo="${GITHUB_REPOSITORY_OWNER}/${TARGET_REPO}"
installation_id="$(curl --location --silent --request GET \
  --url "${GITHUB_API_URL}/repos/${repo}/installation" \
  --header "Accept: application/vnd.github+json" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --header "Authorization: Bearer ${jwt}" \
  | jq -r '.id'
)"

# Access Tokens APIの実行
token="$(curl --location --silent --request POST \
  --url "${GITHUB_API_URL}/app/installations/${installation_id}/access_tokens" \
  --header "Accept: application/vnd.github+json" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --header "Authorization: Bearer ${jwt}" \
  --data "$(printf '{"repositories":["%s"]}' "${TARGET_REPO}")" \
  | jq -r '.token'
)"
echo "token=${token}" >>"${GITHUB_OUTPUT}"
