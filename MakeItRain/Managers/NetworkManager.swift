import Foundation
import WidgetKit
import SwiftUI
import os


import Foundation

final class NetworkLogger: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    private var startTimes: [Int: Date] = [:]
    private let lock = NSLock()

    private func startTime(for task: URLSessionTask) -> Date {
        lock.lock()
        defer { lock.unlock() }

        if let existing = startTimes[task.taskIdentifier] {
            return existing
        }

        let now = Date()
        startTimes[task.taskIdentifier] = now
        return now
    }

    private func elapsed(for task: URLSessionTask) -> TimeInterval {
        let start = startTime(for: task)
        return Date().timeIntervalSince(start)
    }

    private func cleanup(for task: URLSessionTask) {
        lock.lock()
        defer { lock.unlock() }
        startTimes.removeValue(forKey: task.taskIdentifier)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let elapsed = elapsed(for: task)

        if totalBytesExpectedToSend > 0 {
            let percent = (Double(totalBytesSent) / Double(totalBytesExpectedToSend)) * 100
//            print(String(format: "[upload][task %d] %.1f%% (%lld / %lld bytes) after %.2fs",
//                         task.taskIdentifier,
//                         percent,
//                         totalBytesSent,
//                         totalBytesExpectedToSend,
//                         elapsed))
        } else {
//            print("[upload][task \(task.taskIdentifier)] \(totalBytesSent) bytes sent after \(elapsed)s")
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let elapsed = elapsed(for: dataTask)
        //print("[response][task \(dataTask.taskIdentifier)] received \(data.count) bytes after \(elapsed)s")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = elapsed(for: task)

        if let error {
            //print("[complete][task \(task.taskIdentifier)] failed after \(elapsed)s: \(error)")
        } else {
            //print("[complete][task \(task.taskIdentifier)] finished after \(elapsed)s")
        }

        cleanup(for: task)
    }
}


class NetworkManager {
    /// To Read: Plug iPhone into Mac, open console app, and start streaming.
    /// Set search type to "subsystem" and search for the key in the subsystem above (MakeItRain)
    private static let logger = Logger(subsystem: "MakeItRain", category: "Network Manager")
    
    var session: URLSession?
    private let baseURL: URL

    let logger = NetworkLogger()
    
    init() {
        guard let baseURL = URL(
            string: "\(AppState.shared.devMode ? Keys.devBaseURL : Keys.prodBaseURL)/budget_app"
        ) else {
            fatalError("Invalid API URL")
        }
        
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300

        session = URLSession(
            configuration: config,
            delegate: logger,
            delegateQueue: nil
        )
    }
    
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
            
    
    deinit {
        //request = nil
        //session = nil
        session?.invalidateAndCancel()
        //LogManager.log()
    }
    
    func createRequest(timeout: TimeInterval = 60) -> URLRequest {
        var request = URLRequest(url: baseURL)
        
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
        request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
        request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        return request
    }
    
    private func verify(httpResponse: HTTPURLResponse?, serverText: String) async -> Result<Void, AppError> {
        guard let statusCode = httpResponse?.statusCode else {
            return .failure(.serverError(serverText))
        }
        
        switch statusCode {
            
        case 200...299:
            return .success(())
            
        case 400:
            return .failure(.serverError("Server error: \(serverText)"))
            
        case 401:
            await AuthState.shared.serverAccessRevoked()
            return .failure(.accessRevoked)
            
        case 403:
            await AuthState.shared.serverAccessRevoked()
            return .failure(.incorrectCredentials)
            
        default:
            return .failure(.serverError(serverText))
        }
    }
 
    
    func singleRequest<T: Encodable, U: Decodable>(
        requestModel: RequestModel<T>,
        ticker: Int = 3,
        sessionID: String = "",
        retainTime: Bool = true,
        timeout: TimeInterval = 60
    ) async -> Result<U?, AppError> {
        
        var request = createRequest(timeout: timeout)
        request.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
        
        var sesh: String = ""
        if sessionID.isEmpty {
            sesh = UUID().uuidString
        } else {
            sesh = sessionID
        }
               
        do {
            requestModel.sessionID = sesh            
            
            let jsonData = try? encoder.encode(requestModel)
            request.httpBody = jsonData
            
            if AppState.shared.debugPrint {
                print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)")
            }
                                                
            guard let session else {
                LogManager.error("URL session error", session: sesh)
                return .failure(.sessionError)
            }
            
            let (data, response): (Data, URLResponse) = try await session.data(for: request, delegate: logger)
            let httpResponse = response as? HTTPURLResponse
            //print(httpResponse?.statusCode)
            
            /// Only retain the time if the app is in the foreground. This prevents the time from updating if something is in flight in the background, and a change happens from another device.
            #if os(iOS)
            if retainTime && AppState.shared.scenePhase == .active {
                AppState.shared.lastNetworkTime = .now
            }
            #endif
            
            let serverText = String(data: data, encoding: .utf8) ?? ""
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
            if AppState.shared.debugPrint {
                print(serverText)
            }
            
            if case .failure(let error) = await verify(httpResponse: httpResponse, serverText: serverText) {
                return .failure(error)
            }
            
            #warning("Error handling won't work with the force unwrap")
            #if targetEnvironment(simulator)
            let decodedData = try! decoder.decode(U?.self, from: data)
            #else
            let decodedData = try? decoder.decode(U?.self, from: data)
            #endif
            
            guard let decodedData else {
                LogManager.log("something went wrong with the decoded data: \(serverText)", session: sesh)
                return .failure(.serverError(firstLine))
            }
            
            LogManager.networkingSuccessful(session: sesh)
            return .success(decodedData)
                       
        } catch {
            if Task.isCancelled {
                LogManager.error("networking exception: task cancelled: \(error.localizedDescription)", session: sesh)
                return .failure(.taskCancelled)
            }
            
            if ticker == 0 {
                LogManager.error("networking exception: connection failure / ticker = 0: \(error.localizedDescription)", session: sesh)
                return .failure(.connectionError)
            }
            
            try? await Task.sleep(for: .seconds(1))
            LogManager.error("networking exception: retrying request: \(error.localizedDescription)", session: sesh)
            return await singleRequest(requestModel: requestModel, ticker: ticker - 1, sessionID: sesh, retainTime: retainTime)
        }
    }
    
    
    
    func login(
        using loginType: LoginType,
        with loginModel: LoginModel,
        ticker: Int = 3
    ) async -> Result<CBLogin?, AppError> {
        do {
            var request = createRequest(timeout: 15)
            let requestModel = RequestModel(requestType: "login", model: loginModel)
            
            if loginType == .apiKey {
                request.setValue(loginModel.apiKey, forHTTPHeaderField: "Api-Key")
            }
        
            let jsonData = try? encoder.encode(requestModel)
            request.httpBody = jsonData
            
            if AppState.shared.debugPrint { print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)") }
            
            guard let session else {
                LogManager.error("URL session error")
                return .failure(.sessionError)
            }
            
            let (data, response): (Data, URLResponse) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            //print(httpResponse?.statusCode)
            
            let serverText = String(data: data, encoding: .utf8) ?? ""
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
            if AppState.shared.debugPrint { print(serverText) }
            
            if case .failure(let error) = await verify(httpResponse: httpResponse, serverText: serverText) {
                return .failure(error)
            }
            
            if firstLine == "None" && requestModel.requestType == "login" {
                return .failure(.incorrectCredentials)
            }
                            
            #if targetEnvironment(simulator)
            let decodedData = try! decoder.decode(CBLogin?.self, from: data)
            #else
            let decodedData = try? decoder.decode(CBLogin?.self, from: data)
            #endif
            
            guard let decodedData else {
                LogManager.log("something went wrong with the decoded data: \(serverText)")
                return .failure(.serverError(firstLine))
            }
                            
            return .success(decodedData)
                        
        } catch {
            if Task.isCancelled {
                LogManager.error("networking exception: task cancelled: \(error.localizedDescription)")
                return .failure(.taskCancelled)
            }
            
            if ticker == 0 {
                LogManager.error("networking exception: connection failure / ticker = 0: \(error.localizedDescription)")
                return .failure(.connectionError)
            }
            
            try? await Task.sleep(for: .seconds(1))
            LogManager.error("networking exception: retrying request: \(error.localizedDescription)")
            return await login(using: loginType, with: loginModel, ticker: ticker - 1)
        }
    }
    
    
    
    
    
//    func longPollServer<T: Encodable, U: Decodable>(requestModel: RequestModel<T>, ticker: Int = 2, sessionID: String = "") async -> Result<U?, AppError> {
//        var sesh: String = ""
//        if sessionID.isEmpty {
//            sesh = UUID().uuidString
//        } else {
//            sesh = sessionID
//        }
//        
//        do {
//            var request: URLRequest?
//            var session: URLSession?                        
//            let earl = String(format: "https://\(Keys.baseLongPollURL)/") ///3000 internal
//            var subRequest = URLRequest(url: URL(string: earl)!)
//            
//            subRequest.httpMethod = "POST"
//            subRequest.setValue("Application/json", forHTTPHeaderField: "Content-Type")
//            subRequest.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
//            subRequest.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
//            subRequest.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
//            subRequest.timeoutInterval = 130
//            subRequest.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")
//
//            request = subRequest
//            session = URLSession.shared
//                        
//            
//            LogManager.log("starting", session: sesh)
//            requestModel.sessionID = sessionID
//            let jsonData = try? JSONEncoder().encode(requestModel)
//            LogManager.log("jsonData: \(String(data: jsonData!, encoding: .utf8)!)", session: sesh)
//            
//            request?.httpBody = jsonData
//            
//            if let session {
//                let (data, response): (Data, URLResponse) = try await session.data(for: request!)
//                let httpResponse = response as? HTTPURLResponse
//                //print(httpResponse?.statusCode)
//                
//                LogManager.log("should have a response from the server now", session: sesh)
//                
//                let serverText = String(data: data, encoding: .utf8) ?? ""
//                if AppState.shared.debugPrint { print(serverText) }
//                let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
//                
//                LogManager.log("decoding data", session: sesh)
//                
//                if httpResponse?.statusCode == 403 {
//                    return .failure(.incorrectCredentials)
//                }
//                            
//                #if targetEnvironment(simulator)
//                let decodedData = try! JSONDecoder().decode(U?.self, from: data)
//                #else
//                let decodedData = try! JSONDecoder().decode(U?.self, from: data)
//                #endif
//                LogManager.log("data has been decoded", session: sesh)
//                guard let decodedData else {
//                    LogManager.log("something went wrong with the decoded data", session: sesh)
//                    return .failure(.serverError(firstLine))
//                }
//                
//                LogManager.log("networking successful", session: sesh)
//                return .success(decodedData)
//            
//            } else {
//                LogManager.error("session error", session: sesh)
//                return .failure(.sessionError)
//            }
//                                    
//        } catch {
//            LogManager.error("networking exception \(error.localizedDescription)", session: sesh)
//            if Task.isCancelled {
//                LogManager.error("task cancelled", session: sesh)
//                return .failure(.taskCancelled)
//            }
//            if ticker == 0 {
//                LogManager.error("connection failure", session: sesh)
//                return .failure(.connectionError)
//            } else {
//                //try? await Task.sleep(for: .milliseconds(5000))
//                try? await Task.sleep(for: .seconds(5))
//                LogManager.error("retrying request", session: sesh)
//                return await longPollServer(requestModel: requestModel, ticker: ticker - 1, sessionID: sesh)
//            }
//        }
//    }
    
    
    func downloadFile(
        requestModel: RequestModel<FileRequestModel>,
        ticker: Int = 3,
        sessionID: String = "",
        retainTime: Bool = true
    ) async -> Result<Data?, AppError> {
        var request = createRequest()
        request.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
                
        var sesh: String = ""
        if sessionID.isEmpty {
            sesh = UUID().uuidString
        } else {
            sesh = sessionID
        }
               
        do {
            LogManager.log("starting", session: sesh)
            requestModel.sessionID = sessionID
            
            let jsonData = try? encoder.encode(requestModel)
            LogManager.log("jsonData: \(String(data: jsonData!, encoding: .utf8)!)", session: sesh)
            if AppState.shared.debugPrint { print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)") }
            
            
//            let earl = String(format: "https://\(Keys.baseURL):8681/get_picture")
//            //let earl = String(format: "http://\(Keys.baseURL):8677/")
//            let URL = URL(string: earl)
//            request!.url = URL
            
            request.httpBody = jsonData
            
            guard let session else {
                LogManager.error("URL session error")
                return .failure(.sessionError)
            }
            
            let (data, response): (Data, URLResponse) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            let serverText = String(data: data, encoding: .utf8) ?? ""
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
            if AppState.shared.debugPrint { print(serverText) }
            
            if retainTime { AppState.shared.lastNetworkTime = .now }
            
            //print(httpResponse?.statusCode)
            
            if case .failure(let error) = await verify(httpResponse: httpResponse, serverText: serverText) {
                return .failure(error)
            }
            
            return .success(data)
                        
        } catch {
            if Task.isCancelled {
                LogManager.error("networking exception: task cancelled: \(error.localizedDescription)", session: sesh)
                return .failure(.taskCancelled)
            }
            
            if ticker == 0 {
                LogManager.error("networking exception: connection failure / ticker = 0: \(error.localizedDescription)", session: sesh)
                return .failure(.connectionError)
            }
            
            try? await Task.sleep(for: .seconds(1))
            LogManager.error("networking exception: retrying request: \(error.localizedDescription)", session: sesh)
            return await downloadFile(requestModel: requestModel, ticker: ticker - 1, sessionID: sesh)
        }
    }
        
    
    func uploadFile<U: Decodable>(
        application: String,
        fileParent: FileParent?,
        uuid: String,
        fileData: Data,
        fileName: String,
        fileType: FileType, // e.g. "photo", "pdf", "csv", "text"
        isSmartTransaction: Bool = false,
        smartTransactionDate: Date? = nil,
        ticker: Int = 3
    ) async -> Result<U?, AppError> {
        do {
            var request = createRequest()
            request.setValue(AppState.shared.apiKey, forHTTPHeaderField: "Api-Key")
            
            let metadata: [String: String] = [
                "application": application,
                "type": fileType.rawValue,
                "extension": fileType.ext,
                "record_id": fileParent?.id ?? "",
                "related_type_id": String(fileParent?.type.id ?? 0),
                "uuid": uuid,
                "user_id": String(AppState.shared.user?.id ?? 0),
                "account_id": String(AppState.shared.user?.accountID ?? 0),
                "device_uuid": String(AppState.shared.deviceUUID ?? ""),
                "is_smart_transaction": isSmartTransaction.description,
                "smart_transaction_date": smartTransactionDate?.string(to: .serverDate) ?? ""
            ]
            
            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else { return .failure(.failedToUploadPhoto) }
            
            var body = Data()
            let boundary = "Boundary-\(UUID().uuidString)"
            let new = "\r\n"
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue("yes", forHTTPHeaderField: "This-Is-A-File")
                                                                                    
            body.append("--\(boundary)\(new)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"json\"\(new)".data(using: .utf8)!)
            body.append("Content-Type: application/json\(new)\(new)".data(using: .utf8)!)
            body.append(jsonString.data(using: .utf8)!)
            body.append("\(new)".data(using: .utf8)!)
            
            body.append("--\(boundary)\(new)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(new)".data(using: .utf8)!)
            body.append("Content-Type: \(fileType.mimeType)\(new)\(new)".data(using: .utf8)!)
            body.append(fileData)
            body.append("\(new)".data(using: .utf8)!)
                        
            body.append("--\(boundary)--\(new)".data(using: .utf8)!)
              
            let (data, response) = try await URLSession.shared.upload(for: request, from: body)
            let httpResponse = response as? HTTPURLResponse
        
            let serverText = String(data: data, encoding: .utf8) ?? ""
            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
            if AppState.shared.debugPrint { print(serverText) }
            
            if case .failure(let error) = await verify(httpResponse: httpResponse, serverText: serverText) {
                return .failure(error)
            }
                                                            
            let decodedData = try? decoder.decode(U?.self, from: data)
            if decodedData == nil && httpResponse?.statusCode == 200 {
                return .success(nil)
            } else {
                guard let decodedData else { return .failure(.serverError(firstLine)) }
                return .success(decodedData)
            }
                                    
        } catch {
            if Task.isCancelled {
                LogManager.error("networking exception: task cancelled: \(error.localizedDescription)")
                return .failure(.taskCancelled)
            }
            
            if ticker == 0 {
                LogManager.error("networking exception: connection failure / ticker = 0: \(error.localizedDescription)")
                return .failure(.connectionError)
            }
            
            try? await Task.sleep(for: .seconds(1))
            LogManager.error("networking exception: retrying request: \(error.localizedDescription)")
            return await uploadFile(
                application: application,
                fileParent: fileParent,
                uuid: uuid,
                fileData: fileData,
                fileName: fileName,
                fileType: fileType,
                ticker: ticker - 1
            )
        }
    }
    
    
    
//    func uploadPictureThatTheServerDoesntLike<U: Decodable>(application: String, recordID: String, uuid: String, imageString: String, isSmartTransaction: Bool = false, ticker: Int = 3) async -> Result<U?, AppError> {
//        do {
//            //let paramString = "application=\(application)&type=photo&recordID=\(recordID)&uuid=\(uuid)&image=\(imageString)&userID=\(String(AppState.shared.user?.id ?? 0))&accountID=\(String(AppState.shared.user?.accountID ?? 0))&deviceID=\(String(AppState.shared.deviceUUID ?? ""))&isSmartTransaction=\(isSmartTransaction.description)"
//            
//            
//            do {
//                let apiKey = try KeychainManager().getFromKeychain(key: "api_key")
//                request?.setValue(apiKey, forHTTPHeaderField: "Api-Key")
//            } catch {
//                print("Cannot find apiKey")
//            }
//            
//            
//            let metadata: [String: String] = [
//                "application": application,
//                "type": "photo",
//                "recordID": recordID,
//                "uuid": uuid,
//                "userID": String(AppState.shared.user?.id ?? 0),
//                "accountID": String(AppState.shared.user?.accountID ?? 0),
//                "deviceID": String(AppState.shared.deviceUUID ?? ""),
//                "isSmartTransaction": isSmartTransaction.description
//            ]
//            
//            guard
//                let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
//                let jsonString = String(data: jsonData, encoding: .utf8)
//            else { return .failure(.failedToUploadPhoto)}
//            
//            let bodyString = "image=\(imageString)&json=\(jsonString)"
//            
//            
//            
//            let paramData = bodyString.data(using: .utf8)
//            request?.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//            request?.setValue("yes", forHTTPHeaderField: "This-Is-A-Photo-For-Budget-App")
//            request?.httpBody = paramData
//            
//            let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request!)
//            let httpResponse = response as? HTTPURLResponse
//        
//            let serverText = String(data: data, encoding: .utf8) ?? ""
//            if AppState.shared.debugPrint { print(serverText) }
//            
//            print(serverText)
//            
//            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
//                                                            
//            let decodedData = try? JSONDecoder().decode(U?.self, from: data)
//            if decodedData == nil && httpResponse?.statusCode == 200 {
//                return .success(nil)
//            } else {
//                guard let decodedData else { return .failure(.serverError(firstLine)) }
//                return .success(decodedData)
//            }
//            
//            
//            
//        } catch {
//            if Task.isCancelled { return .failure(.taskCancelled) }
//            if ticker == 0 {
//                return .failure(.connectionError)
//            } else {
//                try? await Task.sleep(for: .milliseconds(1000))
//                return await uploadPictureThatTheServerDoesntLike(application: application, recordID: recordID, uuid: uuid, imageString: imageString, ticker: ticker - 1)
//            }
//        }
//    }
//    
//    
//    
//    func uploadPictureOG<U: Decodable>(application: String, recordID: String, uuid: String, imageString: String, isSmartTransaction: Bool = false, ticker: Int = 3) async -> Result<U?, AppError> {
//        do {
//            let paramString = "application=\(application)&type=photo&recordID=\(recordID)&uuid=\(uuid)&image=\(imageString)&userID=\(String(AppState.shared.user?.id ?? 0))&accountID=\(String(AppState.shared.user?.accountID ?? 0))&deviceID=\(String(AppState.shared.deviceUUID ?? ""))&isSmartTransaction=\(isSmartTransaction.description)"
//            
//            let paramData = paramString.data(using: .utf8)
//            
//            let earl = String(format: "https://\(Keys.baseURL):8681/upload_photo")
//            
//            let URL = URL(string: earl)
//            var request = URLRequest(url: URL!)
//            
//            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//            request.setValue("yes", forHTTPHeaderField: "This-Is-A-Photo-For-Budget-App")
//            request.httpBody = paramData
//            
//            request.httpMethod = "POST"
//            request.setValue(Keys.authPhrase, forHTTPHeaderField: "Auth-Phrase")
//            request.setValue(Keys.authID, forHTTPHeaderField: "Auth-ID")
//            request.timeoutInterval = 60
//            request.setValue(Keys.userAgent, forHTTPHeaderField: "User-Agent")
//
//            
//            
//            
//            let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
//            let httpResponse = response as? HTTPURLResponse
//                        
//            let serverText = String(data: data, encoding: .utf8) ?? ""
//            if AppState.shared.debugPrint { print(serverText) }
//            
//            print(serverText)
//            
//            let firstLine = String(serverText.split(whereSeparator: \.isNewline).first ?? "") /// used to grab the error from the response
//            
//            let decodedData = try? JSONDecoder().decode(U?.self, from: data)
//            
//            if decodedData == nil && httpResponse?.statusCode == 200 {
//                return .success(nil)
//            } else {
//                guard let decodedData else { return .failure(.serverError(firstLine)) }
//                return .success(decodedData)
//            }
//            
//            
//            
//        } catch {
//            if Task.isCancelled { return .failure(.taskCancelled) }
//            if ticker == 0 {
//                return .failure(.connectionError)
//            } else {
//                try? await Task.sleep(for: .milliseconds(1000))
//                return await uploadPictureOG(application: application, recordID: recordID, uuid: uuid, imageString: imageString, ticker: ticker - 1)
//            }
//        }
//    }
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




