//
//  PlayerView.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import SwiftUI
import AVFoundation

struct PlayerView: View {
    
    @Environment(\.colorScheme) var colorScheme
    let audio: ContentMolecule
    
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var fontVM = FontViewModel()
    
    @State private var didLoad = false
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(audio.atoms, id: \.id ) { atom in
                    HStack{
                        Spacer().frame(width:16)
                        VStack{
                            
                            Spacer().frame(height:2)
                            
                            HStack {
                                
                                Text(audio.id != "1" ? atom.text.deletingPrefix("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ").deletingPrefix("بِّسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ") : atom.text)
                                    .frame(maxWidth: .infinity, alignment: Alignment.topLeading)
                                    .font(.uthmanicTahaScript(size: CGFloat(fontVM.fontSize)))
                                    .minimumScaleFactor(0.01)
                                    .multilineTextAlignment(.leading)
                                    .allowsTightening(true)
                                    .lineSpacing(CGFloat(fontVM.fontSize/6))
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .onDisappear {
                                        //                            print("disappearing:", atom.id)
                                        playerVM.setVisibility(for: atom.id, isVisible: false)
                                    }
                            }
                            
                            Spacer().frame(height:4)
                            
                            if !atom.commentary.isEmpty {
                                Text(atom.commentary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(Font.system(size: CGFloat(fontVM.fontSize*0.75)))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .listRowBackground(Color.clear)
                                    .onAppear {
                                        //                                print("appearing:", atom.id)
                                        playerVM.setVisibility(for: atom.id, isVisible: true)
                                    }
                            }
                            
                            Spacer().frame(height:8)
                            
                            Text(atom.meaning)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(Font.system(size: CGFloat(fontVM.fontSize/2)))
                                .fixedSize(horizontal: false, vertical: true)
                                .listRowBackground(Color.clear)
                                .onAppear {
                                    //                            print("appearing:", atom.id)
                                    playerVM.setVisibility(for: atom.id, isVisible: true)
                                }
                            
                            Spacer().frame(height:8)
                        }
                        Spacer().frame(width:12)
                        if playerVM.activeItemId == atom.id {
                            Color.blue.frame(width:3)
                        } else {
                            Color.clear.frame(width:3)
                        }
                        Spacer().frame(width:1)
                    }
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {
                        playerVM.handleRowTap(at: atom.id)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: playerVM.activeItemId, perform: { newId in
                
                if playerVM.getVisibility(for: newId) {return}
                withAnimation {
                    proxy.scrollTo(newId, anchor: .topLeading)
                }
            })
            
        }.onAppear {
            if didLoad == false {
                didLoad = true
                playerVM.tracks = audio.atoms.map { $0.id }
            }
            
        }.onDisappear {
            playerVM.resetPlayer()
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                
                
                Menu {
                    Stepper(value: $fontVM.fontSize,
                            in: fontVM.fontRange,
                            step: fontVM.fontStep) {
                        Text("Font: \(Int(fontVM.fontSize))")
                    }
                    Stepper(value: $playerVM.speed,
                            in: playerVM.range,
                            step: playerVM.step) {
                        Text("Speed: \(String(format: "%.2f", playerVM.speed))x")
                    }
                } label: {
                    Image(systemName:"ellipsis.circle")
                }
                
                
                
            }
        }
        
        
        
        ProgressView(value: playerVM.progress, total: 1)
            .tint(Color.primary)
        HStack {
            PlayerControlPanel(playerVM: playerVM)
                .frame(height: 50)
        }
        
        
    }
    
    private func isRowOutsideScreen(_ geometry: GeometryProxy) -> Bool {
        // Alternatively, you can also check for geometry.frame(in:.global).origin.y if you know the button height.
        if geometry.frame(in: .global).maxY <= 0 {
            return true
        }
        return false
    }
    
}

struct PlayerControlPanel: View {
    
    @StateObject var playerVM: PlayerViewModel
    
    var body: some View {
        HStack {
            Spacer().frame(width:16)
            GeometryReader { geo in
                HStack{
                    
                    Spacer()
                    
                    Button {
                        playerVM.handlePreviousButton()
                        print("backward tapped!")
                    } label: {
                        ControlButton(imageName: "backward.fill", height: geo.size.height * 0.4)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button {
                        playerVM.handlePlayButton()
                    } label: {
                        ControlButton(imageName: playerVM.isPlayOn ? "pause.circle" : "play.circle", height: geo.size.height * 0.8)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        playerVM.handleNextButton()
                        print("forward tapped!")
                    } label: {
                        ControlButton(imageName: "forward.fill", height: geo.size.height * 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button {
                        playerVM.handleClockButton()
                    } label: {
                        ControlButton(imageName: "stopwatch", height: geo.size.height * 0.5)
                            .foregroundColor(playerVM.isClockOn ? Color.primary : Color(UIColor.tertiaryLabel))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        playerVM.handleRepeatButton()
                    } label: {
                        
                        switch playerVM.repeatMode {
                        case .repeatOff:
                            ControlButton(imageName: "repeat", height: geo.size.height * 0.7)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        case .repeatAll:
                            ControlButton(imageName: "repeat", height: geo.size.height * 0.7)
                                .foregroundColor(.primary)
                        case .repeatOne:
                            ControlButton(imageName: "repeat.1", height: geo.size.height * 0.7)
                                .foregroundColor(.primary)
                        }
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer().frame(width:16)
            
        }
    }
}

