import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ExtractCaseValuePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ExtractCaseValueMacro.self
  ]
}
