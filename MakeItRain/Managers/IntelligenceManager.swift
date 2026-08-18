//
//  IntelligenceManager.swift
//  MakeItRain
//
//  Created by Cody Burnett on 8/15/26.
//

import Foundation

class IntelligenceManager {
    var request: URLRequest?
    var session: URLSession?
    let logger = NetworkLogger()
    
    init(timeout: TimeInterval = 60) {
        //let url = URL(string: "https://api.openai.com/v1/chat/completions")
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout

        self.request = request
        //self.session = URLSession.shared
        //self.session?.delegate = NetworkLogger()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300

        session = URLSession(
            configuration: config,
            delegate: logger,
            delegateQueue: nil
        )
    }
    
    func loadMarkdown(named name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "md") else {
            return nil
        }

        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    
    func request<U: Decodable>(base64Image: String, ticker: Int = 3) async -> Result<U?, AppError> {
        
        guard let instructions = loadMarkdown(named: "ItemizeReceipt") else {
            return .failure(.serverError("NO MARKDOWN"))
        }
        
        let payload = OpenAIRequest(
            //model: "gpt-4.1",
//            model: "gpt-5.6-sol",
            model: "gpt-5.6-luna",
            input: [
                .init(
                    role: "user",
                    content: [
                        .init(type: "input_text", text: instructions, imageURL: nil),
                        .init(type: "input_image", text: nil, imageURL: "data:image/jpeg;base64,\(base64Image)")
                    ]
                )
            ]
        )

        do {
            //let data = try JSONSerialization.data(withJSONObject: payload)
            //request?.httpBody = data
            
            let jsonData = try? JSONEncoder().encode(payload)
            if AppState.shared.debugPrint { print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)") }
            //print("jsonData: \(String(data: jsonData!, encoding: .utf8)!)")
                        
            request?.httpBody = jsonData
            
            if let session {
                let (data, response): (Data, URLResponse) = try await session.data(for: request!)
                let httpResponse = response as? HTTPURLResponse
                                                             
                let serverText = String(data: data, encoding: .utf8) ?? ""
                if AppState.shared.debugPrint { print(serverText) }
                        
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)

                guard let text = openAIResponse.output
                    .flatMap(\.content)
                    .first(where: { $0.type == "output_text" })?
                    .text
                else {
                    return .failure(.serverError("No output text"))
                }

                guard let textData = text.data(using: .utf8) else {
                    return .failure(.serverError("Could not convert response text to data"))
                }
                
                #if targetEnvironment(simulator)
                let decodedData = try! decoder.decode(U.self, from: textData)
                #else
                let decodedData = try decoder.decode(U.self, from: textData)
                #endif

                return .success(decodedData)
                                                
            } else {
                return .failure(.sessionError)
            }
                        
        } catch {
            print(error.localizedDescription)
            if Task.isCancelled {
                return .failure(.taskCancelled)
            }
            if ticker == 0 {
                return .failure(.connectionError)
            } else {
                //try? await Task.sleep(for: .milliseconds(1000))
                try? await Task.sleep(for: .seconds(5))
                return await request(base64Image: base64Image, ticker: ticker - 1)
            }
        }
    }
}

//
//struct OpenAIRequest: Encodable {
//    let model: String
//    let messages: [Message]
//    let maxTokens: Int
//
//    enum CodingKeys: String, CodingKey {
//        case model
//        case messages
//        case maxTokens = "max_tokens"
//    }
//
//    struct Message: Encodable {
//        let role: String
//        let content: [Content]
//    }
//
//    struct Content: Encodable {
//        let type: String
//        let text: String?
//        let imageURL: ImageURL?
//
//        enum CodingKeys: String, CodingKey {
//            case type
//            case text
//            case imageURL = "image_url"
//        }
//    }
//
//    struct ImageURL: Encodable {
//        let url: String
//    }
//}

struct OpenAIRequest: Encodable {
    let model: String
    let input: [Input]

    struct Input: Encodable {
        let role: String
        let content: [Content]
    }

    struct Content: Encodable {
        let type: String
        let text: String?
        let imageURL: String?

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageURL = "image_url"
        }
    }
}


struct OpenAIResponse: Decodable {
    let output: [Output]

    struct Output: Decodable {
        let content: [Content]
    }

    struct Content: Decodable {
        let type: String
        let text: String?
    }
}


struct ReceiptResponse: Decodable {
    let isReceipt: Bool
    let items: [ReceiptItem]

    enum CodingKeys: String, CodingKey {
        case isReceipt = "is_receipt"
        case items
    }
}

struct ReceiptItem: Decodable {
    let itemName: String
    let cost: String

    enum CodingKeys: String, CodingKey {
        case itemName = "item name"
        case cost
    }
}
