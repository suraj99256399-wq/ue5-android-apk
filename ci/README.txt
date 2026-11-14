This folder holds the GitHub Actions workflow so it can live in the repo
without needing the "workflow" token scope.

To enable CI, move it into place:

    mkdir -p .github/workflows
    git mv ci/github-workflow-build-android-apk.yml .github/workflows/build-android-apk.yml
    git commit -m "Enable Android APK workflow"
    git push

Pushing that path requires a token with the "workflow" scope, or you can do
it in the GitHub web UI: create .github/workflows/build-android-apk.yml and
paste the file's contents.
