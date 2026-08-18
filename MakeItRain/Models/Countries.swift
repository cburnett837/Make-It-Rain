//
//  Countries.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/27/26.
//

import Foundation
import MapKit
import SwiftUI
//
//struct MorphingView<From: View, To: View>: View {
//    var blurRadius: CGFloat
//    var toggle: Bool
//    @ViewBuilder var from: From
//    @ViewBuilder var to: To
//    
//    var body: some View {
//        ZStack {
//            if !toggle {
//                from
//                    .contentTransition(.identity)
//                    .transition(.opacity)
//            }
//            
//            if toggle {
//                to
//                    .contentTransition(.identity)
//                    .transition(.opacity)
//            }
//        }
//        .modifier(MorphingModifier(progress: toggle ? 1 : 0, blurRadius: blurRadius))
//    }
//}
//
//@Animatable
//fileprivate struct MorphingModifier: ViewModifier {
//    var progress: CGFloat
//    @AnimatableIgnored var blurRadius: CGFloat
//    
//    func body(content: Content) -> some View {
//        content
//            .compositingGroup()
//            .blur(radius: blurProgress * blurRadius)
//            .visualEffect { content, proxy in
//                content
//                    .layerEffect(ShaderLibrary.alphaThreshold(), maxSampleOffset: proxy.size)
//            }
//    }
//    
//    private var blurProgress: CGFloat {
//        return progress > 0.5 ? abs(1.0 - progress) : progress
//    }
//}


struct CountryPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var country: Country?
    var showNoneOption: Bool = true
    
    @State private var searchText = ""
                    
    
    var relevantCountries: [Country] {
        let countries = Countries.list.filter {
            [
                Countries.homeCountry.code,
                LocationManager.shared.currentCountry,
                country?.code
            ].contains($0.code)
        }

//        if let country {
//            countries.append(country)
//        }
//        
//        if country?.code != Countries.homeCountry.code {
//            countries.append(Countries.homeCountry)
//        }
        

        return Array(Set(countries)).sorted { $0.name < $1.name }
    }
    
    
    var filteredCountries: [Country] {
        return Countries.list.filter {
            searchText.isEmpty ? true : (
                $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
                || $0.currencyCode.localizedCaseInsensitiveContains(searchText)
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if showNoneOption {
                    line(for: nil)
                }
                
                Section {
                    ForEach(relevantCountries) { cunt in
                        line(for: cunt)
                    }
                } header: {
                    Text("Relevant Currencies")
                }
                
//                Section("Your Home Country") {
//                    line(for: Countries.homeCountry)
//                }
                
                Section("All Currencies") {
                    ForEach(filteredCountries) { cunt in
                        line(for: cunt)
                    }
                }
            }
            .navigationTitle("Currencies")
            .searchable(text: $searchText, prompt: "Search Countries & Currencies")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { closeButton }
            }
            #endif
        }
    }
    
    @ViewBuilder
    func line(for country: Country?) -> some View {
        Button {
            self.country = country
            dismiss()
        } label: {
            HStack {
                if let country {
                    FlagCircle(code: country.code)
                    
                    //Text(country.flagEmoji)
                    Text(country.name)
                        .schemeBasedForegroundStyle()
                    
                    Spacer()
                    
                    Text("(\(country.currencyCode))")
                        .foregroundStyle(.secondary)
                    
                } else {
                    Text("None")
                        .schemeBasedForegroundStyle()
                    
                    Spacer()
                }
                
                if self.country == country {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.theme)
                }
                
            }
            .schemeBasedForegroundStyle()
        }
    }
    
    var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .schemeBasedForegroundStyle()
        }
    }
}


struct Country: Hashable, Identifiable {
    var id: Int
    var name: String
    var code: String
    let currencyCode: String
    var coords: CLLocationCoordinate2D
    //var exchangeRate: Decimal?
    //var rateValidityDate: Date?
    
    var globeSymbol: String {
        if coords.longitude <= -30 { return "globe.americas" }
        if coords.longitude > -30 && coords.longitude < 45 { return "globe.europe.africa" }
        if coords.longitude >= 45 && coords.longitude < 90 { return "globe.central.south.asia" }
        return "globe.asia.australia"
    }
    
    var flagEmoji: String {
        code
            .uppercased()
            .unicodeScalars
            .compactMap {
                UnicodeScalar(127397 + $0.value)
            }
            .map(String.init)
            .joined()
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


struct CountryCurrencyDecodable: Decodable {
    var id: Int
    var exchangeRate: Decimal?
    var rateValidityDate: Date?
        
    enum CodingKeys: CodingKey { case id, rate_relative_to_usd, validity_date }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.exchangeRate = try container.decode(Decimal.self, forKey: .rate_relative_to_usd)
        self.rateValidityDate = try container.decode(Date.self, forKey: .validity_date)
    }
}




struct Countries {
    static var list: [Country] = [
        Country(id: 1, name: "Afghanistan", code: "AF", currencyCode: "AFN", coords: .init(latitude: 33.93911, longitude: 67.709953)),
        Country(id: 2, name: "Albania", code: "AL", currencyCode: "ALL", coords: .init(latitude: 41.153332, longitude: 20.168331)),
        Country(id: 3, name: "Algeria", code: "DZ", currencyCode: "DZD", coords: .init(latitude: 28.033886, longitude: 1.659626)),
        Country(id: 4, name: "American Samoa", code: "AS", currencyCode: "USD", coords: .init(latitude: -14.270972, longitude: -170.132217)),
        Country(id: 5, name: "Andorra", code: "AD", currencyCode: "EUR", coords: .init(latitude: 42.546245, longitude: 1.601554)),
        Country(id: 6, name: "Angola", code: "AO", currencyCode: "AOA", coords: .init(latitude: -11.202692, longitude: 17.873887)),
        Country(id: 7, name: "Anguilla", code: "AI", currencyCode: "XCD", coords: .init(latitude: 18.220554, longitude: -63.068615)),
        Country(id: 8, name: "Antigua and Barbuda", code: "AG", currencyCode: "XCD", coords: .init(latitude: 17.060816, longitude: -61.796428)),
        Country(id: 9, name: "Argentina", code: "AR", currencyCode: "ARS", coords: .init(latitude: -38.416097, longitude: -63.616672)),
        Country(id: 10, name: "Armenia", code: "AM", currencyCode: "AMD", coords: .init(latitude: 40.069099, longitude: 45.038189)),
        Country(id: 11, name: "Aruba", code: "AW", currencyCode: "AWG", coords: .init(latitude: 12.52111, longitude: -69.968338)),
        Country(id: 12, name: "Australia", code: "AU", currencyCode: "AUD", coords: .init(latitude: -25.274398, longitude: 133.775136)),
        Country(id: 13, name: "Austria", code: "AT", currencyCode: "EUR", coords: .init(latitude: 47.516231, longitude: 14.550072)),
        Country(id: 14, name: "Azerbaijan", code: "AZ", currencyCode: "AZN", coords: .init(latitude: 40.143105, longitude: 47.576927)),
        Country(id: 15, name: "Bahamas", code: "BS", currencyCode: "BSD", coords: .init(latitude: 25.03428, longitude: -77.39628)),
        Country(id: 16, name: "Bahrain", code: "BH", currencyCode: "BHD", coords: .init(latitude: 25.930414, longitude: 50.637772)),
        Country(id: 17, name: "Bangladesh", code: "BD", currencyCode: "BDT", coords: .init(latitude: 23.684994, longitude: 90.356331)),
        Country(id: 18, name: "Barbados", code: "BB", currencyCode: "BBD", coords: .init(latitude: 13.193887, longitude: -59.543198)),
        Country(id: 19, name: "Belarus", code: "BY", currencyCode: "BYN", coords: .init(latitude: 53.709807, longitude: 27.953389)),
        Country(id: 20, name: "Belgium", code: "BE", currencyCode: "EUR", coords: .init(latitude: 50.503887, longitude: 4.469936)),
        Country(id: 21, name: "Belize", code: "BZ", currencyCode: "BZD", coords: .init(latitude: 17.189877, longitude: -88.49765)),
        Country(id: 22, name: "Benin", code: "BJ", currencyCode: "XOF", coords: .init(latitude: 9.30769, longitude: 2.315834)),
        Country(id: 23, name: "Bermuda", code: "BM", currencyCode: "BMD", coords: .init(latitude: 32.321384, longitude: -64.75737)),
        Country(id: 24, name: "Bhutan", code: "BT", currencyCode: "BTN", coords: .init(latitude: 27.514162, longitude: 90.433601)),
        Country(id: 25, name: "Bolivia", code: "BO", currencyCode: "BOB", coords: .init(latitude: -16.290154, longitude: -63.588653)),
        Country(id: 26, name: "Bosnia-Herzegovina", code: "BA", currencyCode: "BAM", coords: .init(latitude: 43.915886, longitude: 17.679076)),
        Country(id: 27, name: "Botswana", code: "BW", currencyCode: "BWP", coords: .init(latitude: -22.328474, longitude: 24.684866)),
        Country(id: 28, name: "Brazil", code: "BR", currencyCode: "BRL", coords: .init(latitude: -14.235004, longitude: -51.92528)),
        Country(id: 29, name: "British Indian Ocean Terr", code: "IO", currencyCode: "USD", coords: .init(latitude: -6.343194, longitude: 71.876519)),
        Country(id: 30, name: "British Virgin Islands", code: "VG", currencyCode: "USD", coords: .init(latitude: 18.420695, longitude: -64.639968)),
        Country(id: 31, name: "Brunei", code: "BN", currencyCode: "BND", coords: .init(latitude: 4.535277, longitude: 114.727669)),
        Country(id: 32, name: "Bulgaria", code: "BG", currencyCode: "BGN", coords: .init(latitude: 42.733883, longitude: 25.48583)),
        Country(id: 33, name: "Burkina", code: "BF", currencyCode: "XOF", coords: .init(latitude: 12.238333, longitude: -1.561593)),
        Country(id: 35, name: "Burundi", code: "BI", currencyCode: "BIF", coords: .init(latitude: -3.373056, longitude: 29.918886)),
        Country(id: 36, name: "Cambodia", code: "KH", currencyCode: "KHR", coords: .init(latitude: 12.565679, longitude: 104.990963)),
        Country(id: 37, name: "Cameroon", code: "CM", currencyCode: "XAF", coords: .init(latitude: 7.369722, longitude: 12.354722)),
        Country(id: 38, name: "Canada", code: "CA", currencyCode: "CAD", coords: .init(latitude: 56.130366, longitude: -106.346771)),
        Country(id: 39, name: "Cape Verde", code: "CV", currencyCode: "CVE", coords: .init(latitude: 16.002082, longitude: -24.013197)),
        Country(id: 40, name: "Cayman Islands", code: "KY", currencyCode: "KYD", coords: .init(latitude: 19.513469, longitude: -80.566956)),
        Country(id: 41, name: "Central African Republic", code: "CF", currencyCode: "XAF", coords: .init(latitude: 6.611111, longitude: 20.939444)),
        Country(id: 42, name: "Chad", code: "TD", currencyCode: "XAF", coords: .init(latitude: 15.454166, longitude: 18.732207)),
        Country(id: 43, name: "Chile", code: "CL", currencyCode: "CLP", coords: .init(latitude: -35.675147, longitude: -71.542969)),
        Country(id: 44, name: "China", code: "CN", currencyCode: "CNY", coords: .init(latitude: 35.86166, longitude: 104.195397)),
        Country(id: 45, name: "Christmas Island", code: "CX", currencyCode: "AUD", coords: .init(latitude: -10.447525, longitude: 105.690449)),
        Country(id: 46, name: "Cocos (Keeling) Island", code: "CC", currencyCode: "AUD", coords: .init(latitude: -12.164165, longitude: 96.870956)),
        Country(id: 47, name: "Colombia", code: "CO", currencyCode: "COP", coords: .init(latitude: 4.570868, longitude: -74.297333)),
        Country(id: 48, name: "Comoros", code: "KM", currencyCode: "KMF", coords: .init(latitude: -11.875001, longitude: 43.872219)),
        Country(id: 49, name: "Congo (Brazzaville)", code: "CG", currencyCode: "XAF", coords: .init(latitude: -0.228021, longitude: 15.827659)),
        Country(id: 50, name: "Congo (Kinshasa)", code: "CD", currencyCode: "CDF", coords: .init(latitude: -4.038333, longitude: 21.758664)),
        Country(id: 51, name: "Cook Islands", code: "CK", currencyCode: "NZD", coords: .init(latitude: -21.236736, longitude: -159.777671)),
        Country(id: 52, name: "Costa Rica", code: "CR", currencyCode: "CRC", coords: .init(latitude: 9.748917, longitude: -83.753428)),
        Country(id: 53, name: "Croatia", code: "HR", currencyCode: "EUR", coords: .init(latitude: 45.1, longitude: 15.2)),
        Country(id: 54, name: "Cuba", code: "CU", currencyCode: "CUP", coords: .init(latitude: 21.521757, longitude: -77.781167)),
        Country(id: 55, name: "Cyprus", code: "CY", currencyCode: "EUR", coords: .init(latitude: 35.126413, longitude: 33.429859)),
        Country(id: 56, name: "Czech Republic", code: "CZ", currencyCode: "CZK", coords: .init(latitude: 49.817492, longitude: 15.472962)),
        Country(id: 57, name: "Denmark", code: "DK", currencyCode: "DKK", coords: .init(latitude: 56.26392, longitude: 9.501785)),
        Country(id: 58, name: "Djibouti", code: "DJ", currencyCode: "DJF", coords: .init(latitude: 11.825138, longitude: 42.590275)),
        Country(id: 59, name: "Dominica", code: "DM", currencyCode: "XCD", coords: .init(latitude: 15.414999, longitude: -61.370976)),
        Country(id: 60, name: "Dominican Republic", code: "DO", currencyCode: "DOP", coords: .init(latitude: 18.735693, longitude: -70.162651)),
        Country(id: 61, name: "Ecuador", code: "EC", currencyCode: "USD", coords: .init(latitude: -1.831239, longitude: -78.183406)),
        Country(id: 62, name: "Egypt", code: "EG", currencyCode: "EGP", coords: .init(latitude: 26.820553, longitude: 30.802498)),
        Country(id: 63, name: "El Salvador", code: "SV", currencyCode: "USD", coords: .init(latitude: 13.794185, longitude: -88.89653)),
        Country(id: 64, name: "Equatorial Guinea", code: "GQ", currencyCode: "XAF", coords: .init(latitude: 1.650801, longitude: 10.267895)),
        Country(id: 65, name: "Eritrea", code: "ER", currencyCode: "ERN", coords: .init(latitude: 15.179384, longitude: 39.782334)),
        Country(id: 66, name: "Estonia", code: "EE", currencyCode: "EUR", coords: .init(latitude: 58.595272, longitude: 25.013607)),
        Country(id: 67, name: "Ethiopia", code: "ET", currencyCode: "ETB", coords: .init(latitude: 9.145, longitude: 40.489673)),
        Country(id: 68, name: "Falkland Islands", code: "FK", currencyCode: "FKP", coords: .init(latitude: -51.796253, longitude: -59.523613)),
        Country(id: 69, name: "Faroe Islands", code: "FO", currencyCode: "DKK", coords: .init(latitude: 61.892635, longitude: -6.911806)),
        Country(id: 70, name: "Fedrated States of Micronesia", code: "FM", currencyCode: "USD", coords: .init(latitude: 7.425554, longitude: 150.550812)),
        Country(id: 71, name: "Fiji", code: "FJ", currencyCode: "FJD", coords: .init(latitude: -16.578193, longitude: 179.414413)),
        Country(id: 72, name: "Finland", code: "FI", currencyCode: "EUR", coords: .init(latitude: 61.92411, longitude: 25.748151)),
        Country(id: 73, name: "France", code: "FR", currencyCode: "EUR", coords: .init(latitude: 46.227638, longitude: 2.213749)),
        Country(id: 74, name: "French Guiana", code: "GF", currencyCode: "EUR", coords: .init(latitude: 3.933889, longitude: -53.125782)),
        Country(id: 75, name: "French Polynesia", code: "PF", currencyCode: "XPF", coords: .init(latitude: -17.679742, longitude: -149.406843)),
        Country(id: 76, name: "French Southern and Antarctic Lands", code: "TF", currencyCode: "EUR", coords: .init(latitude: -49.280366, longitude: 69.348557)),
        Country(id: 77, name: "Gabon", code: "GA", currencyCode: "XAF", coords: .init(latitude: -0.803689, longitude: 11.609444)),
        Country(id: 78, name: "Gambia", code: "GM", currencyCode: "GMD", coords: .init(latitude: 13.443182, longitude: -15.310139)),
        Country(id: 79, name: "Gaza Strip Administered by Israel", code: "GZ", currencyCode: "ILS", coords: .init(latitude: 31.354676, longitude: 34.308825)),
        Country(id: 80, name: "Georgia", code: "GE", currencyCode: "GEL", coords: .init(latitude: 42.315407, longitude: 43.356892)),
        Country(id: 81, name: "Germany", code: "DE", currencyCode: "EUR", coords: .init(latitude: 51.165691, longitude: 10.451526)),
        Country(id: 82, name: "Ghana", code: "GH", currencyCode: "GHS", coords: .init(latitude: 7.946527, longitude: -1.023194)),
        Country(id: 83, name: "Gibraltar", code: "GI", currencyCode: "GIP", coords: .init(latitude: 36.137741, longitude: -5.345374)),
        Country(id: 84, name: "Greece", code: "GR", currencyCode: "EUR", coords: .init(latitude: 39.074208, longitude: 21.824312)),
        Country(id: 85, name: "Greenland", code: "GL", currencyCode: "DKK", coords: .init(latitude: 71.706936, longitude: -42.604303)),
        Country(id: 86, name: "Grenada", code: "GD", currencyCode: "XCD", coords: .init(latitude: 12.262776, longitude: -61.604171)),
        Country(id: 87, name: "Guadeloupe", code: "GP", currencyCode: "EUR", coords: .init(latitude: 16.995971, longitude: -62.067641)),
        Country(id: 88, name: "Guam", code: "GU", currencyCode: "USD", coords: .init(latitude: 13.444304, longitude: 144.793731)),
        Country(id: 89, name: "Guatemala", code: "GT", currencyCode: "GTQ", coords: .init(latitude: 15.783471, longitude: -90.230759)),
        Country(id: 90, name: "Guinea", code: "GN", currencyCode: "GNF", coords: .init(latitude: 9.945587, longitude: -9.696645)),
        Country(id: 91, name: "Guinea-Bissau", code: "GW", currencyCode: "XOF", coords: .init(latitude: 11.803749, longitude: -15.180413)),
        Country(id: 92, name: "Guyana", code: "GY", currencyCode: "GYD", coords: .init(latitude: 4.860416, longitude: -58.93018)),
        Country(id: 93, name: "Haiti", code: "HT", currencyCode: "HTG", coords: .init(latitude: 18.971187, longitude: -72.285215)),
        Country(id: 94, name: "Heard and McDonald Islands", code: "HM", currencyCode: "AUD", coords: .init(latitude: -53.08181, longitude: 73.504158)),
        Country(id: 95, name: "Honduras", code: "HN", currencyCode: "HNL", coords: .init(latitude: 15.199999, longitude: -86.241905)),
        Country(id: 96, name: "Hong Kong", code: "HK", currencyCode: "HKD", coords: .init(latitude: 22.396428, longitude: 114.109497)),
        Country(id: 97, name: "Hungary", code: "HU", currencyCode: "HUF", coords: .init(latitude: 47.162494, longitude: 19.503304)),
        Country(id: 98, name: "Iceland", code: "IS", currencyCode: "ISK", coords: .init(latitude: 64.963051, longitude: -19.020835)),
        Country(id: 99, name: "India", code: "IN", currencyCode: "INR", coords: .init(latitude: 20.593684, longitude: 78.96288)),
        Country(id: 100, name: "Indonesia", code: "ID", currencyCode: "IDR", coords: .init(latitude: -0.789275, longitude: 113.921327)),
        Country(id: 102, name: "Iran", code: "IR", currencyCode: "IRR", coords: .init(latitude: 32.427908, longitude: 53.688046)),
        Country(id: 103, name: "Iraq", code: "IQ", currencyCode: "IQD", coords: .init(latitude: 33.223191, longitude: 43.679291)),
        Country(id: 104, name: "Ireland", code: "IE", currencyCode: "EUR", coords: .init(latitude: 53.41291, longitude: -8.24389)),
        Country(id: 105, name: "Israel", code: "IL", currencyCode: "ILS", coords: .init(latitude: 31.046051, longitude: 34.851612)),
        Country(id: 106, name: "Italy", code: "IT", currencyCode: "EUR", coords: .init(latitude: 41.87194, longitude: 12.56738)),
        Country(id: 107, name: "Ivory Coast", code: "CI", currencyCode: "XOF", coords: .init(latitude: 7.539989, longitude: -5.54708)),
        Country(id: 108, name: "Jamaica", code: "JM", currencyCode: "JMD", coords: .init(latitude: 18.109581, longitude: -77.297508)),
        Country(id: 109, name: "Japan", code: "JP", currencyCode: "JPY", coords: .init(latitude: 36.204824, longitude: 138.252924)),
        Country(id: 110, name: "Jordan", code: "JO", currencyCode: "JOD", coords: .init(latitude: 30.585164, longitude: 36.238414)),
        Country(id: 111, name: "Kazakhstan", code: "KZ", currencyCode: "KZT", coords: .init(latitude: 48.019573, longitude: 66.923684)),
        Country(id: 112, name: "Kenya", code: "KE", currencyCode: "KES", coords: .init(latitude: -0.023559, longitude: 37.906193)),
        Country(id: 113, name: "Kiribati", code: "KI", currencyCode: "AUD", coords: .init(latitude: -3.370417, longitude: -168.734039)),
        Country(id: 114, name: "South Korea", code: "KR", currencyCode: "KRW", coords: .init(latitude: 35.9078, longitude: 127.7669)),
        Country(id: 115, name: "Kuwait", code: "KW", currencyCode: "KWD", coords: .init(latitude: 29.31166, longitude: 47.481766)),
        Country(id: 116, name: "Kyrgyzstan", code: "KG", currencyCode: "KGS", coords: .init(latitude: 41.20438, longitude: 74.766098)),
        Country(id: 117, name: "Laos", code: "LA", currencyCode: "LAK", coords: .init(latitude: 19.85627, longitude: 102.495496)),
        Country(id: 118, name: "Latvia", code: "LV", currencyCode: "EUR", coords: .init(latitude: 56.879635, longitude: 24.603189)),
        Country(id: 119, name: "Lebanon", code: "LB", currencyCode: "LBP", coords: .init(latitude: 33.854721, longitude: 35.862285)),
        Country(id: 120, name: "Lesotho", code: "LS", currencyCode: "LSL", coords: .init(latitude: -29.609988, longitude: 28.233608)),
        Country(id: 121, name: "Liberia", code: "LR", currencyCode: "LRD", coords: .init(latitude: 6.428055, longitude: -9.429499)),
        Country(id: 122, name: "Libya", code: "LY", currencyCode: "LYD", coords: .init(latitude: 26.3351, longitude: 17.228331)),
        Country(id: 123, name: "Liechtenstein", code: "LI", currencyCode: "CHF", coords: .init(latitude: 47.166, longitude: 9.555373)),
        Country(id: 124, name: "Lithuania", code: "LT", currencyCode: "EUR", coords: .init(latitude: 55.169438, longitude: 23.881275)),
        Country(id: 125, name: "Luxembourg", code: "LU", currencyCode: "EUR", coords: .init(latitude: 49.815273, longitude: 6.129583)),
        Country(id: 126, name: "Macao", code: "MO", currencyCode: "MOP", coords: .init(latitude: 22.198745, longitude: 113.543873)),
        Country(id: 127, name: "Macedonia (Skopje)", code: "MK", currencyCode: "MKD", coords: .init(latitude: 41.608635, longitude: 21.745275)),
        Country(id: 128, name: "Madagascar", code: "MG", currencyCode: "MGA", coords: .init(latitude: -18.766947, longitude: 46.869107)),
        Country(id: 129, name: "Malawi", code: "MW", currencyCode: "MWK", coords: .init(latitude: -13.254308, longitude: 34.301525)),
        Country(id: 130, name: "Malaysia", code: "MY", currencyCode: "MYR", coords: .init(latitude: 4.210484, longitude: 101.975766)),
        Country(id: 131, name: "Maldives", code: "MV", currencyCode: "MVR", coords: .init(latitude: 3.202778, longitude: 73.22068)),
        Country(id: 132, name: "Mali", code: "ML", currencyCode: "XOF", coords: .init(latitude: 17.570692, longitude: -3.996166)),
        Country(id: 133, name: "Malta", code: "MT", currencyCode: "EUR", coords: .init(latitude: 35.937496, longitude: 14.375416)),
        Country(id: 134, name: "Marshall Islands", code: "MH", currencyCode: "USD", coords: .init(latitude: 7.131474, longitude: 171.184478)),
        Country(id: 135, name: "Martinique", code: "MQ", currencyCode: "EUR", coords: .init(latitude: 14.641528, longitude: -61.024174)),
        Country(id: 136, name: "Mauritania", code: "MR", currencyCode: "MRU", coords: .init(latitude: 21.00789, longitude: -10.940835)),
        Country(id: 137, name: "Mauritius", code: "MU", currencyCode: "MUR", coords: .init(latitude: -20.348404, longitude: 57.552152)),
        Country(id: 138, name: "Mexico", code: "MX", currencyCode: "MXN", coords: .init(latitude: 23.634501, longitude: -102.552784)),
        Country(id: 139, name: "Moldova", code: "MD", currencyCode: "MDL", coords: .init(latitude: 47.411631, longitude: 28.369885)),
        Country(id: 140, name: "Monaco", code: "MC", currencyCode: "EUR", coords: .init(latitude: 43.750298, longitude: 7.412841)),
        Country(id: 141, name: "Mongolia", code: "MN", currencyCode: "MNT", coords: .init(latitude: 46.862496, longitude: 103.846656)),
        Country(id: 143, name: "Montserrat", code: "MS", currencyCode: "XCD", coords: .init(latitude: 16.742498, longitude: -62.187366)),
        Country(id: 144, name: "Morocco", code: "MA", currencyCode: "MAD", coords: .init(latitude: 31.791702, longitude: -7.09262)),
        Country(id: 145, name: "Mozambique", code: "MZ", currencyCode: "MZN", coords: .init(latitude: -18.665695, longitude: 35.529562)),
        Country(id: 146, name: "Namibia", code: "NA", currencyCode: "NAD", coords: .init(latitude: -22.95764, longitude: 18.49041)),
        Country(id: 147, name: "Nauru", code: "NR", currencyCode: "AUD", coords: .init(latitude: -0.522778, longitude: 166.931503)),
        Country(id: 148, name: "Nepal", code: "NP", currencyCode: "NPR", coords: .init(latitude: 28.394857, longitude: 84.124008)),
        Country(id: 149, name: "Netherlands", code: "NL", currencyCode: "EUR", coords: .init(latitude: 52.132633, longitude: 5.291266)),
        Country(id: 150, name: "Netherlands Antilles", code: "AN", currencyCode: "ANG", coords: .init(latitude: 12.226079, longitude: -69.060087)),
        Country(id: 151, name: "New Caledonia", code: "NC", currencyCode: "XPF", coords: .init(latitude: -20.904305, longitude: 165.618042)),
        Country(id: 152, name: "New Zealand", code: "NZ", currencyCode: "NZD", coords: .init(latitude: -40.900557, longitude: 174.885971)),
        Country(id: 153, name: "Nicaragua", code: "NI", currencyCode: "NIO", coords: .init(latitude: 12.865416, longitude: -85.207229)),
        Country(id: 154, name: "Niger", code: "NE", currencyCode: "XOF", coords: .init(latitude: 17.607789, longitude: 8.081666)),
        Country(id: 155, name: "Nigeria", code: "NG", currencyCode: "NGN", coords: .init(latitude: 9.081999, longitude: 8.675277)),
        Country(id: 156, name: "Niue", code: "NU", currencyCode: "NZD", coords: .init(latitude: -19.054445, longitude: -169.867233)),
        Country(id: 157, name: "Norfolk Island", code: "NF", currencyCode: "AUD", coords: .init(latitude: -29.040835, longitude: 167.954712)),
        Country(id: 158, name: "North Korea", code: "KP", currencyCode: "KPW", coords: .init(latitude: 40.339852, longitude: 127.510093)),
        Country(id: 159, name: "Northern Mariana Islands", code: "MP", currencyCode: "USD", coords: .init(latitude: 17.33083, longitude: 145.38469)),
        Country(id: 160, name: "Norway", code: "NO", currencyCode: "NOK", coords: .init(latitude: 60.472024, longitude: 8.468946)),
        Country(id: 161, name: "Oman", code: "OM", currencyCode: "OMR", coords: .init(latitude: 21.512583, longitude: 55.923255)),
        Country(id: 162, name: "Pakistan", code: "PK", currencyCode: "PKR", coords: .init(latitude: 30.375321, longitude: 69.345116)),
        Country(id: 163, name: "Palau", code: "PW", currencyCode: "USD", coords: .init(latitude: 7.51498, longitude: 134.58252)),
        Country(id: 164, name: "Panama", code: "PA", currencyCode: "PAB", coords: .init(latitude: 8.537981, longitude: -80.782127)),
        Country(id: 165, name: "Papua New Guinea", code: "PG", currencyCode: "PGK", coords: .init(latitude: -6.314993, longitude: 143.95555)),
        Country(id: 166, name: "Paraguay", code: "PY", currencyCode: "PYG", coords: .init(latitude: -23.442503, longitude: -58.443832)),
        Country(id: 167, name: "Peru", code: "PE", currencyCode: "PEN", coords: .init(latitude: -9.189967, longitude: -75.015152)),
        Country(id: 168, name: "Philippines", code: "PH", currencyCode: "PHP", coords: .init(latitude: 12.879721, longitude: 121.774017)),
        Country(id: 169, name: "Pitcairn Island", code: "PN", currencyCode: "NZD", coords: .init(latitude: -24.703615, longitude: -127.439308)),
        Country(id: 170, name: "Poland", code: "PL", currencyCode: "PLN", coords: .init(latitude: 51.919438, longitude: 19.145136)),
        Country(id: 171, name: "Portugal", code: "PT", currencyCode: "EUR", coords: .init(latitude: 39.399872, longitude: -8.224454)),
        Country(id: 172, name: "Puerto Rico", code: "PR", currencyCode: "USD", coords: .init(latitude: 18.220833, longitude: -66.590149)),
        Country(id: 173, name: "Qatar", code: "QA", currencyCode: "QAR", coords: .init(latitude: 25.354826, longitude: 51.183884)),
        Country(id: 174, name: "Republic of Yemen", code: "YE", currencyCode: "YER", coords: .init(latitude: 15.552727, longitude: 48.516388)),
        Country(id: 175, name: "Reunion", code: "RE", currencyCode: "EUR", coords: .init(latitude: -21.115141, longitude: 55.536384)),
        Country(id: 176, name: "Romania", code: "RO", currencyCode: "RON", coords: .init(latitude: 45.943161, longitude: 24.96676)),
        Country(id: 177, name: "Russia", code: "RU", currencyCode: "RUB", coords: .init(latitude: 61.52401, longitude: 105.318756)),
        Country(id: 178, name: "Rwanda", code: "RW", currencyCode: "RWF", coords: .init(latitude: -1.940278, longitude: 29.873888)),
        Country(id: 179, name: "San Marino", code: "SM", currencyCode: "EUR", coords: .init(latitude: 43.94236, longitude: 12.457777)),
        Country(id: 180, name: "Sao Tome and Principe", code: "ST", currencyCode: "STN", coords: .init(latitude: 0.18636, longitude: 6.613081)),
        Country(id: 181, name: "Saudi Arabia", code: "SA", currencyCode: "SAR", coords: .init(latitude: 23.885942, longitude: 45.079162)),
        Country(id: 182, name: "Senegal", code: "SN", currencyCode: "XOF", coords: .init(latitude: 14.497401, longitude: -14.452362)),
        Country(id: 183, name: "Seychelles", code: "SC", currencyCode: "SCR", coords: .init(latitude: -4.679574, longitude: 55.491977)),
        Country(id: 184, name: "Sierra Leone", code: "SL", currencyCode: "SLE", coords: .init(latitude: 8.460555, longitude: -11.779889)),
        Country(id: 185, name: "Singapore", code: "SG", currencyCode: "SGD", coords: .init(latitude: 1.352083, longitude: 103.819836)),
        Country(id: 186, name: "Slovakia", code: "SK", currencyCode: "EUR", coords: .init(latitude: 48.669026, longitude: 19.699024)),
        Country(id: 187, name: "Slovenia", code: "SI", currencyCode: "EUR", coords: .init(latitude: 46.151241, longitude: 14.995463)),
        Country(id: 188, name: "Solomon Islands", code: "SB", currencyCode: "SBD", coords: .init(latitude: -9.64571, longitude: 160.156194)),
        Country(id: 189, name: "Somalia", code: "SO", currencyCode: "SOS", coords: .init(latitude: 5.152149, longitude: 46.199616)),
        Country(id: 190, name: "South Africa", code: "ZA", currencyCode: "ZAR", coords: .init(latitude: -30.559482, longitude: 22.937506)),
        Country(id: 191, name: "Spain", code: "ES", currencyCode: "EUR", coords: .init(latitude: 40.463667, longitude: -3.74922)),
        Country(id: 192, name: "Sri Lanka", code: "LK", currencyCode: "LKR", coords: .init(latitude: 7.873054, longitude: 80.771797)),
        Country(id: 193, name: "St Helena", code: "SH", currencyCode: "SHP", coords: .init(latitude: -24.143474, longitude: -10.030696)),
        Country(id: 194, name: "St Kitts and Nevis", code: "KN", currencyCode: "XCD", coords: .init(latitude: 17.357822, longitude: -62.782998)),
        Country(id: 195, name: "St Lucia", code: "LC", currencyCode: "XCD", coords: .init(latitude: 13.909444, longitude: -60.978893)),
        Country(id: 196, name: "St Pierre and Miquelon", code: "PM", currencyCode: "EUR", coords: .init(latitude: 46.941936, longitude: -56.27111)),
        Country(id: 197, name: "St Vincent and the Grenadines", code: "VC", currencyCode: "XCD", coords: .init(latitude: 12.984305, longitude: -61.287228)),
        Country(id: 198, name: "Sudan", code: "SD", currencyCode: "SDG", coords: .init(latitude: 12.862807, longitude: 30.217636)),
        Country(id: 199, name: "Suriname", code: "SR", currencyCode: "SRD", coords: .init(latitude: 3.919305, longitude: -56.027783)),
        Country(id: 201, name: "Swaziland", code: "SZ", currencyCode: "SZL", coords: .init(latitude: -26.522503, longitude: 31.465866)),
        Country(id: 202, name: "Sweden", code: "SE", currencyCode: "SEK", coords: .init(latitude: 60.128161, longitude: 18.643501)),
        Country(id: 203, name: "Switzerland", code: "CH", currencyCode: "CHF", coords: .init(latitude: 46.818188, longitude: 8.227512)),
        Country(id: 204, name: "Syria", code: "SY", currencyCode: "SYP", coords: .init(latitude: 34.802075, longitude: 38.996815)),
        Country(id: 205, name: "Taiwan", code: "TW", currencyCode: "TWD", coords: .init(latitude: 23.69781, longitude: 120.960515)),
        Country(id: 206, name: "Tajikistan", code: "TJ", currencyCode: "TJS", coords: .init(latitude: 38.861034, longitude: 71.276093)),
        Country(id: 207, name: "Tanzania", code: "TZ", currencyCode: "TZS", coords: .init(latitude: -6.369028, longitude: 34.888822)),
        Country(id: 208, name: "Thailand", code: "TH", currencyCode: "THB", coords: .init(latitude: 15.870032, longitude: 100.992541)),
        Country(id: 209, name: "Togo", code: "TG", currencyCode: "XOF", coords: .init(latitude: 8.619543, longitude: 0.824782)),
        Country(id: 210, name: "Tokelau", code: "TK", currencyCode: "NZD", coords: .init(latitude: -8.967363, longitude: -171.855881)),
        Country(id: 211, name: "Tonga", code: "TO", currencyCode: "TOP", coords: .init(latitude: -21.178986, longitude: -175.198242)),
        Country(id: 212, name: "Trinidad and Tobago", code: "TT", currencyCode: "TTD", coords: .init(latitude: 10.691803, longitude: -61.222503)),
        Country(id: 213, name: "Tunisia", code: "TN", currencyCode: "TND", coords: .init(latitude: 33.886917, longitude: 9.537499)),
        Country(id: 214, name: "Turkey", code: "TR", currencyCode: "TRY", coords: .init(latitude: 38.963745, longitude: 35.243322)),
        Country(id: 215, name: "Turkmenistan", code: "TM", currencyCode: "TMT", coords: .init(latitude: 38.969719, longitude: 59.556278)),
        Country(id: 216, name: "Turks and Caicos Islands", code: "TC", currencyCode: "USD", coords: .init(latitude: 21.694025, longitude: -71.797928)),
        Country(id: 217, name: "Tuvalu", code: "TV", currencyCode: "AUD", coords: .init(latitude: -7.109535, longitude: 177.64933)),
        Country(id: 218, name: "Uganda", code: "UG", currencyCode: "UGX", coords: .init(latitude: 1.373333, longitude: 32.290275)),
        Country(id: 219, name: "Ukraine", code: "UA", currencyCode: "UAH", coords: .init(latitude: 48.379433, longitude: 31.16558)),
        Country(id: 221, name: "United Arab Emirates", code: "AE", currencyCode: "AED", coords: .init(latitude: 23.424076, longitude: 53.847818)),
        Country(id: 222, name: "United Kingdom", code: "GB", currencyCode: "GBP", coords: .init(latitude: 55.378051, longitude: -3.435973)),
        Country(id: 223, name: "Uruguay", code: "UY", currencyCode: "UYU", coords: .init(latitude: -32.522779, longitude: -55.765835)),
        Country(id: 224, name: "US minor outlying Islands", code: "UM", currencyCode: "USD", coords: .init(latitude: 00.000000, longitude: 00.000000)),
        Country(id: 225, name: "USA", code: "US", currencyCode: "USD", coords: .init(latitude: 37.09024, longitude: -95.712891)),
        Country(id: 226, name: "Uzbekistan", code: "UZ", currencyCode: "UZS", coords: .init(latitude: 41.377491, longitude: 64.585262)),
        Country(id: 227, name: "Vanuatu", code: "VU", currencyCode: "VUV", coords: .init(latitude: -15.376706, longitude: 166.959158)),
        Country(id: 228, name: "Vatican City", code: "VA", currencyCode: "EUR", coords: .init(latitude: 41.902916, longitude: 12.453389)),
        Country(id: 229, name: "Venezuela", code: "VE", currencyCode: "VES", coords: .init(latitude: 6.42375, longitude: -66.58973)),
        Country(id: 230, name: "Vietnam", code: "VN", currencyCode: "VND", coords: .init(latitude: 14.058324, longitude: 108.277199)),
        Country(id: 231, name: "Virgin Islands of the United States", code: "VI", currencyCode: "USD", coords: .init(latitude: 18.335765, longitude: -64.896335)),
        Country(id: 232, name: "Wallis and Futuna", code: "WF", currencyCode: "XPF", coords: .init(latitude: -13.768752, longitude: -177.156097)),
        Country(id: 234, name: "Western Sahara", code: "EH", currencyCode: "MAD", coords: .init(latitude: 24.215527, longitude: -12.885834)),
        Country(id: 235, name: "Western Samoa", code: "WS", currencyCode: "WST", coords: .init(latitude: -13.759029, longitude: -172.104629)),
        Country(id: 237, name: "Zambia", code: "ZM", currencyCode: "ZMW", coords: .init(latitude: -13.133897, longitude: 27.849332)),
        Country(id: 238, name: "Zimbabwe", code: "ZW", currencyCode: "ZWG", coords: .init(latitude: -19.015438, longitude: 29.154857))
    ]
            
    static var homeCountry: Country {
        let localId = AppState.shared.country.code
        return Self.list.first(where: { $0.code == localId }) ?? Self.list.first(where: { $0.code == "US" })!
    }
    
    static func fetch(by id: Int?) -> Country? {
        guard let id else { return nil }
        return Self.list.first(where: { $0.id == id })
    }
    
    static func fetch(by code: String?) -> Country? {
        guard let code else { return nil }
        return Self.list.first(where: { $0.code == code })
    }
    
//    static func convert(amount: Decimal, from: Country, to: Country) -> Decimal? {
//        guard let fromRate = from.exchangeRate, let toRate = to.exchangeRate else {
//            print("Exchange rate not available")
//            return nil
//        }
//        /// Convert source currency to USD
//        let usd = amount / fromRate
//        /// Convert USD to destination currency
//        return usd * toRate
//    }
//    
//    static func convert(amount: Decimal, from: Country, using exchangeRate: Decimal) -> Decimal? {
//        guard let fromRate = from.exchangeRate else {
//            print("Exchange rate not available")
//            return nil
//        }
//        
//        print("Converting \(amount) \(from.name) to local currency with exchange rate \(exchangeRate)")
//        
//        /// Convert source currency to USD
//        let usd = amount / fromRate
//        /// Convert USD to destination currency
//        return usd * exchangeRate
//    }
//    
//    
//    @MainActor
//    static func handleIncoming(currencies: Array<CountryCurrencyDecodable>, incomingDataType: IncomingDataType) {
//        for cur in currencies {
//            if cur.id == AppState.shared.country.id {
//                AppState.shared.country.exchangeRate = cur.exchangeRate
//                AppState.shared.country.rateValidityDate = cur.rateValidityDate
//            }
//            
//            if let index = Self.list.firstIndex(where: { $0.id == cur.id }) {
//                Self.list[index].exchangeRate = cur.exchangeRate
//                Self.list[index].rateValidityDate = cur.rateValidityDate
//            }
//        }
//    }
}
