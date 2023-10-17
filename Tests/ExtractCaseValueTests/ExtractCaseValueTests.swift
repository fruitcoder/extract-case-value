import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import ExtractCaseValueMacros

let testMacros: [String: Macro.Type] = [
	"ExtractCaseValue": ExtractCaseValueMacro.self
]

final class ExtractCaseValueTests: XCTestCase {
  func testMacro() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "path", kind: .position(0), defaultValue: "")
      enum Path {
        case relative(String)
        case absolute(String)
        case root
      }
      """,
      expandedSource: """

        enum Path {
          case relative(String)
          case absolute(String)
          case root

          var path: String {
            switch self {
            case let .relative(__macro_local_4pathfMu_):
              return __macro_local_4pathfMu_
            case let .absolute(__macro_local_4pathfMu0_):
              return __macro_local_4pathfMu0_
            case .root:
              return ""
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testAccessModifierIsInferred() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "path", kind: .position(0), defaultValue: "")
      public enum Path {
        case relative(String)
        case absolute(String)
        case root
      }
      """,
      expandedSource: """

        public enum Path {
          case relative(String)
          case absolute(String)
          case root

          public var path: String {
            switch self {
            case let .relative(__macro_local_4pathfMu_):
              return __macro_local_4pathfMu_
            case let .absolute(__macro_local_4pathfMu0_):
              return __macro_local_4pathfMu0_
            case .root:
              return ""
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testPositionExtraction() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<Double>(name: "x", kind: .position(0))
      enum Coordinate {
        case twoDee(x: Double, y: Double)
        case threeDee(x: Double, y: Double, z: Double)
      }
      """,
      expandedSource: """

        enum Coordinate {
          case twoDee(x: Double, y: Double)
          case threeDee(x: Double, y: Double, z: Double)

          var x: Double {
            switch self {
            case let .twoDee(__macro_local_1xfMu_, _):
              return __macro_local_1xfMu_
            case let .threeDee(__macro_local_1xfMu0_, _, _):
              return __macro_local_1xfMu0_
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testPositionExtractionUsesDefaultValue() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "path", kind: .position(0), defaultValue: "")
      enum Path {
        case relative(String)
        case absolute(String)
        case root
      }
      """,
      expandedSource: """

        enum Path {
          case relative(String)
          case absolute(String)
          case root

          var path: String {
            switch self {
            case let .relative(__macro_local_4pathfMu_):
              return __macro_local_4pathfMu_
            case let .absolute(__macro_local_4pathfMu0_):
              return __macro_local_4pathfMu0_
            case .root:
              return ""
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testAssociatedValueName() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<Double>(name: "y", kind: .associatedValueName("y"))
      enum Coordinate {
        case twoDee(x: Double, y: Double)
        case threeDee(x: Double, y: Double, z: Double)
      }
      """,
      expandedSource: """

        enum Coordinate {
          case twoDee(x: Double, y: Double)
          case threeDee(x: Double, y: Double, z: Double)

          var y: Double {
            switch self {
            case let .twoDee(_, __macro_local_1yfMu_):
              return __macro_local_1yfMu_
            case let .threeDee(_, __macro_local_1yfMu0_, _):
              return __macro_local_1yfMu0_
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testAssociatedValueNameUsesDefaultValue() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<Double?>(name: "z", kind: .associatedValueName("z"), defaultValue: nil)
      enum Coordinate {
        case twoDee(x: Double, y: Double)
        case threeDee(x: Double, y: Double, z: Double)
      }
      """,
      expandedSource: """

        enum Coordinate {
          case twoDee(x: Double, y: Double)
          case threeDee(x: Double, y: Double, z: Double)

          var z: Double? {
            switch self {
            case .twoDee:
              return nil
            case let .threeDee(_, _, __macro_local_1zfMu_):
              return __macro_local_1zfMu_
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testMultipleAssociatedValueNames() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<Double>(name: "x", kind: .associatedValueName("x"))
      @ExtractCaseValue<Double>(name: "y", kind: .associatedValueName("y"))
      @ExtractCaseValue<Double?>(name: "z", kind: .associatedValueName("z"), defaultValue: nil)
      enum Coordinate {
        case twoDee(x: Double, y: Double)
        case threeDee(x: Double, y: Double, z: Double)
      }
      """,
      expandedSource: """

        enum Coordinate {
          case twoDee(x: Double, y: Double)
          case threeDee(x: Double, y: Double, z: Double)

          var x: Double {
            switch self {
            case let .twoDee(__macro_local_1xfMu_, _):
              return __macro_local_1xfMu_
            case let .threeDee(__macro_local_1xfMu0_, _, _):
              return __macro_local_1xfMu0_
            }
          }

          var y: Double {
            switch self {
            case let .twoDee(_, __macro_local_1yfMu_):
              return __macro_local_1yfMu_
            case let .threeDee(_, __macro_local_1yfMu0_, _):
              return __macro_local_1yfMu0_
            }
          }

          var z: Double? {
            switch self {
            case .twoDee:
              return nil
            case let .threeDee(_, _, __macro_local_1zfMu_):
              return __macro_local_1zfMu_
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testFirstMatchingType() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String?>(name: "string", kind: .firstMatchingType, defaultValue: nil)
      enum _JSON {
        case string(String)
        case number(Double)
        case object([String: _JSON])
        case array([_JSON])
        case bool(Bool)
        case null
      }
      """,
      expandedSource: """

        enum _JSON {
          case string(String)
          case number(Double)
          case object([String: _JSON])
          case array([_JSON])
          case bool(Bool)
          case null

          var string: String? {
            switch self {
            case let .string(__macro_local_6stringfMu_):
              return __macro_local_6stringfMu_
            case .number:
              return nil
            case .object:
              return nil
            case .array:
              return nil
            case .bool:
              return nil
            case .null:
              return nil
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsRequiresEnum() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "test", kind: .default)
      struct NotAnEnum {}
      """,
      expandedSource: """

        struct NotAnEnum {}
        """,
      diagnostics: [
        .init(message: "'ExtractCaseValue' macro can only be applied to an enum", line: 1, column: 1)
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsRequiresArgsNoList() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>
      enum AnEnum {}
      """,
      expandedSource: """

        enum AnEnum {}
        """,
      diagnostics: [
        .init(message: "'ExtractCaseValue' macro requires arguments", line: 1, column: 1)
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsRequiresNameArg() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>()
      enum AnEnum {}
      """,
      expandedSource: """

        enum AnEnum {}
        """,
      diagnostics: [
        .init(message: "'ExtractCaseValue' macro requires `name` argument", line: 1, column: 1)
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsRequiresNameStringLiteral() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "prefix\\(stringVariable)")
      enum AnEnum {}
      """,
      expandedSource: """

        enum AnEnum {}
        """,
      diagnostics: [
        .init(message: "'ExtractCaseValue' macro argument `name` must be a string literal", line: 1, column: 33)
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticRequiresGenericType() {
    assertMacroExpansion(
      """
      @ExtractCaseValue(name: "name")
      enum AnEnum {}
      """,
      expandedSource: """

        enum AnEnum {}
        """,
      diagnostics: [
        .init(message: "'ExtractCaseValue' macro requires a generic type for the computed property", line: 1, column: 1)
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsNoAssociatedValues() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "name", kind: .position(1))
      enum AnEnum {
        case one, two
      }
      """,
      expandedSource: """

        enum AnEnum {
          case one, two
        }
        """,
      diagnostics: [
        .init(
          message: "'ExtractCaseValue' macro could not find associated values for `one`. Consider using a default value.",
          line: 3,
          column: 8,
          fixIts: [
            .init(message: "Insert default value")
          ]
        )
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsNoValueAtIndex() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "name", kind: .position(1))
      enum AnEnum {
        case one(String), two(Int)
      }
      """,
      expandedSource: """

        enum AnEnum {
          case one(String), two(Int)
        }
        """,
      diagnostics: [
        .init(
          message: "'ExtractCaseValue' macro could not find an associated value for `one` at index 1. Consider using a default value.",
          line: 3,
          column: 8,
          fixIts: [
            .init(message: "Insert default value")
          ]
        )
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsNoMatchingType() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "string", .firstMatchingType)
      enum AnEnum {
        case one(Int, Double, Float)
      }
      """,
      expandedSource: """

        enum AnEnum {
          case one(Int, Double, Float)
        }
        """,
      diagnostics: [
        .init(
          message: "'ExtractCaseValue' macro found no associated value of type String in `one`. Consider using a default value.",
          line: 3,
          column: 8,
          fixIts: [
            .init(message: "Insert default value")
          ]
        )
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsNoAssociatedValueForName() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<Double>(name: "a", kind: .associatedValueName("a"))
      enum Coordinate {
        case twoDee(x: Double, y: Double)
        case threeDee(x: Double, y: Double, z: Double)
      }
      """,
      expandedSource: """

        enum Coordinate {
          case twoDee(x: Double, y: Double)
          case threeDee(x: Double, y: Double, z: Double)
        }
        """,
      diagnostics: [
        .init(
          message: "'ExtractCaseValue' macro found no associated value named a in `twoDee`. Consider using a default value.",
          line: 3,
          column: 8,
          fixIts: [
            .init(message: "Insert default value")
          ]
        )
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsTypeMismatchAtIndex() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "name", kind: .position(0))
      enum AnEnum {
        case one(String), two(Int)
      }
      """,
      expandedSource: """

        enum AnEnum {
          case one(String), two(Int)
        }
        """,
      diagnostics: [
        .init(
          message: "'ExtractCaseValue' macro found a mismatching type for `two` at index 0",
          line: 3,
          column: 25,
          fixIts: []
        )
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testDiagnosticsTypeMismatchForName() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<String>(name: "name", kind: .associatedValueName("title"))
      enum AnEnum {
        case one(title: Text), two(title: String)
      }
      """,
      expandedSource: """

        enum AnEnum {
          case one(title: Text), two(title: String)
        }
        """,
      diagnostics: [
        .init(
          message: "'ExtractCaseValue' macro found a mismatching type for title in the `one` case",
          line: 3,
          column: 12,
          fixIts: []
        )
      ],
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }



  func testNilIsInferredAsDefaultValueIfTypeIsOptional() {
    assertMacroExpansion(
      """
      @ExtractCaseValue<Double?>(name: "a", kind: .associatedValueName("a"))
      enum Coordinate {
        case twoDee(x: Double, y: Double)
        case threeDee(x: Double, y: Double, z: Double)
      }
      """,
      expandedSource: """

        enum Coordinate {
          case twoDee(x: Double, y: Double)
          case threeDee(x: Double, y: Double, z: Double)

          var a: Double? {
            switch self {
            case .twoDee:
              return nil
            case .threeDee:
              return nil
            }
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }
}
