//
//  AudioPlayer.swift
//  namaz
//
//  Created by Daniya on 11/01/2020.
//  Copyright © 2020 Nursultan Askarbekuly. All rights reserved.
//

import AVFoundation
import MediaPlayer

class RecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @Published var activeItemId: String = ""
    @Published var progress: Float = 0
    
    @Published var speed: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(speed, forKey: "playSpeed")
            UserDefaults.standard.synchronize()
            
            if let player = player, player.isPlaying {
                
                player.stop()
                
                /// if volume is ON, limit playspeed to 1.75
//                let isVolumeOn = AVAudioSession.sharedInstance().outputVolume > 0
                player.rate = speed // isVolumeOn ? min(speed, 1.75) : speed
                
                player.prepareToPlay()
                player.play()
            }
        }
    }
    let step: Float = 0.25
    let range: ClosedRange<Float> = 1.00...2.00
        
    @Published var isPlaying: Bool = false
    @Published var isRecording: Bool = false
    
    let uploader = UploaderService()
    
    public var tracks: [String] = []
    private var visibleRows: [String:Bool] = [:]
    
    public func setVisibility(for item: String, isVisible: Bool) {
        visibleRows[item] = isVisible
    }
    
    public func getVisibility(for item: String) -> Bool {
        visibleRows[item] ?? false
    }
    
    public var progressMode: ProgressMode = .durationBased
    public var currentlyActiveIndex: Int {
        if let index = tracks.firstIndex(of: activeItemId) {
            return index
        } else {
            return -1
        }
    }
    
    private var audioRecorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var updater : CADisplayLink! = nil
    private var runCount: Double = 0
    private let fileManager = FileManager.default

    
    enum ProgressMode {
        case rowBased
        case durationBased
    }
    
    public func handlePlayButton() {
        guard let player = player else {
            
            self.playFromBundle(itemId: activeItemId)
            return
        }
        
        if player.isPlaying {
            /// pause the player
            pausePlayer()
        } else {
            isPlaying = true
            player.play()
        }
    }
    
    public func handleNextButton() {
        
        if isRecording {
            recordNextItem()
        } else if isPlaying {
            playNextItem()
        } else if currentlyActiveIndex < tracks.count - 1 { /// moreItemsAhead
            self.activeItemId = tracks[currentlyActiveIndex+1]
        } else {
            self.activeItemId = tracks.first ?? ""
        }
    }
    
    public func handlePreviousButton() {
        
        if isRecording {
            recordPreviousItem()
        } else if isPlaying {
            playPreviousItem()
        } else if currentlyActiveIndex > 0 {
            self.activeItemId = tracks[currentlyActiveIndex-1]
        }
        
    }

    public func handleRecordButton() {
        if isRecording {
            finishRecording()
        } else {
            startRecording()
        }
    }
    
    public func handleUploadButton() {
        if isRecording {
            finishRecording()
        }
        
        if isPlaying {
            pausePlayer()
        }
        
        uploader.uploadNewlyRecordedAudios(tracks)
    }
    
    public func handleRowTap(at rowId: String) {
        self.activeItemId = rowId
        if isPlaying && uploader.didSaveRecording(activeItemId) {
            playFromBundle(itemId: activeItemId)
        } else if isRecording && uploader.didSaveRecording(activeItemId) {
            finishRecording()
            startRecording()
        } else {
            resetRecorder()
            stopPlayer()
        }
    }
    
    public func recordingExists(_ trackId: String) -> Bool {
        uploader.didSaveRecording(trackId)
    }
    
    public func recordingUploaded(_ trackId: String) -> Bool {
        uploader.didUploadRecording(trackId)
    }
    
    public func resetPlayer() {
        activeItemId = ""
        player?.stop()
        player = nil
    }
    
    public func resetRecorder() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
    }
    
    private func startRecording() {
        
        if activeItemId.isEmpty, let first = tracks.first  {
            activeItemId = first
        }
        
        stopPlayer()
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording-\(activeItemId).m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            print("recorded audio:", audioFilename)
            isRecording = true
        } catch {
            print(#file, #function, #line, #column, "recording failed:", error.localizedDescription)
        }
    }
    
    private func finishRecording() {
        uploader.registerRecording(activeItemId)
        resetRecorder()
    }
    
    override init() {
        super.init()
        setupPlayer()
        registerForInterruptions()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(goToBackground),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(returnToForeground),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
        
    }
    
    deinit {
        resetPlayer()
        progressMode = .durationBased
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        updater = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func playFromBundle(itemId: String) {
        
        if itemId.isEmpty, let first = tracks.first  {
            activeItemId = first
        } else {
            activeItemId = itemId
        }
        
        let path = getDocumentsDirectory().appendingPathComponent("recording-\(activeItemId).m4a").path
        
        if fileManager.fileExists(atPath: path) {
            print("FILE AVAILABLE")
            self.playAudio(at: path)
        } else {
            isPlaying = false
        }
        
        
    }
    
    private func playAudio(at path: String) {
        
        let url = URL(fileURLWithPath: path)
        player = nil
        removeDurationTracking()
        /// Uncomment for progress by tracks played
        if progressMode == .rowBased {
            progress = max(0, Float(currentlyActiveIndex)/Float(tracks.count-1))
            removeDurationTracking()
        } else if progressMode == .durationBased {
            setupDurationTracking()
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.delegate = self
            player.enableRate = true
            
            /// if output volume is ON, limit playspeed to 1.75 (specific to namazapp)
            let isVolumeOn = AVAudioSession.sharedInstance().outputVolume > 0
            player.rate = isVolumeOn ? min(speed, 1.75) : speed
            
            
            player.prepareToPlay()
            player.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch let error as NSError {
            print(#file, #function, #line, #column, error.description)
        }
        
    }
    
    private func pausePlayer() {
        isPlaying = false
        self.player?.pause()
    }
    
    private func stopPlayer() {
        isPlaying = false
        self.player?.stop()
        progress = 0
    }
    
    private func recordNextItem(){
        finishRecording()
        
        if currentlyActiveIndex < tracks.count - 1 {
            /// moreItemsAhead
            self.activeItemId = tracks[currentlyActiveIndex+1]
            startRecording()
        } else {
            activeItemId = tracks.first ?? ""
            progress = 0
        }
    }
    
    private func playNextItem(){
        
        if currentlyActiveIndex < tracks.count - 1 { /// moreItemsAhead
            self.playFromBundle(itemId: tracks[currentlyActiveIndex+1])
        } else {
            
            //            Analytics.shared.logEvent("Audio Completed", properties: [
            //                "onRepeat": false,
            //                "audio": audio.id
            //            ])
            activeItemId = tracks.first ?? ""
            isPlaying = false
            progress = 0
            player?.stop()
            player = nil
        }
    }
    
    private func recordPreviousItem() {
        
        finishRecording()
        
        if currentlyActiveIndex > 0 {
            activeItemId = tracks[currentlyActiveIndex-1]
            startRecording()
        }
    }
    
    private func playPreviousItem() {
        if currentlyActiveIndex > 0 {
            let previousItemId = tracks[currentlyActiveIndex-1]
            playFromBundle(itemId: previousItemId)
        } else {
            playFromBundle(itemId: "")
        }
    }
    
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        playNextItem()
    }
    
    private func setupDurationTracking() {
        updater = CADisplayLink(target: self, selector: #selector(self.trackAudio))
        updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    private func removeDurationTracking() {
        guard let _ = updater else { return }
        updater.invalidate()
        updater = nil
    }
    
    @objc private func trackAudio() {
        
        let current: Float = Float(player?.currentTime ?? 0.0)
        let duration: Float = Float(player?.duration ?? 1.0)
//        print(current, duration)
        
        if current < 0.15 {
            return
        }
        
        let newProgress = current / duration
        self.progress = newProgress
        
    }
    
    @objc private func goToBackground() {
        // do something?
    }
    
    @objc private func returnToForeground() {
        // do something?
    }
    
}

extension RecorderViewModel {
    
    private func setupPlayer() {
        if let actualSpeedValue = UserDefaults.standard.object(forKey: "playSpeed") as? Float {
            self.speed = actualSpeedValue
        }
        
    }
    
    private func registerForInterruptions() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(handleInterruption),
                                       name: AVAudioSession.interruptionNotification,
                                       object: nil)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        // put the player to pause in case of an interruption (e.g. incoming phone call)
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            pausePlayer()
        }
        
    }
}
