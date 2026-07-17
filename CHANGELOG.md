## v2.3.5 (2026-07-17)



## v2.3.4 (2026-07-17)



## v2.3.3 (2026-07-10)



## v2.3.2 (2026-07-09)

### Bug Fixes

* fix: fix Makefile lint path and shellcheck warnings (fabddfca2dfeaf68784fa61a256b0c38270a303b)

## v2.3.1 (2026-07-09)



## v2.3.0 (2026-07-09)

### Features

* feat: update CI workflow and add Makefile for linting and testing (a88711f9ffca3aab5f0e9455b3a7d81116606031)

## v2.2.2 (2026-07-09)

### Bug Fixes

* fix: update context-bar color to blue and restore powerline separators (ab209f90512454780b96dc4e6a26ac1f7452be12)

### Miscellaneous Chores

* other: Merge branch 'main' of github.com:heronlabs/code-sessions (6642515512e97ff2c159b518f6b4dbc715c18eed)

## v2.2.1 (2026-07-09)

### Bug Fixes

* fix: reverse ccstatusline settings symlink direction (#19) (f7ebe0c6eca60df2faeaf511163b8f45bc164e51)

## v2.2.0 (2026-07-09)

### Features

* feat: symlink ccstatusline config to live source (#18) (606917280fb560cedd7d463c3ffd5c0f5dd8067f)

## v2.1.0 (2026-07-08)

### Features

* feat: add ccstatusline config symlink (#17) (f6a7505b2e433e9bec6a7c1eabb9776d0fbc4bb2)

## v2.0.1 (2026-07-08)

### Bug Fixes

* fix: Fix check-balance.sh to parse balance_infos[0].total_balance instead of .balance to match real DeepSeek API response format (#16) (79a88aeca4da77e084ed61fb534cf323aab52433)

## v2.0.0 (2026-07-08)



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
