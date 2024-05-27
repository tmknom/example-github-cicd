package main

deny[msg] { # ワークフローレベルのpermissionsが省略されていたら拒否
    not input.permissions
    msg = "Workflow permissions are missing"
}

deny[msg] { # ワークフローレベルのpermissionsで空以外が指定されていたら拒否
    input.permissions != {}
    msg = sprintf("Workflow permissions are not empty: %v", [input.permissions])
}
