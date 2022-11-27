//
//  AudioPlayer.swift
//  namaz
//
//  Created by Daniya on 11/01/2020.
//  Copyright © 2020 Nursultan Askarbekuly. All rights reserved.
//

import Foundation

struct Credentials {
    let remoteAPI: String
    let username: String
    let password: String
}

class UploaderService {
    
    let creds: Credentials = credentials
    
    private let fileManager = FileManager.default
        
    private var recordingDates: [String:Date] = {
        if let dict: [String:Date] = UserDefaults.standard.object(forKey: "recordingDates") as? [String:Date] {
            return dict
        } else {
            return [:]
        }
    }() {
        didSet {
            UserDefaults.standard.set(recordingDates, forKey: "recordingDates")
        }
    }
    
    private var uploadedRecordingDates: [String:Date] = {
        if let dict: [String:Date] = UserDefaults.standard.object(forKey: "uploadedRecordingDates") as? [String:Date] {
            return dict
        } else {
            return [:]
        }
    }() {
        didSet {
            UserDefaults.standard.set(uploadedRecordingDates, forKey: "uploadedRecordingDates")
        }
    }
    
    
    internal func registerRecording(_ trackId: String) {
        recordingDates[trackId] = Date()
    }
    
    internal func didSaveRecording(_ trackId: String) -> Bool {
        let path = getDocumentsDirectory().appendingPathComponent("recording-\(trackId).m4a").path
        return fileManager.fileExists(atPath: path)
    }
    
    internal func didUploadRecording(_ trackId: String) -> Bool {
        
        guard didSaveRecording(trackId) else {return false}
        
        guard self.recordingDates[trackId] != nil else {return false}
        
        let didUpload = self.uploadedRecordingDates[trackId] == self.recordingDates[trackId]
        
        return didUpload
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func getToken() async {
        let url = URL(string: "\(creds.remoteAPI)token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let parameters: [String: Any] = [
            "username": creds.username,
            "password": creds.password
        ]
        
        request.httpBody = parameters.percentEncoded()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let dataDict = try JSONDecoder().decode([String:String].self, from: data)
            
            if let token = dataDict["access_token"] {
                self.token = token
                print(self.token)
            }
            
            print(response)
            print(data)
            
            // handle the result
        } catch {
            print(#file, #function, #line, #column,  "Token initiation failed")
        }

    }
    
    var token: String = ""
    var user_id: String = ""
    
    private func getClientID() async {
        
        let url = URL(string: "\(creds.remoteAPI)me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let dataDict = try JSONDecoder().decode([String:String].self, from: data)
            
            print(response)
            print(dataDict)
            // handle the result
            
            if let user_id = dataDict["user_id"] {
                self.user_id = user_id
                print(self.user_id)
            }
            
        } catch {
            print(#file, #function, #line, #column,  "Token initiation failed")
        }

    }
    
    
    internal func uploadNewlyRecordedAudios(_ tracks: [String]) {
        
        Task {
            do {
                await self.getToken()
                await self.getClientID()
                
                for track in tracks {
                    if didSaveRecording(track) && !didUploadRecording(track) {
                        await self.upload(track)
                    }
                }
                
            } catch {
                print(#file, #function, #line, #column, error.localizedDescription)
            }
        }
        
    }
    
    private func upload(_ track: String) async {
        
        print("uploading \(track)")
        let url = URL(string: "\(creds.remoteAPI)audios?client_id=nurios&surra_number=\(Int(track.prefix(3)) ?? 0)&aya_number=\(Int(track.suffix(3)) ?? 0)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let path = getDocumentsDirectory().appendingPathComponent("recording-\(track).m4a")
            let audioData = try Data(contentsOf: path)
            
            var data = Data()

            // Add the image data to the raw http request data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"recording-\(track).m4a\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
            print(responseData.first)
            self.uploadedRecordingDates[track] = self.recordingDates[track]
            
        } catch {
            print(#file, #function, #line, #column, error.localizedDescription)
        }
    }
    
}
