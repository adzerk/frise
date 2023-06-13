### 0.6.1 (June 13, 2023)

- New features
  - New schema type `$constant` for specifying values with a single possible instance
    ([#32](https://github.com/adzerk/frise/pull/32)).

### 0.6.0 (April 7, 2022)

- Breaking changes
  - Liquid parsing is now strict ([#29](https://github.com/velocidi/frise/pull/29)).
  - Update liquid gem to `5.3.0` ([#29](https://github.com/velocidi/frise/pull/29)).

- New features
  - Add `json` liquid filter ([#28](https://github.com/velocidi/frise/pull/28)).

### 0.5.1 (March 28, 2022)

- Breaking changes
  - Increase minimum required ruby version to 2.6.0 ([#22](https://github.com/velocidi/frise/pull/22)).
- Bug fixes
  - Fix YAML.safe_load call arguments error in ruby 3.1 ([#26](https://github.com/velocidi/frise/pull/26)).

### 0.4.1 (July 7, 2020)

- New features
  - `$delete` directive is now available in config files, allowing users to delete parts of the
    config sub-tree ([#20](https://github.com/velocidi/frise/pull/20)).

### 0.4.0 (November 29, 2019)

- Breaking changes
  - Recursive inclusions now respect the hierarchy of configuration files, avoiding inclusions lower
    in the hiearchy to be resolved before ones higher in the hierarchy
    ([#14](https://github.com/velocidi/frise/pull/14)).
- Bug fixes
  - Fix error messages from validations happening deeper in the config hierarchy, that were wrongly
    missing the first character in their path ([#16](https://github.com/velocidi/frise/pull/16)).

### 0.3.0 (April 16, 2018)

- Breaking changes
  - Defaults and schemas are now defined using a directive in the YAML configs instead of
    implicitly by looking at load paths. See ([#7](https://github.com/velocidi/frise/pull/7)) for
    more information on migration;
- New features
  - `$include` and `$schema` directives are now available in config files, allowing users to
    validate and include defaults at any part of the config
    ([#7](https://github.com/velocidi/frise/pull/7));
  - A new `$content_include` directive allows users to include the content of a file as a YAML
    string ([#8](https://github.com/velocidi/frise/pull/8));
  - The `_file_dir` Liquid variable is now available in all included files, containing always the
    absolute path to the file being loaded ([#7](https://github.com/velocidi/frise/pull/7)).

### 0.2.0 (August 17, 2017)

- New features
  - New schema types `$enum` and `$one_of` for specifying enumerations and values with multiple
    possible schemas ([#5](https://github.com/velocidi/frise/pull/5)).
- Bug fixes
  - Deal correctly with non-existing schema files in the load path
    ([#4](https://github.com/velocidi/frise/pull/4)).

### 0.1.0 (August 10, 2017)

Initial version.
