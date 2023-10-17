import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum ExtractCaseValueMacroDiagnostic {
  case requiresEnum
  case requiresArgs
  case requiresPropertyNameArg
  case requiresPropertyNameStringLiteral
  case requiresGenericType
  case noValue(case: String, index: Int)
  case noMatchingType(type: String, case: String)
  case noAssociatedValues(case: String)
  case noAssociatedValueForName(name: String, case: String)
  case typeMismatch(case: String, index: Int)
  case typeMismatchNamed(name: String, case: String)
}

extension ExtractCaseValueMacroDiagnostic: DiagnosticMessage {
  func diagnose(at node: some SyntaxProtocol, fixIts: [FixIt] = []) -> Diagnostic {
    Diagnostic(node: Syntax(node), message: self, fixIts: fixIts)
  }

  var message: String {
    switch self {
    case .requiresEnum:
      return "'ExtractCaseValue' macro can only be applied to an enum"

    case .requiresArgs:
      return "'ExtractCaseValue' macro requires arguments"

    case .requiresPropertyNameArg:
      return "'ExtractCaseValue' macro requires `\(caseParamExtractionPropertyNameArgumentLabel)` argument"

    case .requiresPropertyNameStringLiteral:
      return "'ExtractCaseValue' macro argument `\(caseParamExtractionPropertyNameArgumentLabel)` must be a string literal"

    case .requiresGenericType:
      return "'ExtractCaseValue' macro requires a generic type for the computed property"

    case let .noValue(caseName, index):
      return "'ExtractCaseValue' macro could not find an associated value for `\(caseName)` at index \(index). Consider using a default value."

    case let .noMatchingType(type, caseName):
      return "'ExtractCaseValue' macro found no associated value of type \(type) in `\(caseName)`. Consider using a default value."

    case let .noAssociatedValues(caseName):
      return "'ExtractCaseValue' macro could not find associated values for `\(caseName)`. Consider using a default value."

    case let .noAssociatedValueForName(name, caseName):
      return "'ExtractCaseValue' macro found no associated value named \(name) in `\(caseName)`. Consider using a default value."

    case let .typeMismatch(caseName, index):
      return "'ExtractCaseValue' macro found a mismatching type for `\(caseName)` at index \(index)"

    case let .typeMismatchNamed(paramName, caseName):
      return "'ExtractCaseValue' macro found a mismatching type for \(paramName) in the `\(caseName)` case"
    }
  }

  var severity: DiagnosticSeverity { .error }

  var diagnosticID: MessageID {
    MessageID(domain: "Swift", id: "ExtractCaseValue.\(self)")
  }
}

struct InsertDefaultValueItMessage: FixItMessage {
  var message: String {
    "Insert default value"
  }

  var fixItID: MessageID {
    MessageID(domain: "Swift", id: "ExtractCaseValue.\(self)")
  }
}

extension MacroExpansionContext {
  func diagnose(_ diagnostic: ExtractCaseValueMacroDiagnostic, at node: some SyntaxProtocol, fixIts: [FixIt] = []) {
    diagnose(diagnostic.diagnose(at: node, fixIts: fixIts))
  }
}
