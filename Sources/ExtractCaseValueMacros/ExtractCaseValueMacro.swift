import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// Argument labels
let caseParamExtractionPropertyNameArgumentLabel = "name"
let caseParamExtractionKindArgumentLabel = "kind"
let caseParamExtractionTypeArgumentLabel = "type"
let caseParamExtractionDefaultValueArgumentLabel = "defaultValue"

// default values
let defaultExtractionKind = CaseExtractionKind.default

public struct ExtractCaseValueMacro {}

extension ExtractCaseValueMacro: MemberMacro {
  public static func expansion(
    of attribute: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax, // Declaration is the enum Type
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Only apply to enums
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      context.diagnose(ExtractCaseValueMacroDiagnostic.requiresEnum.diagnose(at: declaration))
      return []
    }

    guard
      let arguments = attribute.argument,
      case let .argumentList(arguments) = arguments
    else {
      context.diagnose(ExtractCaseValueMacroDiagnostic.requiresArgs.diagnose(at: attribute))
      return []
    }

    // get `name` argument
    guard let propertyNameArg = arguments.first(labeled: caseParamExtractionPropertyNameArgumentLabel) else {
      context.diagnose(ExtractCaseValueMacroDiagnostic.requiresPropertyNameArg.diagnose(at: attribute))
      return []
    }

    guard let propertyNameString = propertyNameArg.expression.stringLiteralSegment else {
      context.diagnose(ExtractCaseValueMacroDiagnostic.requiresPropertyNameStringLiteral.diagnose(at: propertyNameArg.expression))
      return []
    }

    // get kind argument or use default
    let caseExtractionKind: CaseExtractionKind
    if
      let caseExtractionKindArg = arguments.first(labeled: caseParamExtractionKindArgumentLabel),
      let parsedExtractionKind = CaseExtractionKind(expr: caseExtractionKindArg.expression)
    {
      caseExtractionKind = parsedExtractionKind
    } else {
      caseExtractionKind = defaultExtractionKind
    }

    // get expected type
    guard
      let returnType = attribute
        .attributeName.as(SimpleTypeIdentifierSyntax.self)?
        .genericArgumentClause?
        .arguments.first?
        .argumentType
    else {
      context.diagnose(ExtractCaseValueMacroDiagnostic.requiresGenericType.diagnose(at: attribute))
      return []
    }

    // get default value
    let returnTypeIsOptional = returnType.is(OptionalTypeSyntax.self)
    let defaultValue: ExprSyntax?

    if
      let defaultValueArg = arguments.first(labeled: caseParamExtractionDefaultValueArgumentLabel) {
      defaultValue = defaultValueArg.expression
    } else if returnTypeIsOptional {
      defaultValue = ExprSyntax("nil")
    } else {
      defaultValue = nil
    }

    // create fix-it to add a default value if necessary
    guard
      let tupleList = attribute.argument?.as(TupleExprElementListSyntax.self)
    else { return [] }
    let expr: ExprSyntax = ", \(propertyNameString): <#Type#>"
    let newTupleList = tupleList.inserting(TupleExprElementSyntax(expression: expr), at: tupleList.count)

    let insertDefaultFixIt = FixIt(
      message: InsertDefaultValueItMessage(),
      changes: [.replace(oldNode: Syntax(tupleList), newNode: Syntax(newTupleList))]
    )

    let members = declaration.memberBlock.members
    let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
    let elements = caseDecls.flatMap(\.elements)

    // infer access modifier from enum
    let access = enumDecl.modifiers.first(where: \.isNeededAccessLevelModifier)

    var switchCaseSyntaxes: [SwitchCaseSyntax] = []

    for element in elements {
      let caseSyntax = element.as(EnumCaseElementSyntax.self)!

      guard let paramList = caseSyntax.associatedValue?.parameterList else {
        if let defaultValue {
          switchCaseSyntaxes.append(
            "case .\(element.identifier): return \(defaultValue)"
          )
          continue
        } else {
          context.diagnose(ExtractCaseValueMacroDiagnostic.noAssociatedValues(case: element.identifier.text).diagnose(at: element, fixIts: [insertDefaultFixIt]))
          return []
        }
      }

      let associatedValuesCount = paramList.count
      var leadingUnderscoreCount = 0
      var didUseDefaultValue = false

      switch caseExtractionKind {
      case let .position(index):
        guard let associatedValue = paramList.enumerated().first(where: { $0.offset == index })
        else {
          if let defaultValue {
            switchCaseSyntaxes.append(
              "case .\(element.identifier): return \(defaultValue)"
            )
            didUseDefaultValue = true
            break
          } else {
            context.diagnose(ExtractCaseValueMacroDiagnostic.noValue(case: element.identifier.text, index: index).diagnose(at: element, fixIts: [insertDefaultFixIt]))
            return []
          }
        }

        guard associatedValue.element.type.matchesReturnType(returnType) else {
          context.diagnose(ExtractCaseValueMacroDiagnostic.typeMismatch(case: element.identifier.text, index: index).diagnose(at: associatedValue.element))
          return []
        }

        leadingUnderscoreCount = index

      case let .associatedValueName(name):
        guard let associatedValue = paramList.first(labeled: name), let index = paramList.firstIndex(of: name) else {
          if let defaultValue {
            switchCaseSyntaxes.append(
              "case .\(element.identifier): return \(defaultValue)"
            )
            didUseDefaultValue = true
            break
          } else {
            context.diagnose(ExtractCaseValueMacroDiagnostic.noAssociatedValueForName(name: name, case: element.identifier.text).diagnose(at: element, fixIts: [insertDefaultFixIt]))
            return []
          }
        }

        guard associatedValue.type.matchesReturnType(returnType) else {
          context.diagnose(ExtractCaseValueMacroDiagnostic.typeMismatchNamed(name: name, case: element.identifier.text).diagnose(at: associatedValue))
          return []
        }

        leadingUnderscoreCount = index

      case .firstMatchingType:
        guard let index = paramList.enumerated().first(where: { $0.element.type.matchesReturnType(returnType) })?.offset
        else {
          if let defaultValue {
            switchCaseSyntaxes.append(
              "case .\(element.identifier): return \(defaultValue)"
            )
            didUseDefaultValue = true
            break
          } else {
            context.diagnose(ExtractCaseValueMacroDiagnostic.noMatchingType(type: "\(returnType)", case: element.identifier.text).diagnose(at: element, fixIts: [insertDefaultFixIt]))
            return []
          }
        }

        leadingUnderscoreCount = index
      }

      if !didUseDefaultValue {
        let trailingUndescoreCount = associatedValuesCount - leadingUnderscoreCount - 1
        let uniqueVariableName = context.makeUniqueName(propertyNameString.content.text)
        let variablesAndUnderscores = (Array(repeating: "_", count: leadingUnderscoreCount)
                                       + ["\(uniqueVariableName)"]
                                       + Array(repeating: "_", count: trailingUndescoreCount))
          .joined(separator: ", ")

        switchCaseSyntaxes.append(
          "case let .\(element.identifier)(\(raw: variablesAndUnderscores)): return \(uniqueVariableName)"
        )
      }

      didUseDefaultValue = false
    }

    let computedProperty = try VariableDeclSyntax("\(access)var \(propertyNameString): \(returnType)") {
      try SwitchExprSyntax("switch self") {
        for switchCaseSyntax in switchCaseSyntaxes {
          "\(raw: switchCaseSyntax)"
        }
      }
    }

    return [DeclSyntax(computedProperty)]
  }
}
