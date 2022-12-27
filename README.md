# Appcircle _BrowserStack App Automate - XCUI_ component

Run your XCUI tests on BrowserStack App Automate

## Required Inputs

- `AC_BROWSERSTACK_USERNAME`: BrowserStack username. Username of the BrowserStack account.
- `AC_BROWSERSTACK_ACCESS_KEY`: BrowserStack access key. Access key for the BrowserStack account.
- `AC_TEST_IPA_PATH`: Path of the build. Full path of the ipa file
- `AC_UITESTS_RUNNER_PATH`: Path of the output bundle. Full path of the *-Runner.app.
- `AC_BROWSERSTACK_TIMEOUT`: Timeout. BrowserStack plan timeout in seconds

## Optional Inputs

- `AC_BROWSERSTACK_PAYLOAD`: Build Payload. `AC_BROWSERSTACK_APP_URL` and `AC_BROWSERSTACK_TEST_URL` will be auto generated. Please check [documentation](https://www.browserstack.com/docs/app-automate/api-reference/xcuitest/builds#execute-a-build) for more details about the payload.
