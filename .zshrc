# Unlock SSH keys with Keychain
ssh-add --apple-load-keychain

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# PATHs
PATHS=(
    $HOMEBREW_PREFIX/opt/node@18/bin
    $HOMEBREW_PREFIX/opt/python@3.10/libexec/bin
)
export PATH=${(j[:])PATHS}:$PATH 

function aws-get-mfa-code {
    ykman oath accounts code aws --single 2>/dev/null | sed -E 's/(None:)?aws[[:space:]]+([[:digit:]]+)/\2/'
}

function aws-mfa-session {
    AWS_MFA_SERIAL=$(grep mfa ~/.aws/config | sed -E 's/mfa_serial[[:space:]]*=[[:space:]]*(arn.+)/\1/')
    STS_CREDS=$(aws sts get-session-token --serial-number "$AWS_MFA_SERIAL" --token-code "$1" --output json)
    if [ "$?" -eq "0" ]
    then
        export AWS_ACCESS_KEY_ID=$(echo $STS_CREDS | jq -r '.Credentials.AccessKeyId')
        export AWS_SECRET_ACCESS_KEY=$(echo $STS_CREDS | jq -r '.Credentials.SecretAccessKey')
        export AWS_SECURITY_TOKEN=$(echo $STS_CREDS | jq -r '.Credentials.SessionToken')
        export AWS_SESSION_TOKEN=$(echo $STS_CREDS | jq -r '.Credentials.SessionToken')
        export AWS_SESSION_EXPIRY=$(echo $STS_CREDS | jq -r '.Credentials.Expiration')
        echo "Session credentials set, expires at $AWS_SESSION_EXPIRY"
    else
        echo "Error: Failed to obtain temporary credentials."
    fi
}

function aws-reset-env {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SECURITY_TOKEN
    unset AWS_SESSION_TOKEN
    unset AWS_SESSION_EXPIRY
    unset AWS_ASSUMED_ROLE_ID
    unset AWS_ASSUMED_ROLE_ARN
}

alias awsmfa="aws-reset-env && aws-mfa-session \$(aws-get-mfa-code)"
alias nukedns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
