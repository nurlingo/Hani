//
//  hanyApp.swift
//  hany
//
//  Created by Daniya on 16/09/2022.
//

import SwiftUI
import AVFoundation

@main
struct HanyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainView(audioGroups: Storage.shared.audioSections)
//            PlayerView(audio: Storage.shared.audios["surah"]![0])
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.beginReceivingRemoteControlEvents()
        
        do {
            // play sound even on silent
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playAndRecord)
            }
            
        } catch let error as NSError {
            print(#function, error.description)
        }
        
        return true
        
    }
}
