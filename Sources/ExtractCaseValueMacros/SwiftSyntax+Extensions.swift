import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
  }
}

extension TypeSyntax {
  func matchesReturnType(_ type: TypeSyntax) -> Bool {
    guard let typeName = self.as(SimpleTypeIdentifierSyntax.self)?.name.text else { return false }

    return typeName == type.as(SimpleTypeIdentifierSyntax.self)?.name.text ||
    typeName == type.as(OptionalTypeSyntax.self)?.wrappedType.as(SimpleTypeIdentifierSyntax.self)!.name.text
  }
}

extension DeclModifierSyntax {
  var isNeededAccessLevelModifier: Bool {
    switch self.name.tokenKind {
    case .keyword(.public): return true
    default: return false
    }
  }
}

extension TupleExprElementListSyntax {
  /// Retrieve the first element with the given label.
  func first(labeled name: String) -> Element? {
    return first { element in
      if let label = element.label, label.text == name {
        return true
      }

      return false
    }
  }
}

extension EnumCaseParameterListSyntax {
  /// Retrieve the first element with the given label.
  func first(labeled name: String) -> Element? {
    first { $0.isLabeled(name) }
  }

  func firstIndex(of label: String) -> Int? {
    enumerated().first(where: { $0.element.isLabeled(label) })?.offset
  }
}

extension EnumCaseParameterListSyntax.Element {
  func isLabeled(_ label: String) -> Bool {
    self.firstName?.text == label ||
    (self.firstName?.tokenKind == .wildcard && self.secondName?.text == label)
  }
}

extension ExprSyntax {
  var stringLiteralSegment: StringSegmentSyntax? {
    guard
      let stringLiteral = self.as(StringLiteralExprSyntax.self),
      stringLiteral.segments.count == 1,
      case let .stringSegment(string)? = stringLiteral.segments.first
    else { return nil }

    return string
  }
}
