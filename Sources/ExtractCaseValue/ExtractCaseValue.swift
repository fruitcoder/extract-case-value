import ExtractCaseValueMacros

/// A macro that extracts an associated value from enum cases using a default value if
/// extraction is not possible.
///
/// For example
///
/// ```swift
/// @ExtractCaseValue<String>(name: "path", kind: CaseExtractionKind.position(0), defaultValue: "")
/// enum Path {
///   case relative(String)
///   case absolute(String)
///   case root
/// }
/// ```
/// produces
///
/// ```swift
/// enum Path {
///   case relative(String)
///   case absolute(String)
///   case root
///   var path: String {
///     switch self {
///     case let .relative(__macro_local_4pathfMu_):
///       return __macro_local_4pathfMu_
///     case let .absolute(__macro_local_4pathfMu0_):
///       return __macro_local_4pathfMu0_
///     case .root:
///       return ""
///     }
///   }
/// }
/// ```
@attached(member, names: arbitrary)
public macro ExtractCaseValue<T>(name: String, kind: CaseExtractionKind = .default, defaultValue: T) = #externalMacro(module: "ExtractCaseValueMacros", type: "ExtractCaseValueMacro")

/// A macro that extracts an associated value from enum cases.
///
/// For example
///
/// ```swift
/// @ExtractCaseValue<String>(name: "path", kind: CaseExtractionKind.position(0))
/// enum Path {
///   case relative(String)
///   case absolute(String)
/// }
/// ```
/// produces
///
/// ```swift
/// enum Path {
///   case relative(String)
///   case absolute(String)
///   case root
///   var path: String {
///     switch self {
///     case let .relative(__macro_local_4pathfMu_):
///       return __macro_local_4pathfMu_
///     case let .absolute(__macro_local_4pathfMu0_):
///       return __macro_local_4pathfMu0_
///     }
///   }
/// }
/// ```
@attached(member, names: arbitrary)
public macro ExtractCaseValue<T>(name: String, kind: CaseExtractionKind = .default) = #externalMacro(module: "ExtractCaseValueMacros", type: "ExtractCaseValueMacro")
