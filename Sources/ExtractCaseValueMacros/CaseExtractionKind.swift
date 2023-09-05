import SwiftSyntax
import ExtractCaseValueTypes

extension CaseExtractionKind {
    init?(expr: ExprSyntax) {
        guard
            let functionCall = expr.as(FunctionCallExprSyntax.self),
            let memberAccessExpr = functionCall.calledExpression.as(MemberAccessExprSyntax.self)
        else { return nil }

        let firstIntArgument = (functionCall.argumentList.first?.expression.as(IntegerLiteralExprSyntax.self)?.digits.text).flatMap(Int.init)
        let firstStringArgument = functionCall.argumentList.first?.expression.stringLiteralSegment

        switch memberAccessExpr.name.text {
        case "position" :
            guard let position = firstIntArgument else { return nil }
            self = .position(position)
        case "associatedValueName":
            guard let name = firstStringArgument?.content.text else { return nil }
            self = .associatedValueName(name)
        case "firstMatchingType":
            self = .firstMatchingType
        default:
            return nil
        }
    }
}
