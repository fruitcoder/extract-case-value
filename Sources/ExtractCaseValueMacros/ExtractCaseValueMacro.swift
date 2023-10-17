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
      context.diagnose(.requiresEnum, at: declaration)
      return []
    }

    guard
      let arguments = attribute.arguments,
      case let .argumentList(arguments) = arguments
    else {
      context.diagnose(.requiresArgs, at: attribute)
      return []
    }

    // get `name` argument
    guard let propertyNameArg = arguments.first(labeled: caseParamExtractionPropertyNameArgumentLabel) else {
      context.diagnose(.requiresPropertyNameArg, at: attribute)
      return []
    }

    guard let propertyNameString = propertyNameArg.expression.stringLiteralSegment else {
      context.diagnose(.requiresPropertyNameStringLiteral, at: propertyNameArg.expression)
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
        .attributeName.as(IdentifierTypeSyntax.self)?
        .genericArgumentClause?
        .arguments.first?
        .argument
    else {
      context.diagnose(.requiresGenericType, at: attribute)
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
      let tupleList = attribute.arguments?.as(LabeledExprListSyntax.self)
    else { return [] }
    let expr: ExprSyntax = ", \(propertyNameString): <#Type#>"
    var newTupleList = tupleList
    newTupleList.append(LabeledExprSyntax(expression: expr))

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

      guard let paramList = caseSyntax.parameterClause?.parameters else {
        if let defaultValue {
          switchCaseSyntaxes.append(
            "case .\(element.name): return \(defaultValue)"
          )
          continue
        } else {
          context.diagnose(.noAssociatedValues(case: element.name.text), at: element, fixIts: [insertDefaultFixIt])
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
              "case .\(element.name): return \(defaultValue)"
            )
            didUseDefaultValue = true
            break
          } else {
            context.diagnose(.noValue(case: element.name.text, index: index), at: element, fixIts: [insertDefaultFixIt])
            return []
          }
        }

        guard associatedValue.element.type.matchesReturnType(returnType) else {
          context.diagnose(.typeMismatch(case: element.name.text, index: index), at: associatedValue.element)
          return []
        }

        leadingUnderscoreCount = index

      case let .associatedValueName(name):
        guard let associatedValue = paramList.first(labeled: name), let index = paramList.firstIndex(of: name) else {
          if let defaultValue {
            switchCaseSyntaxes.append(
              "case .\(element.name): return \(defaultValue)"
            )
            didUseDefaultValue = true
            break
          } else {
            context.diagnose(
              .noAssociatedValueForName(name: name, case: element.name.text),
              at: element,
              fixIts: [insertDefaultFixIt]
            )
            return []
          }
        }

        guard associatedValue.type.matchesReturnType(returnType) else {
          context.diagnose(
            .typeMismatchNamed(name: name, case: element.name.text),
            at: associatedValue
          )
          return []
        }

        leadingUnderscoreCount = index

      case .firstMatchingType:
        guard let index = paramList.enumerated().first(where: { $0.element.type.matchesReturnType(returnType) })?.offset
        else {
          if let defaultValue {
            switchCaseSyntaxes.append(
              "case .\(element.name): return \(defaultValue)"
            )
            didUseDefaultValue = true
            break
          } else {
            context.diagnose(
              .noMatchingType(type: "\(returnType)", case: element.name.text),
              at: element,
              fixIts: [insertDefaultFixIt]
            )
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
          "case let .\(element.name)(\(raw: variablesAndUnderscores)): return \(uniqueVariableName)"
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
