//
//  CaseExtractionKind.swift
//  
//
//  Created by Tomas Harkema on 02/09/2023.
//

import Foundation

/// The available kinds of case value extractions.
public enum CaseExtractionKind {
    /// Extract a value at a position in the associated values.
    case position(Int)

    /// Extract a value with a certain name.
    case associatedValueName(String)

    /// Extract the first value with a matching type.
    case firstMatchingType

    public static let `default` = Self.firstMatchingType
}

