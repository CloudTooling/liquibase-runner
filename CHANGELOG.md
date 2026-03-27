# [1.0.0](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.6...v1.0.0) (2026-03-27)


### Bug Fixes

* **deps:** update dependency org.liquibase:liquibase-core to v5 ([e4c162f](https://github.com/CloudTooling/liquibase-runner/commit/e4c162fba674c8a098ccb79141dc66228a31dcb5))


### Features

* **Java:** Use JDK17 ([63448bc](https://github.com/CloudTooling/liquibase-runner/commit/63448bc1349efdf55420245ed3b35d2195a79946)), closes [#40](https://github.com/CloudTooling/liquibase-runner/issues/40)
* **Liquibase:** Adding ITs for liquibase ([39aa854](https://github.com/CloudTooling/liquibase-runner/commit/39aa854b5edb0955e1d7bc1db37c07db1a5fd3d2)), closes [#40](https://github.com/CloudTooling/liquibase-runner/issues/40)
* **Liquibase:** Adding support for liquibase v5 ([9b0075d](https://github.com/CloudTooling/liquibase-runner/commit/9b0075d815f8bd771ec0e0e3d057ea43a0a09681)), closes [#40](https://github.com/CloudTooling/liquibase-runner/issues/40)


### BREAKING CHANGES

* **Java:** JDK11 support remove, as liquibase v5 needs 17 as requirement

## [0.2.6](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.5...v0.2.6) (2026-03-16)


### Bug Fixes

* **Logging:** Handle log level correct and disable debug logging ([ac3a85f](https://github.com/CloudTooling/liquibase-runner/commit/ac3a85f977464f40c69a93ae8d34bf4e9c610780)), closes [#37](https://github.com/CloudTooling/liquibase-runner/issues/37)

## [0.2.5](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.4...v0.2.5) (2026-03-06)


### Bug Fixes

* **Runner:** Correcting classpath handling ([7e0615c](https://github.com/CloudTooling/liquibase-runner/commit/7e0615c6ba355716a95925dd5f99360002e5fda1)), closes [#33](https://github.com/CloudTooling/liquibase-runner/issues/33)

## [0.2.4](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.3...v0.2.4) (2026-03-06)


### Bug Fixes

* **Classpath:** Correcting classpath order ([db89901](https://github.com/CloudTooling/liquibase-runner/commit/db89901693ffcb1eb1213db1177a72659d495148))

## [0.2.3](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.2...v0.2.3) (2026-02-17)


### Bug Fixes

* **Classpath:** Correcting classpath definition ([03295e6](https://github.com/CloudTooling/liquibase-runner/commit/03295e66dbad3703d9bd4df31f4890cddffd94df))
* **deps:** update logback monorepo to v1.5.32 ([#28](https://github.com/CloudTooling/liquibase-runner/issues/28)) ([043e428](https://github.com/CloudTooling/liquibase-runner/commit/043e4282e5e2af9a2822df139db352936004ddcc))

## [0.2.2](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.1...v0.2.2) (2026-02-16)


### Bug Fixes

* **Wrapper:** Correcting classpath config ([4d38435](https://github.com/CloudTooling/liquibase-runner/commit/4d3843551ab1be4d797bca5fc26e9bf734206fb3))


### Features

* **Logging:** Improve error logging ([25969b2](https://github.com/CloudTooling/liquibase-runner/commit/25969b22b2e347121fe54e0e7946a9959241b946))

## [0.2.1](https://github.com/CloudTooling/liquibase-runner/compare/v0.2.0...v0.2.1) (2026-02-16)


### Bug Fixes

* **Wrapper:** Correcting java execution ([825fc69](https://github.com/CloudTooling/liquibase-runner/commit/825fc69e1943cac1f359b8d249367388b41f8618))

# [0.2.0](https://github.com/CloudTooling/liquibase-runner/compare/v0.1.3...v0.2.0) (2026-02-16)


### Bug Fixes

* **deps:** update logback monorepo to v1.5.30 ([#21](https://github.com/CloudTooling/liquibase-runner/issues/21)) ([b281bc4](https://github.com/CloudTooling/liquibase-runner/commit/b281bc42b027f32b1bce2d78fa05654091227303))
* **deps:** update logback monorepo to v1.5.31 ([#22](https://github.com/CloudTooling/liquibase-runner/issues/22)) ([dd6749a](https://github.com/CloudTooling/liquibase-runner/commit/dd6749a123f076b51503d8faeccc83a9d620efa3))

## [0.1.3](https://github.com/CloudTooling/liquibase-runner/compare/v0.1.2...v0.1.3) (2026-02-13)


### Bug Fixes

* **Logging:** Correcting json logging ([fd08986](https://github.com/CloudTooling/liquibase-runner/commit/fd089860498acbbe400ec57503fdd8da338879c5))

## [0.1.2](https://github.com/CloudTooling/liquibase-runner/compare/v0.1.1...v0.1.2) (2026-02-13)


### Bug Fixes

* **Liquibase:** Read common properties from defaults file ([d94eeee](https://github.com/CloudTooling/liquibase-runner/commit/d94eeeea7eedbb5b4d7b4cb4bb942e23652387b7))
* **Logging:** Use ECS JSON logging ([6c1f359](https://github.com/CloudTooling/liquibase-runner/commit/6c1f3591196e6d240936337ebe3afebc0e542682))

## [0.1.1](https://github.com/CloudTooling/liquibase-runner/compare/v0.1.0...v0.1.1) (2026-02-13)


### Bug Fixes

* **deps:** update dependency net.logstash.logback:logstash-logback-encoder to v9 ([d27600f](https://github.com/CloudTooling/liquibase-runner/commit/d27600f5efd658185fb5a5ff07f6bb568308134a))
* **Logging:** Correct prefix timestamp ([c75253b](https://github.com/CloudTooling/liquibase-runner/commit/c75253b340916c0f4e0f605bdf0c8ceb5a5e79e8))

# [0.1.0](https://github.com/CloudTooling/liquibase-runner/compare/v0.0.3...v0.1.0) (2026-02-12)


### Bug Fixes

* **Logging:** Detect JSON and Pass Through ([8be3197](https://github.com/CloudTooling/liquibase-runner/commit/8be319726b94fccc7ba19e965f1da2fbab1c1bdd))

## [0.0.3](https://github.com/CloudTooling/liquibase-runner/compare/v0.0.2...v0.0.3) (2026-02-12)


### Bug Fixes

* **CLI:** Correcting arg handling via script ([e41939a](https://github.com/CloudTooling/liquibase-runner/commit/e41939acb11c7668ceb420f7d1397057e67bc822))
* **deps:** update dependency com.h2database:h2 to v2.4.240 ([#12](https://github.com/CloudTooling/liquibase-runner/issues/12)) ([c584e0a](https://github.com/CloudTooling/liquibase-runner/commit/c584e0a2b888dd50a794477c9cdf5f638756934c))
* **deps:** update dependency org.liquibase:liquibase-core to v4.31.1 ([#6](https://github.com/CloudTooling/liquibase-runner/issues/6)) ([32d3560](https://github.com/CloudTooling/liquibase-runner/commit/32d35609f812bc6abd690ecf7763159af05af9da))
* **deps:** update dependency org.liquibase:liquibase-core to v4.33.0 ([#13](https://github.com/CloudTooling/liquibase-runner/issues/13)) ([06ddc1e](https://github.com/CloudTooling/liquibase-runner/commit/06ddc1e606ca7fd5f0eb2a6c53841d09cb6a56f4))
* **deps:** update dependency org.slf4j:jul-to-slf4j to v2.0.17 ([#7](https://github.com/CloudTooling/liquibase-runner/issues/7)) ([a995162](https://github.com/CloudTooling/liquibase-runner/commit/a995162aa7b505dff7f08c26350f272a925f6bd7))
* **deps:** update logback monorepo to v1.5.28 ([#14](https://github.com/CloudTooling/liquibase-runner/issues/14)) ([89c0b0c](https://github.com/CloudTooling/liquibase-runner/commit/89c0b0c7148722a2c10fad87636365ccab08ca3f))
* **deps:** update logback monorepo to v1.5.29 ([#18](https://github.com/CloudTooling/liquibase-runner/issues/18)) ([6eefda1](https://github.com/CloudTooling/liquibase-runner/commit/6eefda1a72b6ec77e118e15eb097f0366297402c))
* **Package:** Include logging JARs ([fa007bb](https://github.com/CloudTooling/liquibase-runner/commit/fa007bb3b2bcee2a817fb18ce742e9933020f6bd))

## [0.0.2](https://github.com/CloudTooling/liquibase-runner/compare/v0.0.1...v0.0.2) (2026-02-04)


### Bug Fixes

* Adding missing logger ([4d08261](https://github.com/CloudTooling/liquibase-runner/commit/4d082616783835d09ea3a72c187d1a05a7e1466a))
* Correcting error handling ([628be08](https://github.com/CloudTooling/liquibase-runner/commit/628be087eb6fa0be76442f05a9a526dc395e8aae)), closes [#4](https://github.com/CloudTooling/liquibase-runner/issues/4)
* Default to JDK 11 compiling ([ded90e1](https://github.com/CloudTooling/liquibase-runner/commit/ded90e1723cb6484ae32e68793cf61f84c10910f)), closes [#5](https://github.com/CloudTooling/liquibase-runner/issues/5)

## 0.0.1 (2026-02-03)
