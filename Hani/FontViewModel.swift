//
//  ListViewModel.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//

import Foundation

class FontViewModel: NSObject, ObservableObject {
    
    @Published var fontSize: Float = 30.0 {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "fontSize")
            UserDefaults.standard.synchronize()
        }
    }
    let fontStep: Float = 5.0
    let fontRange: ClosedRange<Float> = 20.00...50.00
    
    override init() {
        super.init()
        setupFont()
    }
    
    private func setupFont() {
        
        if let fontSize = UserDefaults.standard.object(forKey: "fontSize") as? Float {
            self.fontSize = fontSize
        }
        
        //        for family in UIFont.familyNames.sorted() {
        //            let names = UIFont.fontNames(forFamilyName: family)
        //            print("Family: \(family) Font names: \(names)")
        //        }
        
    }
}    
    
    
