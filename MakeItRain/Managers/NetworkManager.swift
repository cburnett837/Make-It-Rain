import Foundation
import WidgetKit
import SwiftUI
import os

class NetworkManager {
    
    //static var shared = NetworkManager()
    
    private static let logger = Logger(
        subsystem: "Jarvis",
        category: "Network Manager"
        /// To Read: Plug iPhone into Mac, open console app, and start streaming.
        /// Set search type to "subsystem" and search for the key in the subsystem above (Jarvis)
    )
    var request: URLRequest?
    var session: URLSession?
    
    init(timeout: TimeInterval = 60) {
        //let earl = String(format: "http://www.codyburnett.com:8677/")
        //let earl = String(format: "http://10.0.0.87:8677/")
        let earl = String(format: "https://\(Keys.baseURL):8681/")
        //let earl = String(format: "http://\(Keys.baseURL):8677/")
        let URL = URL(string: earl)
        var request = URLRequest(url: URL!)
        
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
        request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
        request.timeoutInterval = timeout
        request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")

        self.request = request
        self.session = URLSession.shared
    }
    
    deinit {
        request = nil
        session = nil
        LogManager.log()
    }
 
    func arrayRequest<T: Encodable, U: Decodable>(requestModel: RequestModel<T>, ticker: Int = 3, sessionID: String = "") async -> Result<Array<U>?, AppError> {
        var sesh: String = ""
        if sessionID.isEmpty {
            sesh = UUID().uuidString
        } else {
            sesh = sessionID
        }
        
        do {
            LogManager.log("starting", session: sesh)
            requestModel.sessionID = sessionID
            let jsonData = try? JSONEncoder().encode(requestModel)
            LogManager.log("jsonData: \(String(data: jsonData!, encoding: .utf8)!)", session: sesh)
            if AppState.shared.debugPrint { print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)") }
            
            request?.httpBody = jsonData
            
            if let session {
                let (data, response): (Data, URLResponse) = try await session.data(for: request!)
                let httpResponse = response as? HTTPURLResponse
                
                if httpResponse?.statusCode == 403 {
                    await AuthState.shared.serverAccessRevoked()
                    return .failure(.accessRevoked)
                }
                
                LogManager.log("should have a response from the server now", session: sesh)
                
                let serverText = String(data: data, encoding: .utf8) ?? ""
                if AppState.shared.debugPrint { print(serverText) }
                let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
                
                LogManager.log("decoding data", session: sesh)
                #warning("Error handling won't work with the force unwrap")
                #if targetEnvironment(simulator)
                let decodedData = try! JSONDecoder().decode(Array<U>?.self, from: data)
                #else
                let decodedData = try? JSONDecoder().decode(Array<U>?.self, from: data)
                #endif
                LogManager.log("data has been decoded", session: sesh)
                guard let decodedData else {
                    LogManager.log("something went wrong with the decoded data", session: sesh)
                    return .failure(.serverError(firstLine))
                }
                
                LogManager.log("networking successful", session: sesh)
                return .success(decodedData)
            } else {
                LogManager.error("session error", session: sesh)
                return .failure(.sessionError)
            }
                                    
        } catch {
            LogManager.error("networking exception \(error.localizedDescription)", session: sesh)
            if Task.isCancelled {
                LogManager.error("task cancelled", session: sesh)
                return .failure(.taskCancelled)
            }
            if ticker == 0 {
                LogManager.error("connection failure", session: sesh)
                return .failure(.connectionError)
            } else {
                try? await Task.sleep(for: .milliseconds(1000))
                LogManager.error("retrying request", session: sesh)
                return await arrayRequest(requestModel: requestModel, ticker: ticker - 1, sessionID: sesh)
            }
        }
    }
    
    
    func singleRequest<T: Encodable, U: Decodable>(requestModel: RequestModel<T>, ticker: Int = 3, sessionID: String = "") async -> Result<U?, AppError> {
        var sesh: String = ""
        if sessionID.isEmpty {
            sesh = UUID().uuidString
        } else {
            sesh = sessionID
        }
               
        do {
            LogManager.log("starting", session: sesh)
            requestModel.sessionID = sessionID
            let jsonData = try? JSONEncoder().encode(requestModel)
            LogManager.log("jsonData: \(String(data: jsonData!, encoding: .utf8)!)", session: sesh)
            if AppState.shared.debugPrint { print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)") }
            
            
            request?.httpBody = jsonData
            
            if let session {
                let (data, response): (Data, URLResponse) = try await session.data(for: request!)
                let httpResponse = response as? HTTPURLResponse
                
                print(httpResponse?.statusCode)
                
                if httpResponse?.statusCode == 403 {
                    await AuthState.shared.serverAccessRevoked()
                    return .failure(.accessRevoked)
                }
                
                LogManager.log("should have a response from the server now", session: sesh)
                
                let serverText = String(data: data, encoding: .utf8) ?? ""
                //print("GOT SERVER RESPONSE")
                if AppState.shared.debugPrint { print(serverText) }
                let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
                
                if firstLine == "None" && requestModel.requestType == "budget_app_login" {
                    return .failure(.incorrectCredentials)
                }
                
                LogManager.log("decoding data", session: sesh)
                #warning("Error handling won't work with the force unwrap")
                #if targetEnvironment(simulator)
                let decodedData = try! JSONDecoder().decode(U?.self, from: data)
                #else
                let decodedData = try? JSONDecoder().decode(U?.self, from: data)
                #endif
                LogManager.log("data has been decoded", session: sesh)
                guard let decodedData else {
                    LogManager.log("something went wrong with the decoded data", session: sesh)
                    return .failure(.serverError(firstLine))
                }
                
                LogManager.log("networking successful", session: sesh)
                return .success(decodedData)
            } else {
                LogManager.error("session error", session: sesh)
                return .failure(.sessionError)
            }
                        
        } catch {
            LogManager.error("networking exception \(error.localizedDescription)", session: sesh)
            if Task.isCancelled {
                LogManager.error("task cancelled", session: sesh)
                return .failure(.taskCancelled)
            }
            if ticker == 0 {
                LogManager.error("connection failure", session: sesh)
                return .failure(.connectionError)
            } else {
                try? await Task.sleep(for: .milliseconds(1000))
                LogManager.error("retrying request", session: sesh)
                return await singleRequest(requestModel: requestModel, ticker: ticker - 1, sessionID: sesh)
            }
        }
    }
    
    
    
    func longPollServer<T: Encodable, U: Decodable>(requestModel: RequestModel<T>, ticker: Int = 2, sessionID: String = "") async -> Result<U?, AppError> {
        var sesh: String = ""
        if sessionID.isEmpty {
            sesh = UUID().uuidString
        } else {
            sesh = sessionID
        }
        
        do {
            var request: URLRequest?
            var session: URLSession?
            
            //let earl = String(format: "http://www.codyburnett.com:8677/")
            //let earl = String(format: "http://10.0.0.87:8677/")
            let earl = String(format: "https://\(Keys.baseURL):8678/") ///3000 internal
            
            let URL = URL(string: earl)
            var subRequest = URLRequest(url: URL!)
            
            subRequest.httpMethod = "POST"
            subRequest.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            subRequest.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
            subRequest.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
            subRequest.setValue(String(AppState.shared.user!.accountID), forHTTPHeaderField: "Account-ID")
            subRequest.setValue(String(AppState.shared.user!.id), forHTTPHeaderField: "User-ID")
            subRequest.setValue(String(AppState.shared.deviceUUID!), forHTTPHeaderField: "Device-UUID")
            subRequest.timeoutInterval = 130
            subRequest.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")

            request = subRequest
            session = URLSession.shared
                        
            
            LogManager.log("starting", session: sesh)
            requestModel.sessionID = sessionID
            let jsonData = try? JSONEncoder().encode(requestModel)
            LogManager.log("jsonData: \(String(data: jsonData!, encoding: .utf8)!)", session: sesh)
            
            request?.httpBody = jsonData
            
            if let session {
                let (data, response): (Data, URLResponse) = try await session.data(for: request!)
                
                let httpResponse = response as? HTTPURLResponse
                
                LogManager.log("should have a response from the server now", session: sesh)
                
                let serverText = String(data: data, encoding: .utf8) ?? ""
                if AppState.shared.debugPrint { print(serverText) }
                let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
                
                LogManager.log("decoding data", session: sesh)
                
                
                if httpResponse?.statusCode == 504 {
                    return .success(nil)
                } else {
                    #if targetEnvironment(simulator)
                    let decodedData = try! JSONDecoder().decode(U?.self, from: data)
                    #else
                    let decodedData = try? JSONDecoder().decode(U?.self, from: data)
                    #endif
                    LogManager.log("data has been decoded", session: sesh)
                    guard let decodedData else {
                        LogManager.log("something went wrong with the decoded data", session: sesh)
                        return .failure(.serverError(firstLine))
                    }
                    
                    LogManager.log("networking successful", session: sesh)
                    return .success(decodedData)
                }
            } else {
                LogManager.error("session error", session: sesh)
                return .failure(.sessionError)
            }
                                    
        } catch {
            LogManager.error("networking exception \(error.localizedDescription)", session: sesh)
            if Task.isCancelled {
                LogManager.error("task cancelled", session: sesh)
                return .failure(.taskCancelled)
            }
            if ticker == 0 {
                LogManager.error("connection failure", session: sesh)
                return .failure(.connectionError)
            } else {
                try? await Task.sleep(for: .milliseconds(5000))
                LogManager.error("retrying request", session: sesh)
                return await longPollServer(requestModel: requestModel, ticker: ticker - 1, sessionID: sesh)
            }
        }
    }
    
    
    
    
    
    func uploadPicture<U: Decodable>(
        application: String,
        recordID: String,
        relatedTypeID: String,
        uuid: String,
        imageData: Data,
        isSmartTransaction: Bool = false,
        ticker: Int = 3
    ) async -> Result<U?, AppError> {
        do {
            let metadata: [String: String] = [
                "application": application,
                "type": "photo",
                "recordID": recordID,
                "relatedTypeID": relatedTypeID,
                "uuid": uuid,
                "userID": String(AppState.shared.user?.id ?? 0),
                "accountID": String(AppState.shared.user?.accountID ?? 0),
                "deviceID": String(AppState.shared.deviceUUID ?? ""),
                "isSmartTransaction": isSmartTransaction.description
            ]
            
            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else { return .failure(.failedToUploadPhoto) }
            
            var body = Data()
            let boundary = "Boundary-\(UUID().uuidString)"
            request?.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request?.setValue("yes", forHTTPHeaderField: "This-Is-A-Photo-For-Budget-App")
                                                            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"json\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(jsonString.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"hey\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
                        
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
              
            let (data, response) = try await URLSession.shared.upload(for: request!, from: body)
            let httpResponse = response as? HTTPURLResponse
        
            let serverText = String(data: data, encoding: .utf8) ?? ""
            if AppState.shared.debugPrint { print(serverText) }
            //print(serverText)
            
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
                                                            
            let decodedData = try? JSONDecoder().decode(U?.self, from: data)
            if decodedData == nil && httpResponse?.statusCode == 200 {
                return .success(nil)
            } else {
                guard let decodedData else { return .failure(.serverError(firstLine)) }
                return .success(decodedData)
            }
                                    
        } catch {
            if Task.isCancelled { return .failure(.taskCancelled) }
            if ticker == 0 {
                return .failure(.connectionError)
            } else {
                try? await Task.sleep(for: .milliseconds(1000))
                return await uploadPicture(
                    application: application,
                    recordID: recordID,
                    relatedTypeID: relatedTypeID,
                    uuid: uuid,
                    imageData: imageData,
                    ticker: ticker - 1
                )
            }
        }
    }
    
    
    
    func uploadPictureThatTheServerDoesntLike<U: Decodable>(application: String, recordID: String, uuid: String, imageString: String, isSmartTransaction: Bool = false, ticker: Int = 3) async -> Result<U?, AppError> {
        do {
            //let paramString = "application=\(application)&type=photo&recordID=\(recordID)&uuid=\(uuid)&image=\(imageString)&userID=\(String(AppState.shared.user?.id ?? 0))&accountID=\(String(AppState.shared.user?.accountID ?? 0))&deviceID=\(String(AppState.shared.deviceUUID ?? ""))&isSmartTransaction=\(isSmartTransaction.description)"
            
            
            let metadata: [String: String] = [
                "application": application,
                "type": "photo",
                "recordID": recordID,
                "uuid": uuid,
                "userID": String(AppState.shared.user?.id ?? 0),
                "accountID": String(AppState.shared.user?.accountID ?? 0),
                "deviceID": String(AppState.shared.deviceUUID ?? ""),
                "isSmartTransaction": isSmartTransaction.description
            ]
            
            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else { return .failure(.failedToUploadPhoto)}
            
            let bodyString = "image=\(imageString)&json=\(jsonString)"
            
            
            
            let paramData = bodyString.data(using: .utf8)
            request?.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request?.setValue("yes", forHTTPHeaderField: "This-Is-A-Photo-For-Budget-App")
            request?.httpBody = paramData
            
            let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request!)
            let httpResponse = response as? HTTPURLResponse
        
            let serverText = String(data: data, encoding: .utf8) ?? ""
            if AppState.shared.debugPrint { print(serverText) }
            
            print(serverText)
            
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
                                                            
            let decodedData = try? JSONDecoder().decode(U?.self, from: data)
            if decodedData == nil && httpResponse?.statusCode == 200 {
                return .success(nil)
            } else {
                guard let decodedData else { return .failure(.serverError(firstLine)) }
                return .success(decodedData)
            }
            
            
            
        } catch {
            if Task.isCancelled { return .failure(.taskCancelled) }
            if ticker == 0 {
                return .failure(.connectionError)
            } else {
                try? await Task.sleep(for: .milliseconds(1000))
                return await uploadPictureThatTheServerDoesntLike(application: application, recordID: recordID, uuid: uuid, imageString: imageString, ticker: ticker - 1)
            }
        }
    }
    
    
    
    func uploadPictureOG<U: Decodable>(application: String, recordID: String, uuid: String, imageString: String, isSmartTransaction: Bool = false, ticker: Int = 3) async -> Result<U?, AppError> {
        do {
            let paramString = "application=\(application)&type=photo&recordID=\(recordID)&uuid=\(uuid)&image=\(imageString)&userID=\(String(AppState.shared.user?.id ?? 0))&accountID=\(String(AppState.shared.user?.accountID ?? 0))&deviceID=\(String(AppState.shared.deviceUUID ?? ""))&isSmartTransaction=\(isSmartTransaction.description)"
            
            let paramData = paramString.data(using: .utf8)
            
            let earl = String(format: "https://\(Keys.baseURL):8681/upload_photo")
            
            let URL = URL(string: earl)
            var request = URLRequest(url: URL!)
            
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("yes", forHTTPHeaderField: "This-Is-A-Photo-For-Budget-App")
            request.httpBody = paramData
            
            request.httpMethod = "POST"
            request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
            request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
            request.timeoutInterval = 60
            request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")

            
            
            
            let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
                        
            let serverText = String(data: data, encoding: .utf8) ?? ""
            if AppState.shared.debugPrint { print(serverText) }
            
            print(serverText)
            
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
            
            let decodedData = try? JSONDecoder().decode(U?.self, from: data)
            
            if decodedData == nil && httpResponse?.statusCode == 200 {
                return .success(nil)
            } else {
                guard let decodedData else { return .failure(.serverError(firstLine)) }
                return .success(decodedData)
            }
            
            
            
        } catch {
            if Task.isCancelled { return .failure(.taskCancelled) }
            if ticker == 0 {
                return .failure(.connectionError)
            } else {
                try? await Task.sleep(for: .milliseconds(1000))
                return await uploadPictureOG(application: application, recordID: recordID, uuid: uuid, imageString: imageString, ticker: ticker - 1)
            }
        }
    }
    
}

//
//
//class DownloadManager: NSObject, ObservableObject {
//    static var shared = DownloadManager()
//
//    private var urlSession: URLSession!
//    @Published var tasks: [URLSessionTask] = []
//
//    override private init() {
//        super.init()
//
//        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
//
//        // Warning: Make sure that the URLSession is created only once (if an URLSession still
//        // exists from a previous download, it doesn't create a new URLSession object but returns
//        // the existing one with the old delegate object attached)
//        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
//
//        updateTasks()
//    }
//
//    func startDownload(url: URL) {
//        let task = urlSession.downloadTask(with: url)
//        task.resume()
//        tasks.append(task)
//    }
//
//    private func updateTasks() {
//        urlSession.getAllTasks { tasks in
//            DispatchQueue.main.async {
//                self.tasks = tasks
//            }
//        }
//    }
//}
//
//extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
//    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
//        os_log("Progress %f for %@", type: .debug, downloadTask.progress.fractionCompleted, downloadTask)
//    }
//
//    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        os_log("Download finished: %@", type: .info, location.absoluteString)
//        // The file at location is temporary and will be gone afterwards
//    }
//
//    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if let error = error {
//            os_log("Download error: %@", type: .error, String(describing: error))
//        } else {
//            os_log("Task finished: %@", type: .info, task)
//        }
//    }
//}
//
//
//
//class BackgroundManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
//    
//    var completionHandler: (() -> Void)? = nil
//    
//    private lazy var urlSession: URLSession = {
//        let config = URLSessionConfiguration.background(withIdentifier: "widget-bundleID")
//        config.sessionSendsLaunchEvents = true
//        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
//    }()
//    
//    func update() {
//        let task = urlSession.downloadTask(with: URL(string: "SAME URL FROM DATA MODEL HERE")!)
//        task.resume()
//    }
//    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        print(location)
//    }
//    
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        self.completionHandler!()
//        WidgetCenter.shared.reloadTimelines(ofKind: "Widget")
//        print("Background update")
//    }
//}
//
//
//
//




