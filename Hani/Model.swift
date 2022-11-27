//
//  Model.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import Foundation

protocol Groupable {
    var id: String {get}
    var title: String {get}
    var items: [Listable] { get }
}

protocol Listable {
    var id: String {get}
    var title: String {get}
    var isShown: Int {get}
}

protocol ContentMolecule {
    var id: String {get}
    var title: String {get}
    var atoms: [ContentAtom] {get}
}

protocol ContentAtom {
    var id: String {get}
    var text: String {get}
    var meaning: String {get}
    var commentary: String {get}
    var image: String {get}
}


struct AudioGroup: Decodable, Groupable, Identifiable {
    
    let id, ru, en: String
    
    var title: String {
        isRussian ? ru : en
    }
    
    var isShown: Int {
        1
    }
    
    var items: [Listable] {
        
        guard let items = Storage.shared.audios[id] else {
            return []
        }
        
        return items.filter { item in
            
            item.isShown > 0
            
        }
    }
    
}

struct AudioTrack: Codable, Listable, ContentMolecule {
    
    let id, en, ru: String
    let isShown: Int
    
    var atoms: [ContentAtom] {
        Storage.shared.audioContents[id] ?? []
    }
    
    var title: String {
        return isRussian ? ru : en
    }
    
}

struct AudioAtom: Codable, ContentAtom {
    
    var text: String {
        uthmani
    }
    
    var meaning: String {
        isRussian ? ru : en
    }
    
    var commentary: String {
        return isRussian ? ruTranslit : enTranslit
    }
    
    var image: String {
        ""
    }
    
    let id: String
    let index: Int
    let clean, uthmani: String
    let en, ru: String
    let enTranslit, ruTranslit: String
}
