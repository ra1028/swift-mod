# swift-mod

A tool for Swift code modification intermediating between code generation and formatting.

[![swift](https://img.shields.io/badge/language-Swift5-orange.svg)](https://developer.apple.com/swift)
[![release](https://img.shields.io/github/release/ra1028/swift-mod.svg)](https://github.com/ra1028/swift-mod/releases/latest)
[![test](https://github.com/ra1028/swift-mod/workflows/GitHub%20Actions/badge.svg)](https://github.com/ra1028/swift-mod/actions)
[![lincense](http://img.shields.io/badge/License-Apache%202.0-black.svg)](https://github.com/ra1028/swift-mod/blob/master/LICENSE)

---

## Overview

`swift-mod` is a tool for Swift code modification that intermediating between code generator and formatter built on top of [apple/SwiftSyntax](https://github.com/apple/swift-syntax).  
It can generates boilerplate code, such as access control or memberwise initializers in modularized source code, taking into account the state of the [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree).  
You can improve your productivity for writing more advanced Swift codes by introducing `swift-mod`.  

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
swift-mod rules --rule [RULE NAME] # Display more detailed rule description
```

4. Edit your configuration file with an editor you like, refering to the [documentation](#configuration).

5. Run

```sh
swift-mod <list of input files>
```

---

## Command Usage

```sh
swift-mod [COMMAND] [OPTIONS]
```

All commands can be display a usage by option `-h/--help`.

- `run` (or not specified)

```
OVERVIEW: Runs modification.

USAGE: swift-mod run [--mode <mode>] [--configuration <configuration>] [<paths> ...]

ARGUMENTS:
  <paths>                 Zero or more input filenames.

OPTIONS:
  -m, --mode <mode>                   Overrides running mode: modify|dry-run|check. (default: modify)
  -c, --configuration <configuration> The path to a configuration file.
  -h, --help                          Show help information.
```

- `init`

```
OVERVIEW: Generates a modify configuration file.

USAGE: swift-mod init [--output <output>]

OPTIONS:
  -o, --output <output>   An output for the configuration file to be generated.
  -h, --help              Show help information.
```

- `rules`

```
OVERVIEW: Display the list of rules.

USAGE: swift-mod rules [--rule <rule>]

OPTIONS:
  -r, --rule <rule>       A rule name to see detail.
  -h, --help              Show help information.
```

---

## Configuration

Modification rules and targets are defines with YAML-formatted file. By default, it's searched by name `.swift-mod.yml`.  
Any file name is allowed with passing with option like follows:  

```sh
swift-mod --configuration <configuration>
```

### Example

```yaml
format:
  indent: 4
  lineBreakBeforeEachArgument: true
rules:
  defaultAccessLevel:
    accessLevel: openOrPublic
    implicitInternal: true
  defaultMemberwiseInitializer:
    implicitInitializer: false
    implicitInternal: true
    ignoreClassesWithInheritance: false
```

### Format

Determines the format setting in all rules.  
Format according to this setting only when changes occur.  

|KEY|VALUE|REQUIREMENT|DEFAULT|
|:-|:-|:-|:-|
|indent|The number of spaces, or `tab` by text|Optional|4|
|lineBreakBeforeEachArgument|Indicating whether to insert new lines before each function argument|Optional|true|

### Rules

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

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

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

### [Mint](https://github.com/yonaskolb/Mint)

Install with Mint by following command:

```sh
mint install ra1028/swift-mod
```

Run command:

```sh
mint run ra1028/swift-mod [COMMAND] [OPTIONS]
```

### Using a pre-built binary

You can also install swift-mod by downloading `swift-mod.zip` from the latest GitHub release.

### Swift Version Support

`swift-mod` depends on [SwiftSyntax](https://github.com/apple/swift-syntax) version that matches the toolchain version in use.  
So you should use swift-mod version that built with compatible version of Swift you are using.

|Swift Version|Last Supported `swift-mod`      |
|:------------|:-------------------------------|
|5.1          |0.0.2                           |
|5.2          |0.0.4                           |
|5.3          |0.0.5                           |
|5.4          |0.0.6                           |
|5.5          |0.0.7                           |
|5.6          |0.1.0                           |
|5.7          |0.1.1                           |
|5.8          |0.2.0                           |
|5.9          |0.2.0                           |
|5.10         |0.2.1                           |
|6.1          |0.3.0                           |

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

---

## License

swift-mod is released under the [Apache 2.0 License](https://github.com/ra1028/swift-mod/blob/master/LICENSE).
