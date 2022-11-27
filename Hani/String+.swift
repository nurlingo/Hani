//
//  String+.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//

import Foundation
import SwiftUI

extension Font {
    /// get "Open Sans" font or fallbacks to the system font in case the custom font was not registered
    /// - Parameter size: size of font
    /// - Returns: "Open Sans" font (or sytem font as fallback)
    static func uthmanicHafsScript(size: CGFloat) -> Font {
        guard UIFont.familyNames.contains("KFGQPC Uthmanic Script HAFS") else {
            return Font.system(size: size)
        }
        return .custom("KFGQPCUthmanicScriptHAFS", size: size)
    }
    
    static func uthmanicTahaScript(size: CGFloat) -> Font {
        guard UIFont.familyNames.contains("KFGQPC Uthman Taha Naskh") else {
            return Font.system(size: size)
        }
        return .custom("KFGQPCUthmanTahaNaskh", size: size)
    }
    
    
}


extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}


extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
