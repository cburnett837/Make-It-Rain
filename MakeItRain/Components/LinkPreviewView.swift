//
//  LinkPresentationView.swift
//  MakeItRain
//
//  Created by Cody Burnett on 3/27/25.
//

import SwiftUI

import SwiftUI
import LinkPresentation
import UniformTypeIdentifiers

#if os(iOS)
struct LinkPreviewView: UIViewRepresentable {
    var previewURL: URL

    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: previewURL)
        let provider = LPMetadataProvider()

        provider.startFetchingMetadata(for: previewURL) { (metadata, error) in
            guard let metadata = metadata, error == nil else { return }

            DispatchQueue.main.async {
                linkView.metadata = metadata
                linkView.sizeToFit()
            }
        }

        return linkView
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) {}
}




struct LinkItemView: View {
    var url: URL?
    @State private var isValidUrl = true
    @State private var metadata: LPLinkMetadata? = nil
    @State private var imageStatus: ImageStatus = .loading
    
//    init(link: String) {
//        _url = State(wrappedValue: URL(string: link))
//    }
    
    var body: some View {
        VStack {
            if isValidUrl, let url {
                Link(destination: url) {
                    HStack(alignment: .center) {
                        VStack {
                            switch imageStatus {
                            case .loading:
                                ProgressView()
                                    .tint(.none)

                            case .finished(let image):
                                image
                                    .resizable()
                                    .scaledToFill()

                            case .failed:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                                    .foregroundStyle(.gray)
                            }
                        }
                        .clipped()
                        .frame(width: 90, height: 90)
                        .cornerRadius(15)

                        VStack(alignment: .leading) {
                            Text(metadata?.title ?? "url title placeholder")
                                .font(.body)
                                .redacted(reason: metadata == nil ? .placeholder : [])

                            Text(metadata?.url?.host ?? "url host placeholder")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .redacted(reason: metadata == nil ? .placeholder : [])
                        }
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "circle.slash")
                        .foregroundStyle(.red)
                    Text("Provided link is invalid")
                        .font(.title3).bold()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.gray.opacity(0.2))
        }
        .task(id: url) {
            await fetchMetadata()
        }
    }
    
    
    private func fetchMetadata() async {
        guard let url else {
            isValidUrl = false
            return
        }

        do {
            metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
            await loadImage(from: metadata?.imageProvider)

        } catch {
            print("Error fetching URL metadata: \(error.localizedDescription)")
            isValidUrl = false
        }
    }
    
    
    private func loadImage(from imageProvider: NSItemProvider?) async {
        let imageType = UTType.image.identifier
        do {
            guard let imageProvider, imageProvider.hasItemConformingToTypeIdentifier(imageType) else {
                imageStatus = .failed(LoadingError.contentUnavailable)
                return
            }

            let item = try await imageProvider.loadItem(forTypeIdentifier: imageType)
            
            if item is UIImage, let image = item as? UIImage {
                imageStatus = .finished(Image(uiImage: image))
                
            } else if item is URL {
                guard let url = item as? URL,
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data)
                else {
                    imageStatus = .failed(LoadingError.contentTypeNotSupported)
                    return
                }
                imageStatus = .finished(Image(uiImage: image))
                
            } else if item is Data {
                guard let data = item as? Data, let image = UIImage(data: data) else {
                    imageStatus = .failed(LoadingError.contentTypeNotSupported)
                    return
                }
                imageStatus = .finished(Image(uiImage: image))
            }
        } catch {
            print("Error loading Image: \(error.localizedDescription)")
            imageStatus = .failed(error)
        }
    }
    
}


enum ImageStatus {
    case loading
    case finished(Image)
    case failed(Error)
}

enum LoadingError: Error {
    case contentUnavailable
    case contentTypeNotSupported
}
#endif
