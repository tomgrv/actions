<!-- @format -->

# Changelog

## 2.17.0 (2026-08-13)

_Commits from: v2.16.0..HEAD_

### 📂 Unscoped changes

#### Features

- ✨ update actions to use new repository paths and add filtering for private packages ([05f1fcc](https://github.com/tomgrv/actions/commit/05f1fcc4309a7edc5995f2f437fed5fc4e8fedad))

#### Other changes

- Merge tag 'v2.16.0' into develop ([90bc958](https://github.com/tomgrv/actions/commit/90bc958c0bec09fd34ecbc92c2914b144b66328b))

### 📦 list-packages changes

#### Features

- ✨ add npmjs registry publication status (#63) ([8e00928](https://github.com/tomgrv/actions/commit/8e00928d4d5f3e0a4521cd7de6a6b7848abc34b3))

## 2.16.0 (2026-08-13)

_Commits from: v2.15.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v2.15.0' into develop ([75ecd37](https://github.com/tomgrv/actions/commit/75ecd379bddca8376733d98623e3561e77b918aa))
- 🚨 Add comprehensive BATS test suite for composite actions (#61) ([a76920e](https://github.com/tomgrv/actions/commit/a76920e856c8cc94134c58e6eff03af77b755a18))

### 📦 publish-npm changes

#### Bug Fixes

- 🐛 avoid ENOWORKSPACES when publishing a workspace member (#59) ([07a99bd](https://github.com/tomgrv/actions/commit/07a99bd0eea27602d48e8425eb45770b8e2042d6))

### 📦 run-deployer changes

#### Bug Fixes

- 🐛 classify reviewdog diagnostics by content, not host prefix (#60) ([90b1c00](https://github.com/tomgrv/actions/commit/90b1c0011e93fc1776455de003f2f1dde2b2987d))

## 2.15.0 (2026-08-12)

_Commits from: v2.14.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 handle empty PR title on PR open event (#58) ([1068f72](https://github.com/tomgrv/actions/commit/1068f725148cc3c3ba41b9bd82b7c2b76993d58e))

#### Features

- ✨ add publish-npm GitHub Action for npm trusted publishers (#57) ([a8d35ce](https://github.com/tomgrv/actions/commit/a8d35ce7f78a0e667d994cac71e450dde077d8c6))

#### Other changes

- Merge tag 'v2.14.0' into develop ([9945d58](https://github.com/tomgrv/actions/commit/9945d5872eb9cf19b3121c0e3fa63a9ea69b9d59))

## 2.14.0 (2026-08-12)

_Commits from: v2.13.4..HEAD_

### 📂 Unscoped changes

#### Features

- make npm install silent and display commitlint output as notice (#53) ([87136a5](https://github.com/tomgrv/actions/commit/87136a52649610a1d6aa04c2273b98a89f4568f3))
- ✨ add check-dockerfile action with 6 best practices (#56) ([9fc98ee](https://github.com/tomgrv/actions/commit/9fc98ee03794949f7a5d5298b73e3629e8e8a418))

#### Other changes

- Merge tag 'v2.13.0' into develop ([b394b93](https://github.com/tomgrv/actions/commit/b394b934d291d19106c618b45a101d250843a4c0))
- Merge tag 'v2.13.1' into develop ([726e91b](https://github.com/tomgrv/actions/commit/726e91b0cf194c800573e88113e7c06123374f61))
- Merge tag 'v2.13.2' into develop ([6b2ddc6](https://github.com/tomgrv/actions/commit/6b2ddc680c2c312e3b041f1b49b5861c28380b82))
- Merge tag 'v2.13.3' into develop ([97c58c1](https://github.com/tomgrv/actions/commit/97c58c10ac293847062d91647276009f852e5b46))
- Merge tag 'v2.13.4' into develop ([bafa5e3](https://github.com/tomgrv/actions/commit/bafa5e35b2d1993cfe02ebac3d220a374da38a96))
- 🔧 update devcontainer ([07a0028](https://github.com/tomgrv/actions/commit/07a002890d3f4c41bb37b3cf5c33041b41009b88))

### 📦 run-deployer changes

#### Features

- report successful deploys as reviewdog notices (#54) ([d09166f](https://github.com/tomgrv/actions/commit/d09166f0b99987872c160d39bef9ebed0411a11b))

## 2.13.4 (2026-08-11)

_Commits from: v2.13.3..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 ensure proper exit on commitlint and title validation errors ([d7d1c1b](https://github.com/tomgrv/actions/commit/d7d1c1bb3e92e6dba6b79ddfa47b70f30a3228b8))

## 2.13.3 (2026-08-11)

_Commits from: v2.13.2..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 multiline error annotation escaping in check-pr-format (#51) ([cb2d85f](https://github.com/tomgrv/actions/commit/cb2d85f3eaff9d27bfc3313c934895d31d1b4cd8))

## 2.13.2 (2026-08-11)

_Commits from: v2.13.1..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 ensure commitlint output is captured correctly ([b912501](https://github.com/tomgrv/actions/commit/b9125010ede63f81cfae40491f9dedd75c03eb9f))

## 2.13.1 (2026-08-11)

_Commits from: v2.13.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 allow commitlint errors to be reported without exiting script ([cfaaac6](https://github.com/tomgrv/actions/commit/cfaaac678afc9b38b067d112afc97e07a93adcd8))

## 2.13.0 (2026-08-11)

_Commits from: v2.12.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- Consolidate check-title error annotations into single annotation (#50) ([826f3ef](https://github.com/tomgrv/actions/commit/826f3efd393342439eeb80a9f2f1241e551f3e75))

#### Other changes

- Merge tag 'v2.12.0' into develop ([1d46820](https://github.com/tomgrv/actions/commit/1d46820869ada9c9578745a06b7131819b1fb8cd))
- 🔧 update devcontainer ([95c74ea](https://github.com/tomgrv/actions/commit/95c74eae15574b54ee25685db0fa21f6c79aeafc))

## 2.12.0 (2026-08-11)

_Commits from: v2.11.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- add type parameter to setup-reviewdog and aggregate run-deployer errors (#48) ([3c227ae](https://github.com/tomgrv/actions/commit/3c227aeca4de73458596d2fed21554b8d165c88b))

#### Other changes

- Merge tag 'v2.11.0' into develop ([527eb51](https://github.com/tomgrv/actions/commit/527eb51f71e4e5bb9ff804812c7983a5ea18fb95))
- improve run.sh diagnostics for unexplained exit 1 (#46) ([71124e3](https://github.com/tomgrv/actions/commit/71124e3cd36a7245d8a37dcbc1a0849160c9f2ec))
- ♻️ update run command syntax for consistency ([a39dc45](https://github.com/tomgrv/actions/commit/a39dc453d546b42dd7dae3c3f5c8ba5685bb98b9))
- 🔧 swap positions of caveman and copilot-plugins in marketplace list ([a0a9e3d](https://github.com/tomgrv/actions/commit/a0a9e3d7cbc345b153b211c9f34a6fff7da59f16))
- 🔧 update devcontainer ([6eee575](https://github.com/tomgrv/actions/commit/6eee5751955563dd0d1d7b91ee0fc7d40f8f3682))

### 📦 check-pr-format changes

#### Bug Fixes

- autocorrect PR title before validating (#49) ([b7f4444](https://github.com/tomgrv/actions/commit/b7f4444f3da4ee939a6431a141b2434eda5f4d56))

### 📦 check-security-composer changes

#### Other changes

- ♻️ change shell from bash to sh for running audit ([a936df7](https://github.com/tomgrv/actions/commit/a936df7c47c123f9d9a65f898f7dd147a611438b))

### 📦 release changes

#### Other changes

- 🚀 2.12.0 ([62a3195](https://github.com/tomgrv/actions/commit/62a3195ba34d3d42c45b9384fd3dc246bebc5499))

### 📦 reviewdog changes

#### Bug Fixes

- fix filter-mode by convention, resolve reporter/token by run context (#47) ([4378688](https://github.com/tomgrv/actions/commit/4378688bbe91e65ef1474666f7258f576f5c08b2))

### 📦 run-phpstan changes

#### Other changes

- 🔧 add logging for PHPStan stdout/stderr output ([32871c9](https://github.com/tomgrv/actions/commit/32871c9491dda2512f36d71de4b68b527b37d68f))
- 🔧 update default reviewdog flags to include '-tee' ([ded3109](https://github.com/tomgrv/actions/commit/ded3109f33a3b2ced25cac2075e830255bd1618d))

## 2.12.0 (2026-08-11)

_Commits from: v2.11.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- add type parameter to setup-reviewdog and aggregate run-deployer errors (#48) ([3c227ae](https://github.com/tomgrv/actions/commit/3c227aeca4de73458596d2fed21554b8d165c88b))

#### Other changes

- Merge tag 'v2.11.0' into develop ([527eb51](https://github.com/tomgrv/actions/commit/527eb51f71e4e5bb9ff804812c7983a5ea18fb95))
- improve run.sh diagnostics for unexplained exit 1 (#46) ([71124e3](https://github.com/tomgrv/actions/commit/71124e3cd36a7245d8a37dcbc1a0849160c9f2ec))
- ♻️ update run command syntax for consistency ([a39dc45](https://github.com/tomgrv/actions/commit/a39dc453d546b42dd7dae3c3f5c8ba5685bb98b9))
- 🔧 swap positions of caveman and copilot-plugins in marketplace list ([a0a9e3d](https://github.com/tomgrv/actions/commit/a0a9e3d7cbc345b153b211c9f34a6fff7da59f16))
- 🔧 update devcontainer ([6eee575](https://github.com/tomgrv/actions/commit/6eee5751955563dd0d1d7b91ee0fc7d40f8f3682))

### 📦 check-pr-format changes

#### Bug Fixes

- autocorrect PR title before validating (#49) ([b7f4444](https://github.com/tomgrv/actions/commit/b7f4444f3da4ee939a6431a141b2434eda5f4d56))

### 📦 check-security-composer changes

#### Other changes

- ♻️ change shell from bash to sh for running audit ([a936df7](https://github.com/tomgrv/actions/commit/a936df7c47c123f9d9a65f898f7dd147a611438b))

### 📦 reviewdog changes

#### Bug Fixes

- fix filter-mode by convention, resolve reporter/token by run context (#47) ([4378688](https://github.com/tomgrv/actions/commit/4378688bbe91e65ef1474666f7258f576f5c08b2))

### 📦 run-phpstan changes

#### Other changes

- 🔧 add logging for PHPStan stdout/stderr output ([32871c9](https://github.com/tomgrv/actions/commit/32871c9491dda2512f36d71de4b68b527b37d68f))
- 🔧 update default reviewdog flags to include '-tee' ([ded3109](https://github.com/tomgrv/actions/commit/ded3109f33a3b2ced25cac2075e830255bd1618d))

## 2.11.0 (2026-08-10)

_Commits from: v2.10.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v2.10.0' into develop ([53cce4f](https://github.com/tomgrv/actions/commit/53cce4fe856daa1d0a682b057e54edc30d6cf083))
- move composer bin PATH setup into setup-php (#45) ([f7c445a](https://github.com/tomgrv/actions/commit/f7c445ae1be5447f1874dc765b9e965ff8570d24))
- 🔧 remove Claude Code workflow file ([d00ae4d](https://github.com/tomgrv/actions/commit/d00ae4d2b9a75efd29ecb8c947a40fd00cf4fb9d))

## 2.10.0 (2026-08-09)

_Commits from: v2.9.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v2.9.0' into develop ([61351ab](https://github.com/tomgrv/actions/commit/61351ab212a93ea7213ac72c13f8615ef975bb23))
- uniformize logging, drop npm CLI distribution, add actions dependabot (#43) ([a9f7d8b](https://github.com/tomgrv/actions/commit/a9f7d8b7e0332b22f9a4f04e7cb0db24fa1e6dd2))

## 2.9.0 (2026-08-09)

_Commits from: v2.8.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v2.8.0' into develop ([2c9d9ca](https://github.com/tomgrv/actions/commit/2c9d9ca0a04347921a9ac1d4180d020496317519))

### 📦 run-phpstan changes

#### Bug Fixes

- 🐛 handle PHPStan output errors and warnings ([5e01ffa](https://github.com/tomgrv/actions/commit/5e01ffa1d266b1aac85b582e24e63c9b7228b067))

## 2.8.0 (2026-08-09)

_Commits from: v2.7.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v2.7.0' into develop ([f7a0c10](https://github.com/tomgrv/actions/commit/f7a0c109ed254c84d49d0260644f50a29290aced))

### 📦 check-filament changes

#### Bug Fixes

- 🐛 add conditional execution for FilaCheck based on input path ([83f1998](https://github.com/tomgrv/actions/commit/83f1998e8aee267c8e0d2dc77f19a0e7aead5a14))

### 📦 check-laravel changes

#### Bug Fixes

- 🐛 change default for tests input to false ([0caeabf](https://github.com/tomgrv/actions/commit/0caeabfb5c398a4eb131ed8598391e3fb5c52ba8))
- 🐛 set default for phpinsights to false ([fd0c809](https://github.com/tomgrv/actions/commit/fd0c809f8eb2b6cc8ead12c93817e556b458b2f0))
- 🐛 update paths input description to clarify filtering behavior ([6439f94](https://github.com/tomgrv/actions/commit/6439f94ad582d59c62ad1bfc989fb40032e21b9e))

#### Features

- ✨ add PR creation step for automatic fixes in fix mode ([d42c427](https://github.com/tomgrv/actions/commit/d42c4274f2929184a322784bc8a5d0e696bcf317))

### 📦 check-lock changes

#### Features

- ✨ add setup steps for PHP and Node toolchains ([195981f](https://github.com/tomgrv/actions/commit/195981facb931ed74bda335f75689661d6ca6a44))

### 📦 run-phpstan changes

#### Bug Fixes

- 🐛 validate PHPStan output and ensure binaries exist ([766fa87](https://github.com/tomgrv/actions/commit/766fa87da66e7cf56a635a4b687c8ad73cb151b3))

### 📦 setup-node changes

#### Features

- ✨ add bare input option to skip npm ci step ([436071a](https://github.com/tomgrv/actions/commit/436071a1101508a23c041bd92447480540d51cb4))

### 📦 setup-php changes

#### Features

- ✨ add bare input option to skip composer install step ([1655386](https://github.com/tomgrv/actions/commit/1655386f48b5907af9b15ca92944c2eaae2e13d0))

## 2.7.0 (2026-08-09)

_Commits from: v2.6.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- find and report version fixes reliably (#41) ([0189b29](https://github.com/tomgrv/actions/commit/0189b294a2e9aaf1bcfde51e00392db66d48f2e8))
- 🐛 add conditional checks for PHP version and extensions extraction ([a6c750b](https://github.com/tomgrv/actions/commit/a6c750b089070950e11d146759c7d1c6ca85ad01))

#### Features

- ✨ add dirty/wip flags to PHP check actions (#42) ([17925db](https://github.com/tomgrv/actions/commit/17925dbd1f55a56830b58becc87a4d2bb5563ccc))

#### Other changes

- Merge tag 'v2.6.0' into develop ([f5f796c](https://github.com/tomgrv/actions/commit/f5f796ce7b893ef43a92a9f466e90592fa9ffe5e))

## 2.6.0 (2026-08-08)

_Commits from: v2.5.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- scope git auth header to degit-package clone, not global config (#40) ([cff6ba8](https://github.com/tomgrv/actions/commit/cff6ba80e57772fd802bcde03b86ded1a4960de4))

#### Features

- default github-token input to github.token across actions (#38) ([940053b](https://github.com/tomgrv/actions/commit/940053bc9fbeff129be8e7de7de06ca7e92d7733))
- ✨ move global php tool installs into setup-php's require.sh (#37) ([1a010a2](https://github.com/tomgrv/actions/commit/1a010a26354f3515716f78614da846f0f7ce61dc))

#### Other changes

- Merge tag 'v2.5.0' into develop ([b6600c2](https://github.com/tomgrv/actions/commit/b6600c2a26eb523b01d08dacb57d65c19890e61e))
- 🔧 update devcontainer ([b4749f0](https://github.com/tomgrv/actions/commit/b4749f095d8237884b072a61e841ff60aeed2ffe))

## 2.5.0 (2026-08-08)

_Commits from: v2.4.0..HEAD_

### 📂 Unscoped changes

#### Features

- add run-deployer composite action (#36) ([56ee1e8](https://github.com/tomgrv/actions/commit/56ee1e88c82c3f4318724eeff383b857b5ed013a))

#### Other changes

- Merge tag 'v2.4.0' into develop ([ecd4152](https://github.com/tomgrv/actions/commit/ecd4152b83a8bb181faad4122d40ae507e472b25))
- ♻️ update devcontainer ([d070805](https://github.com/tomgrv/actions/commit/d070805f63dcfc9fde226cd9e4791ce3abcfb08a))

## 2.4.0 (2026-08-07)

_Commits from: v2.3.0..HEAD_

### 📂 Unscoped changes

#### Bug Fixes

- 🐛 reduce max diagnostics to comply with GitHub annotation limits ([81bd1f1](https://github.com/tomgrv/actions/commit/81bd1f135d8f4f03c895ba5e19dc77ce6ba05359))

#### Features

- auto-detect root config files for phpmd, phpstan, pint and phpinsights (#35) ([a046aa3](https://github.com/tomgrv/actions/commit/a046aa345b8561548bdb0a35c870f682f5e420ee))

#### Other changes

- Merge tag 'v2.3.0' into develop ([7a4bd26](https://github.com/tomgrv/actions/commit/7a4bd267e39a48b2ab6835a4d57998f0f4e80924))

### 📦 check-security-npm, check-security-composer changes

#### Bug Fixes

- cap reviewdog diagnostics to avoid annotation limit (#34) ([2bcc88e](https://github.com/tomgrv/actions/commit/2bcc88e6d083e540047e4086ef262dd31c06e249))

## 2.3.0 (2026-08-07)

_Commits from: v2.2.0..HEAD_

### 📂 Unscoped changes

#### Features

- allow overriding reviewdog check name across reviewdog-based actions (#32) ([612003d](https://github.com/tomgrv/actions/commit/612003d00f06e18537cbdce29de23644733f5b3c))

#### Other changes

- Merge tag 'v2.2.0' into develop ([628c1fb](https://github.com/tomgrv/actions/commit/628c1fbb41c967179525afe42edbe0aeadc300c1))

### 📦 check-security changes

#### Bug Fixes

- rationalize audit annotations and suggest version fixes (#33) ([2cda0a1](https://github.com/tomgrv/actions/commit/2cda0a1e8538f32afdb4ee1e87179ad9becd1e69))

## 2.2.0 (2026-08-05)

_Commits from: v2.1.0..HEAD_

### 📂 Unscoped changes

#### Features

- align PHP/Node/reviewdog setup and add check-laravel/check-filament suite wrappers (#31) ([e7bc605](https://github.com/tomgrv/actions/commit/e7bc6056946dd3ac1f69ae754d4727040aad62a4))

#### Other changes

- Merge tag 'v2.1.0' into develop ([f13f069](https://github.com/tomgrv/actions/commit/f13f069d78a2516bc22c5761cd8b723a45a8cd2e))

### 📦 degit-package changes

#### Bug Fixes

- fix exclude-args subshell bug breaking change detection (#30) ([99b833b](https://github.com/tomgrv/actions/commit/99b833b6a0064aece4b11c94123be9ac05808d9f))

## 2.1.0 (2026-08-04)

_Commits from: v2.0.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v2.0.0' into develop ([bca7431](https://github.com/tomgrv/actions/commit/bca74317a48ef53cceaeca75aebd023578a538ca))

### 📦 setup-node changes

#### Bug Fixes

- 🐛 allow additional install arguments for npm command ([889c8ba](https://github.com/tomgrv/actions/commit/889c8ba136de57fcb24fecc70541913e1551680f))

## 2.0.0 (2026-08-04)

_Commits from: v1.4.0..HEAD_

### 💥 BREAKING CHANGES

- check-composer is deleted. Replace ([6fda6e9](https://github.com/tomgrv/actions/commit/6fda6e9fae686d3b0d8bdeb95b9950284242d52b))

### 📂 Unscoped changes

#### Other changes

- Merge tag 'vv1.4.0' into develop ([ed6d749](https://github.com/tomgrv/actions/commit/ed6d749c9faa42efa0a4d4a3a622be493b6c44a7))

## 1.4.0 (2026-08-02)

_Commits from: v1.3.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- Merge tag 'v1.3.0' into develop ([4fc5d32](https://github.com/tomgrv/actions/commit/4fc5d326c6dc366840745090475fc818a5e35443))
- 🔧 update feature versions for githooks, gitutils, and gitversion ([b0e31c5](https://github.com/tomgrv/actions/commit/b0e31c5b63dede35f2bcd3fdec7dba7181160a11))

### 📦 run-phptests changes

#### Bug Fixes

- 🐛 handle PHP test runs properly (#28) ([9181131](https://github.com/tomgrv/actions/commit/91811311b1d0152dbb3e5febf9afb9718337886b))

## 1.3.0 (2026-05-18)

_Commits from: v1.2.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- add FilaCheck composite action for Filament checks (#27) ([00d4404](https://github.com/tomgrv/actions/commit/00d440442b9a8f753703da5b036d0e78791e71c5))
- ♻️ expose php tools and simplify binary resolution (#23) ([3007e11](https://github.com/tomgrv/actions/commit/3007e11e4694cce5eba64544c5b6add654c14503))
- Merge tag 'v1.2.0' into develop ([45dc494](https://github.com/tomgrv/actions/commit/45dc494600b5195c4713a03b94153a5518fe7748))
- 🔧 update actions to v1 for setup-php, setup-node, list-packages, config-bot, and split-package ([c2c5820](https://github.com/tomgrv/actions/commit/c2c58201901fb72aae64669c4025cd3abf153f61))
- ♻️ update file patterns for workspace packages ([cc192e6](https://github.com/tomgrv/actions/commit/cc192e685e6a5966c7a30f6d6805fa9b550b895b))

## 1.2.0 (2026-05-08)

_Commits from: v1.1.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- 🐛 add conditional for lock files before installing dependencies ([ff4ed52](https://github.com/tomgrv/actions/commit/ff4ed5229c48d7040b9d9780c0c79a27633a1d4d))
- ✨ add confirm comment action with reaction functionality ([da9e03f](https://github.com/tomgrv/actions/commit/da9e03f31b031d8297948c73edb822f7dca15410))
- add detect-changes composite action (#19) ([ad019be](https://github.com/tomgrv/actions/commit/ad019be963732ec9daa38307270091fd90311375))
- ✨ add rebase-pr composite action ([62a4c38](https://github.com/tomgrv/actions/commit/62a4c384062a44f87eab24aa37e597222541dc5e))
- 🐛 case-insensitive label name matching (#14) ([a0e3970](https://github.com/tomgrv/actions/commit/a0e397026642fb10bf61adff868d556be382be35))
- Merge tag 'v1.1.0' into develop ([fa4703d](https://github.com/tomgrv/actions/commit/fa4703d9f5be500d72c8405c701af6569034a834))
- review, test and cleanup (#21) ([59afcda](https://github.com/tomgrv/actions/commit/59afcda7f75c4ada4e71d374b8f49992bdad2694))
- 🔧 update devcontainer ([94efaf0](https://github.com/tomgrv/actions/commit/94efaf01817e9b2d8a87db0a1ad87d990d35c385))
- 🔧 update devcontainer ([ffe7ca3](https://github.com/tomgrv/actions/commit/ffe7ca3dba22fcfcf0389db88d5a2712edb45c87))
- 📚️ update README with badges and color reference (#12) (#13) ([f87b05b](https://github.com/tomgrv/actions/commit/f87b05b1fbb8644fd2f816edbe67ac59698dbf27))

## 1.1.0 (2026-05-01)

_Commits from: v1.0.1..HEAD_

### 📂 Unscoped changes

#### Features

- ✨ add degit and split packages workflows ([f4c11b2](https://github.com/tomgrv/actions/commit/f4c11b2969af2dee980e1ee51be69a0a76cf6bcc))
- ✨ add labels ([5e2f6f4](https://github.com/tomgrv/actions/commit/5e2f6f44136a6c21fde24fa1aa5baf81a9f7b716))
- ✨ add new labels and update README and action configuration ([ee1fc6d](https://github.com/tomgrv/actions/commit/ee1fc6d4dd15da16e7ffee38e9611b4b7382eaf2))
- ✨ add update-labels action for managing repository labels ([11652a1](https://github.com/tomgrv/actions/commit/11652a1a01c75daf1d32cde7e60d26abce1f135a))

#### Other changes

- 📚️ fix typo in action description ([8ad6fa7](https://github.com/tomgrv/actions/commit/8ad6fa7bd8f72caabf8ee852b94817c9291fdd8b))
- Merge tag 'v1.0.0' into develop ([76ef44c](https://github.com/tomgrv/actions/commit/76ef44caf4ecf510aeb543751dec4490faee109d))
- Merge tag 'v1.0.1' into develop ([fb52683](https://github.com/tomgrv/actions/commit/fb5268316523571a0a7a1702e7db61e058dff3a3))
- ♻️ remove old split-package directory (renamed to split-packages) ([6053411](https://github.com/tomgrv/actions/commit/605341134d4a6c21b571635bd2937f682b7b6101))
- 🔧 remove unused output definitions ([a037c09](https://github.com/tomgrv/actions/commit/a037c09284a21e13e86694f009b5101ea8da514b))
- ♻️ rename split-package to split-packages ([65f9361](https://github.com/tomgrv/actions/commit/65f93613640e584466e3e4e5e3f1ab3cfd90afc9))
- 📚️ update all action README files for consistency ([fc0ea61](https://github.com/tomgrv/actions/commit/fc0ea61d4a7aa0d59adea597d46cc2dc499d1833))
- 👷 update feature definitions & test script ([1115723](https://github.com/tomgrv/actions/commit/111572368a95b0b4ab505727b8bfa16f1301a191))
- 📚️ update gitleaks-license description for clarity ([96d66b0](https://github.com/tomgrv/actions/commit/96d66b09517b323ce705fd26ef5b5e6e612e49d4))
- 📚️ update README and action description for clarity ([da1ace0](https://github.com/tomgrv/actions/commit/da1ace06e8a5379ec004e3317e8e05bc147c937d))

## 1.0.1 (2026-04-30)

_Commits from: v1.0.0..HEAD_

### 📂 Unscoped changes

#### Other changes

- 📚️ update README for clarity and consistency in input descriptions ([f0aa7f5](https://github.com/tomgrv/actions/commit/f0aa7f5cea75ef0e269cafe2c3817f3cfe0055c7))

## 1.0.0 (2026-04-30)

_Commits from: v0.2.0..HEAD_

## 0.1.0 (2026-04-30)

_Commits from: 7de041a1f6cc92abe82b86a200dfa0df0a404d7e..HEAD_

### 📂 Unscoped changes

#### Features

- ✨ initialize devcontainer setup with scripts and configurations ([76a1672](https://github.com/tomgrv/actions/commit/76a167222cb4439c16c97013ea6f3d85f09cc8d2))

#### Other changes

- import from monorepo perspikapps/flekskit (#4) ([6f53a6f](https://github.com/tomgrv/actions/commit/6f53a6f8edb7721d1ad674e432488838f2c54b4c))

---

_Generated on 2026-08-13 by [tomgrv/devcontainer-features](https://github.com/tomgrv/devcontainer-features)_
