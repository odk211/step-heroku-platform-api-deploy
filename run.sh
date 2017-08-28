#!/bin/bash

set -eu

dig_json() {
  local keys
  keys=$(echo "$*" | tr ' ' '\n' | awk '{keys=keys"[\""$1"\"]"}END{print keys}')
  python -c "import sys, json; print(json.load(sys.stdin)${keys})"
}

main() {
  local app_name=${WERCKER_HEROKU_PLATFORM_API_DEPLOY_APP_NAME:?"app-name is required"}
  local heroku_key=${WERCKER_HEROKU_PLATFORM_API_DEPLOY_KEY:?"key is required"}

  if [ -n "${WERCKER_HEROKU_PLATFORM_API_DEPLOY_VERSION}" ]; then
    local heroku_version=${WERCKER_HEROKU_PLATFORM_API_DEPLOY_VERSION}
  else
    info "version is not set. use WERCKER_GIT_COMMIT value"
    local heroku_version=${WERCKER_GIT_COMMIT}
  fi

  if [ -n "${WERCKER_HEROKU_PLATFORM_API_DEPLOY_SOURCE_BLOB}" ]; then
    local source_blob=${WERCKER_HEROKU_PLATFORM_API_DEPLOY_SOURCE_BLOB}
  else
    local source_blob=source-blob.tar.gz
    info "source-blob is not set. generate source-blob with \`git archive --format=tar.gz -o ${source_blob} HEAD\` command"
    git archive --format=tar.gz -o ${source_blob} HEAD
  fi

  info "Deploying Heroku Version ${heroku_version}"

  local source_blob_json
  source_blob_json=$(curl -s -n -X POST https://api.heroku.com/sources \
    -H 'Accept: application/vnd.heroku+json; version=3' \
    -H "Authorization: Bearer ${heroku_key}")

  local put_url get_url
  put_url=$(echo "${source_blob_json}" | dig_json source_blob put_url)
  get_url=$(echo "${source_blob_json}" | dig_json source_blob get_url)

  curl "${put_url}" -X PUT -H 'Content-Type:' --data-binary "@${source_blob}"

  local req_data="{\"source_blob\": {\"url\":\"${get_url}\", \"version\": \"${heroku_version}\"}}"
  local build_output
  build_output=$(curl -s -n -X POST "https://api.heroku.com/apps/${app_name}/builds" \
    -d "${req_data}" \
    -H 'Accept: application/vnd.heroku+json; version=3' \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${heroku_key}")

  local build_id output_stream_url
  build_id=$(echo "${build_output}" | dig_json id)
  output_stream_url=$(echo "${build_output}" | dig_json output_stream_url)

  curl "${output_stream_url}"

  build_status=$(curl -s -n "https://api.heroku.com/apps/${app_name}/builds/${build_id}" \
    -H 'Accept: application/vnd.heroku+json; version=3' \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${heroku_key}" \
    | dig_json status)

  if [ "${build_status}" = "failed" ]; then
    fail "heroku build failed"
  fi
}

main
