# ExtractCaseValue

The `ExtractCaseValue` package provides a macro to expose assiocated values from enum cases as a computed property. 

@Metadata {
  @PageColor(blue)
}

## Overview

@Row {
  @Column {
    To extract a simple value annotate an enum with the `ExtractCaseValue` macro and provide the expected type as a generic along with a name for the comuted property. This will use the ``CaseExtractionKind/firstMatchingType`` as a default to use the first associated value in a case that matches the expected type (in this case `String`).
  }
  @Column {
    ![Screenshot of Xcode showing the marco expansion on a Path enum with a String as return type](sample-one)
  }
}

@Row {
  @Column {
    If the return type is optional the macro will infer `nil` as the default value.
  }
  @Column {
    ![Screenshot of Xcode showing the marco expansion on a JSON enum with an optional String as return type](sample-two)
  }
}
  
@Row {
  @Column {
    ![Screenshot of Xcode showing the fix-it](fix-it)		
  }
  @Column {
    Otherwise, you will get a fix-it that recommends to use a default value.	
  }
}
    
@Row {
  @Column {
    You can also add mutliple `ExtractCaseValue` macros.
    ![Screenshot of Xcode showing the marco expansion on a Coordinate enum which uses multiple macros](sample-three)
  }
}
