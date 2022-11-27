//
//  RecorderView.swift
//  hany
//
//  Created by Nursultan Askarbekuly on 26.11.2022.
//
import SwiftUI
import AVFoundation

struct RecorderView: View {
    
    @Environment(\.colorScheme) var colorScheme
    let audio: ContentMolecule
    
    @StateObject private var fontVM = FontViewModel()
    @StateObject private var recorderVM = RecorderViewModel()
    
    enum PlayerMode {
        case player
        case recorder
    }

    @State private var didLoad = false
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(audio.atoms, id: \.id ) { atom in
                    HStack{
                        Spacer().frame(width:1)
                        if recorderVM.activeItemId == atom.id {
                            Color.blue.frame(width:3)
                        } else {
                            Color.clear.frame(width:3)
                        }
                        Spacer().frame(width:12)
                        
                        VStack{
                            
                            Spacer().frame(height:2)
                            
                            HStack {

                                VStack {
                                    if recorderVM.recordingExists(atom.id) {
                                        Image(systemName: "recordingtape.circle")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.red, .primary)
                                            .frame(width:16,height:16)
                                    }
                                    Spacer()
                                        .frame(height:4)
                                    if recorderVM.recordingUploaded(atom.id) {
                                        Image(systemName: "checkmark.icloud")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.blue, .primary)
                                            .frame(width:16,height:16)
                                    } else {
                                        Spacer()
                                            .frame(width:16,height:16)
                                    }
                                }

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
                                        recorderVM.setVisibility(for: atom.id, isVisible: false)
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
                                        recorderVM.setVisibility(for: atom.id, isVisible: true)
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
                                    recorderVM.setVisibility(for: atom.id, isVisible: true)
                                }
                            
                            Spacer().frame(height:8)
                        }
                        Spacer().frame(width:16)
                    }
                    .listRowInsets(EdgeInsets())
                    .onTapGesture {
                        recorderVM.handleRowTap(at: atom.id)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: recorderVM.activeItemId, perform: { newId in
                
                if recorderVM.getVisibility(for: newId) {return}
                withAnimation {
                    proxy.scrollTo(newId, anchor: .topLeading)
                }
            })
            
        }.onAppear {
            if didLoad == false {
                didLoad = true
                recorderVM.tracks = audio.atoms.map { $0.id }
            }
            
        }
        .onDisappear {
            recorderVM.resetPlayer()
            recorderVM.resetRecorder()
        }
        
        ProgressView(value: (recorderVM.progress), total: 1)
            .tint(Color.primary)
        RecorderControlPanel(recorderVM: recorderVM)
            .frame(height: 50)
        
    }
    
    private func handleModeButton() {
        
        AVAudioSession.sharedInstance().requestRecordPermission() { allowed in
            DispatchQueue.main.async {
                if allowed {
                    /// all good
                } else {
                    print("recording is not allowed!")
                    /// FIXME: what else should be done?
                }
            }
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

struct RecorderControlPanel: View {
    
    @StateObject var recorderVM: RecorderViewModel
    
    @State var isPresentingConfirm: Bool = false
    
    var body: some View {
        HStack {
            Spacer().frame(width:16)
            GeometryReader { geo in
                HStack{
                    
                    Spacer().frame(width: 20)
                    Button {
                        recorderVM.handleRecordButton()
                    } label: {
                        if recorderVM.isRecording {
                            ControlButton(imageName: "stop.circle", height: geo.size.height * 0.8)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.primary, .red)
                        } else {
                            ControlButton(imageName: "record.circle", height: geo.size.height * 0.8)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.red, .primary)
                        }
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button {
                        recorderVM.handlePreviousButton()
                        print("backward tapped!")
                    } label: {
                        ControlButton(imageName: "backward.fill", height: geo.size.height * 0.4)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        recorderVM.handlePlayButton()
                    } label: {
                        ControlButton(imageName: recorderVM.isPlaying ? "pause.circle" : "play.circle", height: geo.size.height * 0.8)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        recorderVM.handleNextButton()
                        print("forward tapped!")
                    } label: {
                        ControlButton(imageName: "forward.fill", height: geo.size.height * 0.4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button {
                        print("upload")
                        isPresentingConfirm = true
                    } label: {
                        
                        VStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .resizable()
                                .scaledToFit()
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.blue, .primary)
                                .font(.system(size: 16, weight: .light))
                                .frame(width: 40, height: geo.size.height * 0.4)
                        }
                        .frame(width: geo.size.height * 0.8, height: geo.size.height * 0.8)
                        .overlay(
                            RoundedRectangle(cornerRadius: geo.size.height * 0.4)
                                .stroke(.primary, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .confirmationDialog("Upload recorded audios?",
                      isPresented: $isPresentingConfirm) {
                        Button("Upload") {
                            recorderVM.handleUploadButton()
                        }
                    } message: {
                      Text("Upload recorded audios: We'll use it to train a model that will assess your recitation automatically. InshaAllah you'll get a reward for participating.")
                    }
                    
                    
                    
                    Spacer().frame(width: 20)
                    
                }
            }
            
            Spacer().frame(width:16)
            
        }
    }
}


