[![Build Status](https://secure.travis-ci.org/simp/rubygem-simp-module-repoclosure.svg?branch=master)](https://travis-ci.org/simp/rubygem-simp-module-repoclosure)
[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
# simp-module-repoclosure

A ~~stupidly~~ admirably direct repoclosure for a Puppet module's `metadata.json`.  Test your modules's dependency declarations by committing **Puppet Forgery!**

#### Table of Contents
1. [Overview](#overview)
2. [Setup](#setup)
* [Beginning with simp-module-repoclosure](#beginning-with-simp-module-repoclosure)
3. [Methods](#methods)
4. [Environment variables](#environment-variables)
5. [Examples](#examples)
6. [License](#license)

## Overview

This gem validates the dependencies declared in a Puppet module's `metadata.json`.
  * It does this by by running `puppet module install` against a local Puppet Forge and saving the results into a temporary `modulepath`.




## TODO
- [ ] run standalone from `bin`
- [ ] finish README
- [ ] if `TEST_FORGE_tar_dir` is set, don't user `@mut_dir`

## Setup

### Beginning with simp-module-repoclosure

Add this to your project's `Gemfile`:

```ruby
gem 'simp-module-repoclosure'
```

## Methods



## Environment variables
You can set the environment variables `TEST_FORGE_tar_dir` and
`TEST_FORGE_mods_dir` to use pre-existing diretories of modules
for the local forge.

### TEST_FORGE_mods_dir

### TEST_FORGE_tar_dir

### TEST_FORGE_port





## Examples
```bash
TEST_FORGE_port=8888
```


## License
See [LICENSE](LICENSE)
