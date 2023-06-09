import ExtractCaseValue

@ExtractCaseValue<Double>(name: "x", kind: .associatedValueName("x"))
@ExtractCaseValue<Double>(name: "y", kind: .associatedValueName("y"))
@ExtractCaseValue<Double?>(name: "z", kind: .associatedValueName("z"), defaultValue: nil)
enum Coordinate {
  case twoDee(x: Double, y: Double)
  case threeDee(x: Double, y: Double, z: Double)
}

@ExtractCaseValue<String?>(name: "string", kind: .firstMatchingType)
enum JSON {
  case string(String)
  case number(Double)
  case object([String: JSON])
  case array([JSON])
  case bool(Bool)
  case null
}

@ExtractCaseValue<String>(name: "path")
enum Path {
  case absolute(String)
  case relative(String)
}
