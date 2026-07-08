## v1.0.2 (2026-07-08)

### Features

* feat: Create src/check-balance.sh to check DeepSeek API balance with bats tests (#12) (bd1723c702c94dbdd4a16dd9e1ef33593a64f3cf)

### Bug Fixes

* fix: update settings file reference from claude-deepseek-settings.json to claude-api-settings.json (fd169841974d08e55b139d297c67a09e341457a2)
* fix: add .worktrees to .gitignore (5fae742a36aa4176e56ddd11ceb9b30eea2c6cf0)

### Miscellaneous Chores

* other: Bump actions/checkout from 4 to 7 in the actions group (#10) (0c34c5c244c8ae2ad11f09b11e53258a54098f0e)

# Changelog

## [1.0.1](https://github.com/heronlabs/code-sessions/compare/v1.0.0...v1.0.1) (2026-06-26)


### Bug Fixes

* rename CD workflow, add CI permissions and concurrency ([#8](https://github.com/heronlabs/code-sessions/issues/8)) ([975bb78](https://github.com/heronlabs/code-sessions/commit/975bb78b13dc7d929445eb652f12dc5b5dc2e78b))

## 1.0.0 (2026-06-25)


### Features

* add CI/CD with shellcheck, bats tests, and release-please ([74824bc](https://github.com/heronlabs/code-sessions/commit/74824bcb485c4ad9ac3841b1b9d0cb36f59d69a7))


### Bug Fixes

* **ci:** use PAT token for release-please to bypass org-level PR creation restriction ([#4](https://github.com/heronlabs/code-sessions/issues/4)) ([07f0df9](https://github.com/heronlabs/code-sessions/commit/07f0df967603e2aefab2d6ef2d97275e1ad6f756))
