//
//  LogoSearchPage.swift
//  MakeItRain
//
//  Created by Cody Burnett on 10/27/25.
//

import SwiftUI

struct LogoSearchPage<T: CanHandleLogo & Observation.Observable>: View {
    struct LogoSearchResult: Identifiable, Decodable {
        var id: UUID
        var name: String
        var domain: String
        var logoUrl: String
        
        enum CodingKeys: CodingKey { case name, domain, logo_url }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = UUID()
            self.name = try container.decode(String.self, forKey: .name)
            self.domain = try container.decode(String.self, forKey: .domain)
            self.logoUrl = try container.decode(String.self, forKey: .logo_url)
        }
    }
    @Environment(\.dismiss) var dismiss
    @Environment(FuncModel.self) private var funcModel

    var parent: T
    let parentType: XrefEnum
    
    @FocusState private var focusedField: Int?
    
    @State private var selectedItemId: UUID?
    @State private var searchResults: Array<LogoSearchResult> = []
    @State private var searchText = ""
    @State private var showLoadingSpinner = false
    
    let logoSize: CGFloat = 30
    
    var body: some View {
        NavigationStack {
            StandardContainerWithToolbar(.list) {
                if searchResults.isEmpty {
                    if showLoadingSpinner {
                        ProgressView()
                            .tint(.none)
                    } else {
                        ContentUnavailableView("No Search Results", systemImage: "magnifyingglass")
                    }
                } else {
                    
                    content
                }
            }
            
            #if os(iOS)
            .searchable(text: $searchText, prompt: Text("Search Businesses"))
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .onSubmit(of: .search) {
                showLoadingSpinner = true
                Task {
                    //try? await downloadCompanyLogo(domain: searchText)
                    try? await searchCompanies(searchTerm: searchText)
                }
            }
            .navigationTitle("Logo Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
    }
    
    
    @ViewBuilder
    var content: some View {
        Section("Results") {
            ForEach(searchResults) { result in
                Label {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(result.name)
                            Text(result.domain)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        if selectedItemId == result.id {
                            ProgressView()
                                .tint(.none)
                        }
                    }
                    
                } icon: {
                    AsyncImage(url: URL(string: result.logoUrl)!) { image in
                        image
                            .resizable()
                            .frame(width: logoSize, height: logoSize, alignment: .center)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .tint(.none)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedItemId = result.id
                    Task {
                        print(result.logoUrl)
                        let logoData = try? await downloadCompanyLogo(logoUrl: result.logoUrl)
                        //if let b64String = logoData?.base64EncodedString() {
                            parent.logo = logoData
                        //}
                        dismiss()
                    }
                }
            }
        }
    }
    
    var textfield: some View {
        //Spacer()
        #if os(iOS)
        UITextFieldWrapper(placeholder: "bankofamerica.com", text: $searchText, onSubmit: {
            focusedField = 1
        }, toolbar: {
            KeyboardToolbarView(focusedField: $focusedField)
        })
        .uiTag(0)
        .uiClearButtonMode(.whileEditing)
        .uiStartCursorAtEnd(true)
        .uiTextAlignment(.left)
        .uiKeyboardType(.system(.URL))
        .uiAutoCorrectionDisabled(true)
        #else
        StandardTextField("Title", text: $trans.title, focusedField: $focusedField, focusValue: 0)
            .onSubmit { focusedField = 1 }
        #endif
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
    
    
    func searchCompanies(searchTerm: String) async throws {
        //let LOGO_DEV_PUBLIC_KEY = "pk_DUP3h2BFQuqR-BSqb-Nnhg"
        showLoadingSpinner = true
        
        if let preparedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            let url = URL(string: "https://api.logo.dev/search?q=\(preparedSearchTerm)")!
            
            var request = URLRequest(url: url)
            
            request.setValue("Bearer sk_AflL_YtDQt-ihw_FbS-_Xw", forHTTPHeaderField: "Authorization")
            let (data, response): (Data, URLResponse) = try await URLSession.shared.data(for: request)
            //let httpResponse = response as? HTTPURLResponse
            
            let serverText = String(data: data, encoding: .utf8) ?? ""
            print(serverText)
            
            #if targetEnvironment(simulator)
            let decodedData = try! JSONDecoder().decode(Array<LogoSearchResult>?.self, from: data)
            #else
            let decodedData = try? JSONDecoder().decode(Array<LogoSearchResult>?.self, from: data)
            #endif
            
            if let decodedData {
                self.searchResults = decodedData
            }
            
            showLoadingSpinner = false
        }
    }
    
    
    func downloadCompanyLogo(logoUrl: String) async throws -> Data {
        let url = URL(string: "\(logoUrl)&format=png&retina=true")!
        let (data, _) = try await URLSession.shared.data(from: url)
        showLoadingSpinner = false
        return data
    }
    
    
//    func downloadCompanyLogoOG(domain: String) async throws {
//        let LOGO_DEV_PUBLIC_KEY = "pk_DUP3h2BFQuqR-BSqb-Nnhg"
//        let url = URL(string: "https://img.logo.dev/\(domain)?token=\(LOGO_DEV_PUBLIC_KEY)&retina=true")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        self.logoData = data
//        showLoadingSpinner = false
//    }
}
