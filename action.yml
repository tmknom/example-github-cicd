name: Create PR
description: |
  変更したファイルをコミットし、プルリクエストを作成します。
  プルリクエストのタイトルや本文には、コミットメッセージがそのまま利用されます。
  パーミッションに「contents: write」と「pull-requests: write」が必要です。
inputs:
  message:                                # アクションの入力
    required: true
    description: コミットメッセージ
outputs:
  branch:                                 # アクションの出力
    value: ${{ steps.pr.outputs.branch }}
    description: プルリクエストのブランチ
runs:
  using: composite
  steps:
    - id: pr
      shell: bash
      env:
        USERNAME: github-actions[bot]
        EMAIL: 41898282+github-actions[bot]@users.noreply.github.com
        MESSAGE: ${{ inputs.message }}
        BRANCH: auto/${{ github.run_id }}/${{ github.run_attempt }}
        GITHUB_TOKEN: ${{ github.token }}
      run: |
        echo "branch=${BRANCH}" >> "${GITHUB_OUTPUT}"
        git config --global user.name "${USERNAME}"   # Gitのユーザー設定
        git config --global user.email "${EMAIL}"
        git switch -c "${BRANCH}"                     # コミットとプッシュ
        git add .
        git commit -m "${MESSAGE}"
        git push origin "${BRANCH}"                   # プルリクエストの作成（↓）
        gh pr create --head "${BRANCH}" --title "${MESSAGE}" --body "${MESSAGE}"
branding:      # ブランディング設定
  color: green # 緑色
  icon: shield # シールドアイコン
