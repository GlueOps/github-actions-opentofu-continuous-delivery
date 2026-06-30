# Changelog

## [6.1.1](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/compare/v6.1.0...v6.1.1) (2026-06-30)


### Bug Fixes

* authenticate release-please via GitHub App token ([#149](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/issues/149)) ([d8baf59](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/commit/d8baf59804375f43b073fbbfe40c469009444cdf))


### Continuous Integration

* bring release-please config up to GlueOps convention ([#151](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/issues/151)) ([9a04546](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/commit/9a045467d6134b801f50bee491056225049c0228))

## [6.1.0](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/compare/v6.0.0...v6.1.0) (2026-06-26)


### Features

* trigger 6.1.0 release ([#146](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/issues/146)) ([9a32c2b](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/commit/9a32c2babe1fbdfaa0aac674b59c3b612205f8c7))

## [6.0.0](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/compare/v5.1.0...v6.0.0) (2026-06-26)


### ⚠ BREAKING CHANGES

* the enable_slack_notification_for_approval input has been removed from the action's interface. In practice it was already ignored, and GitHub silently ignores undeclared 'with:' inputs, so existing workflows that still set it will continue to run. It is flagged as breaking because a documented input has been removed from the public API.

### Features

* remove Slack notification surface entirely ([#142](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/issues/142)) ([68b344a](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/commit/68b344a362fb1180e1ab7a0441eba8b753246064))

## [5.1.0](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/compare/v5.0.0...v5.1.0) (2026-06-26)


### Features

* refresh stale versions in README usage examples ([#140](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/issues/140)) ([9641b88](https://github.com/GlueOps/github-actions-opentofu-continuous-delivery/commit/9641b88643f5fba71b40d0f925d23ab2d3e2380f))
