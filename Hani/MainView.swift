//
//  ContentView.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import SwiftUI

struct MainView: View {
    
    var audioGroups = Storage.shared.audioSections
    @State var mushafMeta: MushafMeta?
    @State private var didLoad = false
    
    var body: some View {
        
        NavigationView {
            List {
                
                ForEach(audioGroups) { group in
                    Section(header: Text(group.title)) {
                        ForEach(group.items, id: \.id) { audio in
                            
                            if let audio = audio as? AudioTrack {
                                NavigationLink(
                                    destination: RecorderView(audio: audio)
                                ) {
                                    AudioRow(title: group.id == "surah" ? "\(audio.id). \(audio.title)" : audio.title)
                                }
                            } else {
                                Text("No such audio track")
                            }
                        }
                    }.headerProminence(.increased)
                }
                
                if let mushafMeta = mushafMeta {
                    
                    Section(header: Text("Short surahs without transliteration")) {
                        ForEach(mushafMeta.data.surahs.references
                            .filter({$0.number >= 93 && $0.number < 103 || [105,106,107].contains($0.number)}))
                        { surahReference in
                            
                            if let surah = Storage.shared.surahs[surahReference.id] {
                                NavigationLink(
                                    destination: RecorderView(audio: surah)
                                ) {
                                    AudioRow(title: "\(surahReference.number). \(surahReference.englishName)")
                                }
                            }
                        }
                    }.headerProminence(.increased)
                    
                    
                }
            }
            .onAppear {
                if didLoad == false {
                    didLoad = true
                    
                    Task {
                        try? await Storage.shared.loadMasahif()
                        self.mushafMeta = try? await Storage.shared.fetchMeta()
                    }
                }
            }
        }
    }
    
}

struct AudioRow: View {
    
    let title: String
    
    var body: some View {
        Text(title)
    }
}
