import Foundation
import SwiftModCommands
import SwiftModCore

let tool = Tool(command: RunCommand())
tool.add(command: InitCommand())
tool.add(command: RulesCommand())

exit(tool.run())
