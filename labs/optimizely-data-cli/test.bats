#!/usr/bin/env bats

################################################################################
# Sourcing the Optimizely Enriched Event CLI                                   #
################################################################################

setup() {
  CLI_NAME="oevents"
  source "./$CLI_NAME" > /dev/null 2> /dev/null
}

################################################################################
# Helper functions and handy global variables                                  #
################################################################################

AreArraysEqual() {
  local -n arr1="$1"
  local -n arr2="$2"

  [ ${#arr1[@]} = ${#arr2[@]} ]

  for (( i=0; i<${#arr1[@]}; ++i )); do
    [ "${arr1[i]}" = "${arr2[i]}" ]
  done
}

accessKeyId_stub="accessKeyId_stub"
secretAccessKey_stub="secretAccessKey_stub"
sessionToken_stub="sessionToken_stub"
expiration_stub="1595225431000"
s3Path_stub="s3://optimizely-events-data/v1/account_id=123/"

# an example "valid" Optimizely auth api response
export valid_auth_api_response="{
  \"credentials\": {
    \"accessKeyId\":\"$accessKeyId_stub\",
    \"secretAccessKey\":\"$secretAccessKey_stub\",
    \"sessionToken\":\"$sessionToken_stub\",
    \"expiration\":$expiration_stub
  },
  \"s3Path\":\"$s3Path_stub\"
}"

# an example "invalid" Optimizely auth api response
export invalid_auth_api_response="{
  \"credentials\": {
    \"secretAccessKey\":\"$secretAccessKey_stub\",
    \"sessionToken\":\"$sessionToken_stub\",
    \"expiration\":$expiration_stub
  },
  \"s3Path\":\"$s3Path_stub\"
}"

# Current time (in seconds)
present=$(date +%s)

# One hour in the future (in milliseconds)
future=$(( (present+3600) * 1000 ))

# One hour in the past (in milliseconds)
past=$(( (present-3600) * 1000 ))

################################################################################
# Unit Tests                                                                   #
################################################################################

# incr_day

@test "incr_day" {
  [ "$(incr_day 2020-06-30)" = "2020-07-01" ]
}

# assert_before_or_equal

@test "assert_before_or_equal with increasing, equal, and decreasing dates" {
  run assert_before_or_equal "2020-03-01" "2020-03-02"
  [ "$status" = 0 ]
  run assert_before_or_equal "2020-03-01" "2020-03-01"
  [ "$status" = 0 ]
  run assert_before_or_equal "2020-03-01" "2020-02-28"
  [ "$status" = 1 ]
}

# ComputeDateRange

@test "ComputeDateRange with a multi-day range" {
  start="2020-06-29"
  end="2020-07-03"
  expected=( "2020-06-29" "2020-06-30" "2020-07-01" "2020-07-02" "2020-07-03" )

  ComputeDateRange

  AreArraysEqual date_range expected
}

@test "ComputeDateRange with a single-day range" {
  start="2020-06-29"
  expected=( "2020-06-29" )

  ComputeDateRange

  # ComputeDateRange should yield a single date if no end date is specified
  AreArraysEqual date_range expected
}

@test "ComputeDateRange with an invalid range" {
  start="2020-07-03"
  end="2020-06-29"

  run ComputeDateRange

  # ComputeDateRange should fail given an invalid date range
  [ "$status" = 1 ]
}

# CheckAWSCredentialExpiration

@test "CheckAWSCredentialExpiration with AWS_SESSION_EXPIRATION unset" {
  unset AWS_SESSION_EXPIRATION
  authenticated=true

  CheckAWSCredentialExpiration
  
  # CheckAWSCredentialExpiration shouldn't modify authenticated if AWS_SESSION_EXPIRATION isn't set
  [ "$authenticated" = true ]
}

@test "CheckAWSCredentialExpiration with AWS_SESSION_EXPIRATION in the future" {
  authenticated=true
  AWS_SESSION_EXPIRATION="$future"

  CheckAWSCredentialExpiration

  # CheckAWSCredentialExpiration shouldn't modify authenticated if AWS_SESSION_EXPIRATION hasn't passed
  [ "$authenticated" = true ]
}

@test "CheckAWSCredentialExpiration with AWS_SESSION_EXPIRATION in the past" {
  authenticated=true
  AWS_SESSION_EXPIRATION="$past"
  
  CheckAWSCredentialExpiration
  
  # CheckAWSCredentialExpiration should modify authenticated if AWS_SESSION_EXPIRATION has passed
  [ "$authenticated" = false ]
}

# MakeAuthAPIRequest

@test "MakeAuthAPIRequest with OPTIMIZELY_API_TOKEN unset" {
  unset OPTIMIZELY_API_TOKEN

  run MakeAuthAPIRequest
  
  # MakeAuthAPIRequest should fail if it can't find an optimizely api token
  [ "$status" -eq 1 ]
}

@test "MakeAuthAPIRequest with OK response" {
  OPTIMIZELY_API_TOKEN="token"
  response_body="response_body"
  curl() { echo "${response_body}200"; }
  export -f curl

  MakeAuthAPIRequest
  
  # MakeAuthAPIRequest should return the response body (without the response code)
  [ "$auth_api_credential_str" = "$response_body" ]
}

@test "MakeAuthAPIRequest with NOT OK response" {
  OPTIMIZELY_API_TOKEN="token"
  response_body="response_body"
  curl() { echo "${response_body}400"; }
  export -f curl

  run MakeAuthAPIRequest
  
  # MakeAuthAPIRequest should fail if the response code is not 200
  [ "$status" -eq 1 ]
}

# ExtractValueFromJSON

@test "ExtractValueFromJSON with valid path" {
  json_str="{\"obj\":{\"a\":5,\"b\":6}}"
  path=".obj.a"

  val=$(ExtractValueFromJSON "$json_str" "$path")
  
  [ "$val" = "5" ]
}

@test "ExtractValueFromJSON with invalid path" {
  json_str="{\"obj\":{\"a\":5,\"b\":6}}"
  path=".obj.c"
  
  run ExtractValueFromJSON "$json_str" "$path"
  
  # ExtractValueFromJSON should fail if the provided path doesn't correspond to the provide JSON obj
  [ "$status" -eq 1 ]
}

@test "ExtractValueFromJSON with empty json str" {
  json_str=""
  path=".obj.c"
  
  run ExtractValueFromJSON "$json_str" "$path"
  
  # ExtractValueFromJSON if there is no JSON object provided
  [ "$status" -eq 1 ]
}

# ParseAuthAPIResponse

@test "ParseAuthAPIResponse with valid API response" {
  auth_api_credential_str="$valid_auth_api_response"
  
  ParseAuthAPIResponse
  
  # ParseAuthAPIResponse should set each of these variables given a valid API response
  [ "$AWS_ACCESS_KEY_ID" = "$accessKeyId_stub" ]
  [ "$AWS_SECRET_ACCESS_KEY" = "$secretAccessKey_stub" ]
  [ "$AWS_SESSION_TOKEN" = "$sessionToken_stub" ]
  [ "$AWS_SESSION_EXPIRATION" = "$expiration_stub" ]
  [ "$S3_BASE_PATH" = "$s3Path_stub" ]
}

@test "ParseAuthAPIResponse with invalid API response" {
  auth_api_credential_str="$invalid_auth_api_response"
  
  run ParseAuthAPIResponse
  
  # ParseAuthAPIResponse should fail if it receives an invalid JSON response
  [ "$status" -eq 1 ]
}

# Authenticate

@test "Authenticate with valid API response" {
  OPTIMIZELY_API_TOKEN="token"
  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl

  Authenticate 
  
  # Authenticate should set the following variables given a valid Optimizely access token
  [ "$AWS_ACCESS_KEY_ID" = "$accessKeyId_stub" ]
  [ "$AWS_SECRET_ACCESS_KEY" = "$secretAccessKey_stub" ]
  [ "$AWS_SESSION_TOKEN" = "$sessionToken_stub" ]
  [ "$AWS_SESSION_EXPIRATION" = "$expiration_stub" ]
  [ "$S3_BASE_PATH" = "$s3Path_stub" ]
  [ "$authenticated" = true ]
}

@test "Authenticate with an invalid API response" {
  OPTIMIZELY_API_TOKEN="token"
  curl() { echo "${invalid_auth_api_response}200"; }
  export -f curl

  run Authenticate 
  
  # Authenticate should fail if an invalid JSON response is received from the Optimizely auth API
  [ "$status" -eq 1 ]
}

# EnsureAuthenticatedIfTokenPresent

@test "EnsureAuthenticatedIfTokenPresent with no token present" {
  unset OPTIMIZELY_API_TOKEN
  authenticated=false

  EnsureAuthenticatedIfTokenPresent
  
  [ "$authenticated" = false ]
}

@test "EnsureAuthenticatedIfTokenPresent with AWS_SESSION_EXPIRATION unset" {
  OPTIMIZELY_API_TOKEN="token"
  unset AWS_SESSION_EXPIRATION
  authenticated=false
  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl
  
  EnsureAuthenticatedIfTokenPresent

  [ "$authenticated" = true ]
  [ "$AWS_ACCESS_KEY_ID" = "$accessKeyId_stub" ]
}

@test "EnsureAuthenticatedIfTokenPresent with valid credentials" {
  OPTIMIZELY_API_TOKEN="token"
  AWS_ACCESS_KEY_ID="accessKeyId_stub_1"
  authenticated=true
  AWS_SESSION_EXPIRATION="$future"
  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl
  
  EnsureAuthenticatedIfTokenPresent
  
  # EnsureAuthenticatedIfTokenPresent should NOT reauthenticate; AWS_ACCESS_KEY_ID should be preserved
  [ "$authenticated" = true ]
  [ "$AWS_ACCESS_KEY_ID" = "accessKeyId_stub_1" ]
}

@test "EnsureAuthenticatedIfTokenPresent with expired credentials" {
  OPTIMIZELY_API_TOKEN="token"
  AWS_ACCESS_KEY_ID="accessKeyId_stub_1"
  authenticated=true
  AWS_SESSION_EXPIRATION="$past"
  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl
  
  EnsureAuthenticatedIfTokenPresent

  # EnsureAuthenticatedIfTokenPresent should re-authenticate and reset the value of AWS_ACCESS_KEY_ID
  [ "$authenticated" = true ]
  [ "$AWS_ACCESS_KEY_ID" = "$accessKeyId_stub" ] 
}

# BuildS3BasePath

@test "BuildS3BasePath with valid Optimizely token" {
  OPTIMIZELY_API_TOKEN="token"
  authenticated=false
  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl

  BuildS3BasePath

  [ "$authenticated" = true ]
  [ "$S3_BASE_PATH" = "$s3Path_stub" ] 
}

@test "BuildS3BasePath without valid Optimizely token, but with account_id" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  account_id="12345"
  authenticated=false
  
  BuildS3BasePath
  
  # BuildS3BasePath cannot authenticate without a valid token
  [ "$authenticated" = false ] 
  # BuildS3BasePath should be able to use account_id to build a valid base path
  [ "$S3_BASE_PATH" = "s3://$bucket/v1/account_id=$account_id/" ] 
}

@test "BuildS3BasePath without valid Optimizely token or account_id" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  unset account_id
  authenticated=false
  
  run BuildS3BasePath
  
  # BuildS3BasePath should fail, since a base path cannot be constructed
  [ "$status" -eq 1 ]
}

# ValidateType

@test "ValidateType should accept only decisions or events" {
  run ValidateType "decisions"
  [ "$status" -eq 0 ]

  run ValidateType "events"
  [ "$status" -eq 0 ]

  run ValidateType "x"
  [ "$status" -eq 1 ]

  run ValidateType
  [ "$status" -eq 1 ]
}

# BuildS3RelativePaths

@test "BuildS3RelativePaths with no type" {
  bucket="optimizely-events-data"
  account_id="12345"
  expected=( "" )
  
  BuildS3RelativePaths
  
  # BuildS3RelativePaths should return a single empty string, since no type was specified
  AreArraysEqual s3_relative_paths expected 
}

@test "BuildS3RelativePaths with date specified, but no type" {
  bucket="optimizely-events-data"
  account_id="12345"
  start="2020-07-01"
  expected=( "" )
  
  BuildS3RelativePaths
  
  # BuildS3RelativePaths should return a single empty string, since no type was specified
  AreArraysEqual s3_relative_paths expected
}

@test "BuildS3RelativePaths with type specified" {
  bucket="optimizely-events-data"
  account_id="12345"
  type="decisions"
  expected=( "type=decisions" )

  BuildS3RelativePaths
  
  # BuildS3RelativePaths should return only a "type=decisions" path
  AreArraysEqual s3_relative_paths expected
}

@test "BuildS3RelativePaths with misspelled type specified" {
  bucket="optimizely-events-data"
  account_id="12345"
  type="x"

  run BuildS3RelativePaths

  # BuildS3RelativePaths should fail if the specified type is misspelled
  [ "$status" = 1 ]
}

@test "BuildS3RelativePaths with type and single date specified" {
  bucket="optimizely-events-data"
  account_id="12345"
  type="decisions"
  start="2020-07-01"
  expected=( "type=decisions/date=2020-07-01" )
  
  BuildS3RelativePaths
  
  AreArraysEqual s3_relative_paths expected
}

@test "BuildS3RelativePaths with type and date range specified" {
  bucket="optimizely-events-data"
  account_id="12345"
  type="decisions"
  start="2020-07-01"
  end="2020-07-03"
  expected=( 
    "type=decisions/date=2020-07-01"
    "type=decisions/date=2020-07-02"
    "type=decisions/date=2020-07-03"
  )
  
  BuildS3RelativePaths
  
  AreArraysEqual s3_relative_paths expected
}

@test "BuildS3RelativePaths with type, date range, and experiment specified" {
  bucket="optimizely-events-data"
  account_id="12345"
  type="decisions"
  start="2020-07-01"
  end="2020-07-03"
  partition_key="experiment"
  partition_val="5678"
  expected=( 
    "type=decisions/date=2020-07-01/experiment=5678"
    "type=decisions/date=2020-07-02/experiment=5678"
    "type=decisions/date=2020-07-03/experiment=5678"
  )
  
  BuildS3RelativePaths
  
  AreArraysEqual s3_relative_paths expected
}

# BuildS3AbsolutePaths

@test "BuildS3AbsolutePaths with no type" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  account_id="12345"
  expected=( "s3://$bucket/v1/account_id=$account_id/" )
  
  BuildS3AbsolutePaths
  
  AreArraysEqual s3_absolute_paths expected
}

@test "BuildS3AbsolutePaths with type specified" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  account_id="12345"
  type="decisions"
  expected=( "s3://$bucket/v1/account_id=$account_id/type=decisions/" )
  BuildS3AbsolutePaths
  AreArraysEqual s3_absolute_paths expected
}

@test "BuildS3AbsolutePaths with type and single date specified" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  account_id="12345"
  type="decisions"
  start="2020-07-01"
  expected=( "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-01/" )
  
  BuildS3AbsolutePaths
  
  AreArraysEqual s3_absolute_paths expected
}

@test "BuildS3AbsolutePaths with type and date range specified" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  account_id="12345"
  type="decisions"
  start="2020-07-01"
  end="2020-07-03"
  expected=( 
    "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-01/"
    "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-02/"
    "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-03/"
  )

  BuildS3AbsolutePaths
  
  AreArraysEqual s3_absolute_paths expected
}

@test "BuildS3AbsolutePaths with type, date range, and experiment specified" {
  bucket="optimizely-events-data"
  unset OPTIMIZELY_API_TOKEN
  account_id="12345"
  type="decisions"
  start="2020-07-01"
  end="2020-07-03"
  partition_key="experiment"
  partition_val="5678"
  expected=( 
    "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-01/experiment=5678/"
    "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-02/experiment=5678/"
    "s3://$bucket/v1/account_id=$account_id/type=decisions/date=2020-07-03/experiment=5678/"
  )

  BuildS3AbsolutePaths
  
  AreArraysEqual s3_absolute_paths expected
}

# ExecuteAWSCLICommand

@test "ExecuteAWSCLICommand with valid Optimizely api token" {
  export OPTIMIZELY_API_TOKEN="token"
  authenticated=false
  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl
  testcmd() { testcmdcalled=true; }

  # ExecuteAWSCLICommand should authenticate via the auth API, and then call testcmd
  ExecuteAWSCLICommand "testcmd"

  [ "$authenticated" = true ]
  [ "$testcmdcalled" = true ]
}

################################################################################
# Integration Tests                                                            #
################################################################################

@test "help command" {
  run "./$CLI_NAME" help
  [ "$status" = 0 ]
}

@test "auth command" {
  export OPTIMIZELY_API_TOKEN="token"

  curl() { echo "${valid_auth_api_response}200"; }
  export -f curl

  run "./$CLI_NAME" auth
  
  [ "$status" = 0 ]
  [ "${lines[0]}" = "export AWS_ACCESS_KEY_ID=$accessKeyId_stub" ]
  [ "${lines[1]}" = "export AWS_SECRET_ACCESS_KEY=$secretAccessKey_stub" ]
  [ "${lines[2]}" = "export AWS_SESSION_TOKEN=$sessionToken_stub" ]
  [ "${lines[3]}" = "export AWS_SESSION_EXPIRATION=$expiration_stub" ]
  [ "${lines[4]}" = "export S3_BASE_PATH=$s3Path_stub" ]
}

@test "paths command" {
  unset OPTIMIZELY_API_TOKEN

  run "./$CLI_NAME" paths --account-id 12345 --type decisions --start 2020-07-01 --end 2020-07-03 --experiment 56789

  [ "${lines[0]}" = "s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-01/experiment=56789/" ]
  [ "${lines[1]}" = "s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-02/experiment=56789/" ]
  [ "${lines[2]}" = "s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-03/experiment=56789/" ]

}

@test "ls command" {
  # Stub the aws command to echo itself
  unset OPTIMIZELY_API_TOKEN
  aws() { echo "aws $@"; }
  export -f aws

  run "./$CLI_NAME" ls --account-id 12345 --type decisions --start 2020-07-01 --end 2020-07-03 --experiment 56789

  [ "${lines[0]}" = "aws s3 ls --human-readable s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-01/experiment=56789/" ]
  [ "${lines[1]}" = "aws s3 ls --human-readable s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-02/experiment=56789/" ]
  [ "${lines[2]}" = "aws s3 ls --human-readable s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-03/experiment=56789/" ]
}

@test "load command" {
  # Stub the aws command to echo itself
  unset OPTIMIZELY_API_TOKEN
  aws() { echo "aws $@"; }
  export -f aws

  run "./$CLI_NAME" load --account-id 12345 --type decisions --start 2020-07-01 --end 2020-07-03 --experiment 56789 --output ./data

  [ "${lines[0]}" = "aws s3 sync s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-01/experiment=56789/ ./data/type=decisions/date=2020-07-01/experiment=56789" ]
  [ "${lines[1]}" = "aws s3 sync s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-02/experiment=56789/ ./data/type=decisions/date=2020-07-02/experiment=56789" ]
  [ "${lines[2]}" = "aws s3 sync s3://optimizely-events-data/v1/account_id=12345/type=decisions/date=2020-07-03/experiment=56789/ ./data/type=decisions/date=2020-07-03/experiment=56789" ]
}