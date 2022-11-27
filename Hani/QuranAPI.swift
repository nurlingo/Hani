//
//  QuranAPI.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 22.09.2022.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//


import Foundation

// MARK: - MushafMeta
struct MushafMeta: Codable {
    let code: Int
    let status: String
    let data: QuranMetaDataClass
}

// MARK: - DataClass
struct QuranMetaDataClass: Codable {
    let ayahs: Ayahs
    let surahs: Surahs
    let sajdas: Sajdas
    let rukus, pages, manzils, hizbQuarters: HizbQuarters
    let juzs: HizbQuarters
}

// MARK: - Ayahs
struct Ayahs: Codable {
    let count: Int
}

// MARK: - HizbQuarters
struct HizbQuarters: Codable {
    let count: Int
    let references: [HizbQuartersReference]
}

// MARK: - HizbQuartersReference
struct HizbQuartersReference: Codable {
    let surah, ayah: Int
}

// MARK: - Sajdas
struct Sajdas: Codable {
    let count: Int
    let references: [SajdasReference]
}

// MARK: - SajdasReference
struct SajdasReference: Codable {
    let surah, ayah: Int
    let recommended, obligatory: Bool
}

// MARK: - Surahs
struct Surahs: Codable {
    let count: Int
    let references: [SurahsReference]
}

// MARK: - SurahsReference
struct SurahsReference: Codable, Identifiable {
    let number: Int
    let name, englishName, englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: RevelationType
    
    var id: String {
        String(number)
    }
}

enum RevelationType: String, Codable {
    case meccan = "Meccan"
    case medinan = "Medinan"
}

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let quran = try? newJSONDecoder().decode(Mushaf.self, from: jsonData)

import Foundation

// MARK: - Quran
struct Mushaf: Codable {
    let code: Int
    let status: String
    let data: MushafDataClass
}

// MARK: - DataClass
struct MushafDataClass: Codable {
    let surahs: [Surah]
    let edition: Edition
}

// MARK: - Edition
struct Edition: Codable {
    let identifier, language, name, englishName: String
    let format, type: String
}

// MARK: - Surah
struct Surah: Codable, Identifiable, Listable, ContentMolecule {
    
    var title: String {
        englishName
    }
    
    var isShown: Int {
        1
    }
    
    var atoms: [ContentAtom] {
        ayahs
    }
    
    let number: Int
    let name, englishName, englishNameTranslation: String
    let revelationType: RevelationType
    var ayahs: [Ayah]
    
    var id: String {
        String(number)
    }
}

// MARK: - Ayah
struct Ayah: Codable, ContentAtom {
    var id: String {
        String(number)
    }
    
    var meaning: String {
        if let enMeaning = enMeaning {
            return "\(numberInSurah). \(enMeaning)"
        } else {
            return ""
        }
    }
    
    var enMeaning: String?
    var ruMeaning: String?
    
    var commentary: String {
        ""
    }
    
    var image: String {
        ""
    }
    
    let number: Int
    let text: String
    let numberInSurah, juz, manzil, page: Int
    let ruku, hizbQuarter: Int
    let sajda: SajdaUnion
}

enum SajdaUnion: Codable {
    case bool(Bool)
    case sajdaClass(SajdaClass)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(SajdaClass.self) {
            self = .sajdaClass(x)
            return
        }
        throw DecodingError.typeMismatch(SajdaUnion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for SajdaUnion"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let x):
            try container.encode(x)
        case .sajdaClass(let x):
            try container.encode(x)
        }
    }
}

// MARK: - SajdaClass
struct SajdaClass: Codable {
    let id: Int
    let recommended, obligatory: Bool
}
