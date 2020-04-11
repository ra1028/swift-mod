# swift-mod

A tool for Swift code modification intermediating between code generation and formatting.

[![Swift5](https://img.shields.io/badge/language-Swift5-orange.svg)](https://developer.apple.com/swift)
[![Release](https://img.shields.io/github/release/ra1028/swift-mod.svg)](https://github.com/ra1028/swift-mod/releases/latest)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-blue.svg)](https://swift.org/package-manager)
[![CocoaPods](https://img.shields.io/cocoapods/v/swift-mod.svg)](https://cocoapods.org/pods/swift-mod)
[![CI Status](https://github.com/ra1028/swift-mod/workflows/GitHub%20Actions/badge.svg)](https://github.com/ra1028/swift-mod/actions)
[![Lincense](http://img.shields.io/badge/License-Apache%202.0-black.svg)](https://github.com/ra1028/swift-mod/blob/master/LICENSE)

---

## Overview

`swift-mod` is a tool for Swift code modification that intermediating between code generator and formatter built on top of [apple/SwiftSyntax](https://github.com/apple/swift-syntax).  
It can generates boilerplate code, such as access control or memberwise initializers in modularized source code, taking into account the state of the [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree).  
You can improve your productivity for writing more advanced Swift codes with introducing `swift-mod`.  

### Example

- **Before**

```swift
struct Avenger {
    var heroName: String
    internal var realName: String?
}

let avengers = [
    Avenger(heroName: "Iron Man", realName: "Tony Stark"),
    Avenger(heroName: "Captain America", realName: "Steve Rogers"),
    Avenger(heroName: "Thor"),
]

```

- **After**

```diff
+ public struct Avenger {
+     public var heroName: String
    internal var realName: String?

+     public init(
+         heroName: String,
+         realName: String? = nil
+     ) {
+         self.heroName = heroName
+         self.realName = realName
+     }
}

+ public let avengers = [
    Avenger(heroName: "Iron Man", realName: "Tony Stark"),
    Avenger(heroName: "Captain America", realName: "Steve Rogers"),
    Avenger(heroName: "Thor"),
]
```

---

## Getting Started

1. [Install `swift-mod`](#installation).

2. Generates configuration file.

```sh
swift-mod init
```

3. Check the all modification rules.

```sh
swift-mod rules
swift-mod rules --detail [RULE IDENTIFIER] # Display more detailed rule description
```

4. Edit your configuration file with an editor you like, refering to the [documentation](#configuration).

5. Run

```sh
swift-mod
```

---

## Command Usage

```sh
swift-mod [COMMAND] [OPTIONS]
```

All commands can be display a usage by option `-h/--help`.

- `run` (or not specified): Modifies Swift source code by rules.

  |OPTION|SHORT|USAGE|
  |:-|:-|:-|
  |--configuration|-c|The path to a configuration Yaml file|
  |--target|-t|The target name to be run partially|
  |--dry-run||Run without actually changing any files|
  |--check||Dry run that an error occurs if the any files should be changed|

- `init`: Generates a modify configuration file.

  |OPTION|SHORT|USAGE|
  |:-|:-|:-|
  |--output|-o|Path where the modify configuration should be generated|

- `rules`: Display the list of rules and overview.

  |OPTION|SHORT|USAGE|
  |:-|:-|:-|
  |--detail|-d|A rule identifier to displaying detailed description|

---

## Configuration

Modification rules and targets are defines with YAML-formatted file. By default, it's searched by name `.swift-mod.yml`.  
Any file name is allowed with passing with option like follows:  

```sh
swift-mod --configuration your-config-file.yml
```

### Example

```yaml
format:
  indent: 4
  lineBreakBeforeEachArgument: true
targets:
  main:
    paths:
      - "**/main.swift"
    excludedPaths:
      - Modules/
    rules:
      defaultAccessLevel:
        accessLevel: internal
        implicitInternal: true
  module:
    paths:
      - Modules/
    rules:
      defaultAccessLevel:
        accessLevel: openOrPublic
        implicitInternal: true
      defaultMemberwiseInitializer:
        enabled: true
```

### Format

Determines the format setting in all rules.  
Format according to this setting only when changes occur.  

|KEY|VALUE|REQUIREMENT|DEFAULT|
|:-|:-|:-|:-|
|indent|The number of spaces, or `tab` by text|Optional|4|
|lineBreakBeforeEachArgument|Indicating whether to insert new lines before each function argument|Optional|true|

### Targets

Defines the several targets by name key that defines different paths or rules to apply.  
Glob paths are allowed for `paths` and `excludedPaths`.  
Each target can runs partially by command with option like follows:  

```sh
swift-mod --target [TARGET NAME]
```

|KEY|VALUE|REQUIREMENT|DEFAULT|
|:-|:-|:-|:-|
|paths|The file names or paths to be applied rules. The directory is recursively lookup.|Required||
|excludedPaths|The file name or paths to be ecluded from resolved `paths`|Optional|None|
|rules|The set of rules to be applied|Required||

### Rules

Defines a modification rules enabled and its settings.  
All rules are opt-in.  
Rules where all settings are optional can specify only Boolean value indicating whether it's enabled by key `enabled`.  

#### Default Access Level

|IDENTIFIER|OVERVIEW|
|:-|:-|
|defaultAccessLevel|Assigns the suitable access level to all declaration syntaxes if not present|

|KEY|VALUE|REQUIREMENT|DEFAULT|
|:-|:-|:-|:-|
|accessLevel|\|openOrPublic\|public\|internal\|fileprivate\|private\||Required||
|implicitInternal|Indicating whether to omit the `internal` access level|Optional|true|

```swift
struct Avenger {
    var heroName: String
    internal var realName: String?
}
```

```diff
+ public struct Avenger {
+    public var heroName: String
    internal var realName: String?
}
```

#### Default Memberwise Initializer

|IDENTIFIER|OVERVIEW|
|:-|:-|
|defaultMemberwiseInitializer|Defines a memberwise initializer according to the access level in the type declaration if not present|

|KEY|VALUE|REQUIREMENT|DEFAULT|
|:-|:-|:-|:-|
|implicitInitializer|Indicating whether to omit the `internal` initializer in struct decalaration|Optional|false|
|implicitInternal|Indicating whether to omit the `internal` access level|Optional|true|
|ignoreClassesWithInheritance|Indicating whether to skip the classes having inheritance including protocol|Optional|false|

```swift
struct Avenger {
    var heroName: String
    internal var realName: String?
}
```

```diff
struct Avenger {
    var heroName: String
    internal var realName: String?

+    init(
+        heroName: String,
+        realName: String? = nil
+    ) {
+        self.heroName = heroName
+        self.realName = realName
+    }
}
```

---

### Ignoring Rules

`swift-mod` allows users to suppress modification for node and its children by comment like below.  

- **Ignore all rules**  

`// swift-mod-ignore`  

```swift
// swift-mod-ignore
struct Avenger {
    var heroName: String
    internal var realName: String?
}
```

- **Ignore specific rule(s)**  

`// swift-mod-ignore: [COMMA DELIMITED RULE IDENTIFIERS]`

```swift
// swift-mod-ignore: defaultAccessLevel, defaultMemberwiseInitializer
struct Avenger {
    var heroName: String
    internal var realName: String?
}
```

---

## Installation

`swift-mod` doesn't support [HomeBrew](http://brew.sh/) because it's hard to keep backward compatibility due to depended on the version of Swift toolchain you are using.  

### Using [Swift Package Manager](https://github.com/apple/swift-package-manager)

Add the following to the dependencies of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ra1028/swift-mod.git", from: "swift-mod version"),
]
```

Run command:

```sh
swift run -c release swift-mod [COMMAND] [OPTIONS]
```

### Using [Mint](https://github.com/yonaskolb/Mint)

Install with Mint by following command:

```sh
mint install ra1028/swift-mod
```

Run command:

```sh
mint run ra1028/swift-mod [COMMAND] [OPTIONS]
```

### Using [CocoaPods](https://github.com/CocoaPods/CocoaPods)

Add the following to your `Podfile`:

```sh
pod 'swift-mod'
```

Run command:

```sh
Pods/swift-mod/swift-mod [COMMAND] [OPTIONS]
```

\* If you have changed the name of `Xcode.app` used in toolchain (`xcode-select -p`), `swift-mod` via CocoaPods can't be excuted. Please set the Xcode name to `Xcode.app`. (See: https://forums.swift.org/t/swiftsyntax-with-swift-5-1/29051)  


### Swift Version Support

`swift-mod` depends on [SwiftSyntax](https://github.com/apple/swift-syntax) that the version in use must match the toolchain version.  
So you should use swift-mod version that built with compatible version of Swift you are using.  

|Swift Version|Last Supported swift-mod Release|
|:------------|:-------------------------------|
|5.1          |0.0.2                           |
|5.2          |latest                          |


### Issue on macOS Before 10.14.4

Swift tool binary that works with static-stdlib can't running on macOS before 10.14.4.  
You need to update macOS or install the [Swift 5 Runtime Support for Command Line Tools](https://support.apple.com/kb/DL1998).  

---

## Development

Pull requests, bug reports and feature requests are welcome 🚀.  
See [CONTRIBUTING.md](./CONTRIBUTING.md) file to learn how to contribute to swift-mod.  

Please validate and test your code before you submit your changes by following commands:  

```sh
 make autocorrect # Modifying, formatting, linting codes and generating Linux XCTest manifests.  
 make test
 ```

In addition, swift-mod supports running on Linux, so you should test by installing Docker and following command:  

```sh
make docker-test
```

### Known Issue

Currently, swift-mod doesn't works properly with builds in `debug` configuration.  
It may due to stack overflow with tail recursion in the method that enumerating the Swift file paths.  
swift-mod works with optimizing tail recursion by builds in `release` configuration.  

---

## License

swift-mod is released under the [Apache 2.0 License](https://github.com/ra1028/swift-mod/blob/master/LICENSE).
