# step-heroku-platform-api-deploy

[![wercker status](https://app.wercker.com/status/c4725867891ca5e261c8a7b06a0ff657/m "wercker status")](https://app.wercker.com/project/bykey/c4725867891ca5e261c8a7b06a0ff657)

Deploy to Heroku like [wercker/step-heroku-deploy](https://github.com/wercker/step-heroku-deploy), but this step use [Heroku Platform API](https://devcenter.heroku.com/articles/platform-api-reference) instead of `heroku toolbelt`.  
This step do not support `run` option. If you want to run a command on heroku after deployment, use [Heroku Release Phase](https://devcenter.heroku.com/articles/release-phase).

# Options:

- `key` (required) Heroku API Key.
- `app-name` (required) Heroku application name.
- `version` (optional) Heroku application version for this deployment. Default `${WERCKER_GIT_COMMIT}`.
- `source-blob` (optional) Path to the source archive.  
  If left empty, the archive created by `git archive --format=tar.gz -o source-blob.tar.gz HEAD` is used.

# Example

```
deploy:
  steps:
    - odk211/heroku-platform-api-deploy:
        key: ${HEROKU_KEY}
        app-name: ${HEROKU_APP_NAME}
```

