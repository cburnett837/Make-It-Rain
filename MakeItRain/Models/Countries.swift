//
//  Countries.swift
//  MakeItRain
//
//  Created by Cody Burnett on 5/27/26.
//

import Foundation
import MapKit

struct Country: Hashable {
    var id: String
    var countryName: String
    var countryCode: String
    let currencyCode: String
    var coords: CLLocationCoordinate2D
    var exchangeRate: Double?
    
    var idInt: Int { Int(id) ?? 0 }
    var idDouble: Double { Double(id) ?? 0.0 }
    var countryNameUpper: String { countryName.uppercased() }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



struct Countries {
    static var countriesArray: [Country] = [
        Country(id: "634", countryName: "USA", countryCode: "US", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 37.09024, longitude: -95.712891)),
        Country(id: "467", countryName: "Germany", countryCode: "DE", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 51.165691, longitude: 10.451526)),
        Country(id: "523", countryName: "Afghanistan", countryCode: "AF", currencyCode: "AFN", coords: CLLocationCoordinate2D(latitude: 33.93911, longitude: 67.709953)),
        Country(id: "502", countryName: "Albania", countryCode: "AL", currencyCode: "ALL", coords: CLLocationCoordinate2D(latitude: 41.153332, longitude: 20.168331)),
        Country(id: "575", countryName: "Algeria", countryCode: "DZ", currencyCode: "DZD", coords: CLLocationCoordinate2D(latitude: 28.033886, longitude: 1.659626)),
        Country(id: "638", countryName: "American Samoa", countryCode: "AS", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: -14.270972, longitude: -170.132217)),
        Country(id: "464", countryName: "Andorra", countryCode: "AD", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 42.546245, longitude: 1.601554)),
        Country(id: "600", countryName: "Angola", countryCode: "AO", currencyCode: "AOA", coords: CLLocationCoordinate2D(latitude: -11.202692, longitude: 17.873887)),
        Country(id: "423", countryName: "Anguilla", countryCode: "AI", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 18.220554, longitude: -63.068615)),
        Country(id: "426", countryName: "Antigua and Barbuda", countryCode: "AG", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 17.060816, longitude: -61.796428)),
        Country(id: "450", countryName: "Argentina", countryCode: "AR", currencyCode: "ARS", coords: CLLocationCoordinate2D(latitude: -38.416097, longitude: -63.616672)),
        Country(id: "481", countryName: "Armenia", countryCode: "AM", currencyCode: "AMD", coords: CLLocationCoordinate2D(latitude: 40.069099, longitude: 45.038189)),
        Country(id: "435", countryName: "Aruba", countryCode: "AW", currencyCode: "AWG", coords: CLLocationCoordinate2D(latitude: 12.52111, longitude: -69.968338)),
        Country(id: "549", countryName: "Australia", countryCode: "AU", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -25.274398, longitude: 133.775136)),
        Country(id: "468", countryName: "Austria", countryCode: "AT", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 47.516231, longitude: 14.550072)),
        Country(id: "482", countryName: "Azerbaijan", countryCode: "AZ", currencyCode: "AZN", coords: CLLocationCoordinate2D(latitude: 40.143105, longitude: 47.576927)),
        Country(id: "416", countryName: "Bahamas", countryCode: "BS", currencyCode: "BSD", coords: CLLocationCoordinate2D(latitude: 25.03428, longitude: -77.39628)),
        Country(id: "522", countryName: "Bahrain", countryCode: "BH", currencyCode: "BHD", coords: CLLocationCoordinate2D(latitude: 25.930414, longitude: 50.637772)),
        Country(id: "527", countryName: "Bangladesh", countryCode: "BD", currencyCode: "BDT", coords: CLLocationCoordinate2D(latitude: 23.684994, longitude: 90.356331)),
        Country(id: "432", countryName: "Barbados", countryCode: "BB", currencyCode: "BBD", coords: CLLocationCoordinate2D(latitude: 13.193887, longitude: -59.543198)),
        Country(id: "479", countryName: "Belarus", countryCode: "BY", currencyCode: "BYN", coords: CLLocationCoordinate2D(latitude: 53.709807, longitude: 27.953389)),
        Country(id: "462", countryName: "Belgium", countryCode: "BE", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 50.503887, longitude: 4.469936)),
        Country(id: "409", countryName: "Belize", countryCode: "BZ", currencyCode: "BZD", coords: CLLocationCoordinate2D(latitude: 17.189877, longitude: -88.49765)),
        Country(id: "599", countryName: "Benin", countryCode: "BJ", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 9.30769, longitude: 2.315834)),
        Country(id: "415", countryName: "Bermuda", countryCode: "BM", currencyCode: "BMD", coords: CLLocationCoordinate2D(latitude: 32.321384, longitude: -64.75737)),
        Country(id: "540", countryName: "Bhutan", countryCode: "BT", currencyCode: "BTN", coords: CLLocationCoordinate2D(latitude: 27.514162, longitude: 90.433601)),
        Country(id: "445", countryName: "Bolivia", countryCode: "BO", currencyCode: "BOB", coords: CLLocationCoordinate2D(latitude: -16.290154, longitude: -63.588653)),
        Country(id: "499", countryName: "Bosnia-Herzegovina", countryCode: "BA", currencyCode: "BAM", coords: CLLocationCoordinate2D(latitude: 43.915886, longitude: 17.679076)),
        Country(id: "626", countryName: "Botswana", countryCode: "BW", currencyCode: "BWP", coords: CLLocationCoordinate2D(latitude: -22.328474, longitude: 24.684866)),
        Country(id: "447", countryName: "Brazil", countryCode: "BR", currencyCode: "BRL", coords: CLLocationCoordinate2D(latitude: -14.235004, longitude: -51.92528)),
        Country(id: "616", countryName: "British Indian Ocean Terr", countryCode: "IO", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: -6.343194, longitude: 71.876519)),
        Country(id: "424", countryName: "British Virgin Islands", countryCode: "VG", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 18.420695, longitude: -64.639968)),
        Country(id: "537", countryName: "Brunei", countryCode: "BN", currencyCode: "BND", coords: CLLocationCoordinate2D(latitude: 4.535277, longitude: 114.727669)),
        Country(id: "505", countryName: "Bulgaria", countryCode: "BG", currencyCode: "BGN", coords: CLLocationCoordinate2D(latitude: 42.733883, longitude: 25.48583)),
        Country(id: "598", countryName: "Burkina", countryCode: "BF", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 12.238333, longitude: -1.561593)),
        Country(id: "607", countryName: "Burundi", countryCode: "BI", currencyCode: "BIF", coords: CLLocationCoordinate2D(latitude: -3.373056, longitude: 29.918886)),
        Country(id: "533", countryName: "Cambodia", countryCode: "KH", currencyCode: "KHR", coords: CLLocationCoordinate2D(latitude: 12.565679, longitude: 104.990963)),
        Country(id: "583", countryName: "Cameroon", countryCode: "CM", currencyCode: "XAF", coords: CLLocationCoordinate2D(latitude: 7.369722, longitude: 12.354722)),
        Country(id: "405", countryName: "Canada", countryCode: "CA", currencyCode: "CAD", coords: CLLocationCoordinate2D(latitude: 56.130366, longitude: -106.346771)),
        Country(id: "603", countryName: "Cape Verde", countryCode: "CV", currencyCode: "CVE", coords: CLLocationCoordinate2D(latitude: 16.002082, longitude: -24.013197)),
        Country(id: "420", countryName: "Cayman Islands", countryCode: "KY", currencyCode: "KYD", coords: CLLocationCoordinate2D(latitude: 19.513469, longitude: -80.566956)),
        Country(id: "594", countryName: "Central African Republic", countryCode: "CF", currencyCode: "XAF", coords: CLLocationCoordinate2D(latitude: 6.611111, longitude: 20.939444)),
        Country(id: "596", countryName: "Chad", countryCode: "TD", currencyCode: "XAF", coords: CLLocationCoordinate2D(latitude: 15.454166, longitude: 18.732207)),
        Country(id: "446", countryName: "Chile", countryCode: "CL", currencyCode: "CLP", coords: CLLocationCoordinate2D(latitude: -35.675147, longitude: -71.542969)),
        Country(id: "542", countryName: "China", countryCode: "CN", currencyCode: "CNY", coords: CLLocationCoordinate2D(latitude: 35.86166, longitude: 104.195397)),
        Country(id: "552", countryName: "Christmas Island", countryCode: "CX", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -10.447525, longitude: 105.690449)),
        Country(id: "551", countryName: "Cocos (Keeling) Island", countryCode: "CC", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -12.164165, longitude: 96.870956)),
        Country(id: "438", countryName: "Colombia", countryCode: "CO", currencyCode: "COP", coords: CLLocationCoordinate2D(latitude: 4.570868, longitude: -74.297333)),
        Country(id: "621", countryName: "Comoros", countryCode: "KM", currencyCode: "KMF", coords: CLLocationCoordinate2D(latitude: -11.875001, longitude: 43.872219)),
        Country(id: "601", countryName: "Congo (Brazzaville)", countryCode: "CG", currencyCode: "XAF", coords: CLLocationCoordinate2D(latitude: -0.228021, longitude: 15.827659)),
        Country(id: "606", countryName: "Congo (Kinshasa)", countryCode: "CD", currencyCode: "CDF", coords: CLLocationCoordinate2D(latitude: -4.038333, longitude: 21.758664)),
        Country(id: "556", countryName: "Cook Islands", countryCode: "CK", currencyCode: "NZD", coords: CLLocationCoordinate2D(latitude: -21.236736, longitude: -159.777671)),
        Country(id: "413", countryName: "Costa Rica", countryCode: "CR", currencyCode: "CRC", coords: CLLocationCoordinate2D(latitude: 9.748917, longitude: -83.753428)),
        Country(id: "497", countryName: "Croatia", countryCode: "HR", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 45.1, longitude: 15.2)),
        Country(id: "417", countryName: "Cuba", countryCode: "CU", currencyCode: "CUP", coords: CLLocationCoordinate2D(latitude: 21.521757, longitude: -77.781167)),
        Country(id: "507", countryName: "Cyprus", countryCode: "CY", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 35.126413, longitude: 33.429859)),
        Country(id: "469", countryName: "Czech Republic", countryCode: "CZ", currencyCode: "CZK", coords: CLLocationCoordinate2D(latitude: 49.817492, longitude: 15.472962)),
        Country(id: "458", countryName: "Denmark", countryCode: "DK", currencyCode: "DKK", coords: CLLocationCoordinate2D(latitude: 56.26392, longitude: 9.501785)),
        Country(id: "612", countryName: "Djibouti", countryCode: "DJ", currencyCode: "DJF", coords: CLLocationCoordinate2D(latitude: 11.825138, longitude: 42.590275)),
        Country(id: "428", countryName: "Dominica", countryCode: "DM", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 15.414999, longitude: -61.370976)),
        Country(id: "422", countryName: "Dominican Republic", countryCode: "DO", currencyCode: "DOP", coords: CLLocationCoordinate2D(latitude: 18.735693, longitude: -70.162651)),
        Country(id: "443", countryName: "Ecuador", countryCode: "EC", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: -1.831239, longitude: -78.183406)),
        Country(id: "578", countryName: "Egypt", countryCode: "EG", currencyCode: "EGP", coords: CLLocationCoordinate2D(latitude: 26.820553, longitude: 30.802498)),
        Country(id: "410", countryName: "El Salvador", countryCode: "SV", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 13.794185, longitude: -88.89653)),
        Country(id: "581", countryName: "Equatorial Guinea", countryCode: "GQ", currencyCode: "XAF", coords: CLLocationCoordinate2D(latitude: 1.650801, longitude: 10.267895)),
        Country(id: "610", countryName: "Eritrea", countryCode: "ER", currencyCode: "ERN", coords: CLLocationCoordinate2D(latitude: 15.179384, longitude: 39.782334)),
        Country(id: "474", countryName: "Estonia", countryCode: "EE", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 58.595272, longitude: 25.013607)),
        Country(id: "611", countryName: "Ethiopia", countryCode: "ET", currencyCode: "ETB", coords: CLLocationCoordinate2D(latitude: 9.145, longitude: 40.489673)),
        Country(id: "451", countryName: "Falkland Islands", countryCode: "FK", currencyCode: "FKP", coords: CLLocationCoordinate2D(latitude: -51.796253, longitude: -59.523613)),
        Country(id: "457", countryName: "Faroe Islands", countryCode: "FO", currencyCode: "DKK", coords: CLLocationCoordinate2D(latitude: 61.892635, longitude: -6.911806)),
        Country(id: "569", countryName: "Fedrated States of Micronesia", countryCode: "FM", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 7.425554, longitude: 150.550812)),
        Country(id: "572", countryName: "Fiji", countryCode: "FJ", currencyCode: "FJD", coords: CLLocationCoordinate2D(latitude: -16.578193, longitude: 179.414413)),
        Country(id: "456", countryName: "Finland", countryCode: "FI", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 61.92411, longitude: 25.748151)),
        Country(id: "466", countryName: "France", countryCode: "FR", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 46.227638, longitude: 2.213749)),
        Country(id: "442", countryName: "French Guiana", countryCode: "GF", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 3.933889, longitude: -53.125782)),
        Country(id: "567", countryName: "French Polynesia", countryCode: "PF", currencyCode: "XPF", coords: CLLocationCoordinate2D(latitude: -17.679742, longitude: -149.406843)),
        Country(id: "623", countryName: "French Southern and Antarctic Lands", countryCode: "TF", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: -49.280366, longitude: 69.348557)),
        Country(id: "595", countryName: "Gabon", countryCode: "GA", currencyCode: "XAF", coords: CLLocationCoordinate2D(latitude: -0.803689, longitude: 11.609444)),
        Country(id: "590", countryName: "Gambia", countryCode: "GM", currencyCode: "GMD", coords: CLLocationCoordinate2D(latitude: 13.443182, longitude: -15.310139)),
        Country(id: "513", countryName: "Gaza Strip Administered by Israel", countryCode: "GZ", currencyCode: "ILS", coords: CLLocationCoordinate2D(latitude: 31.354676, longitude: 34.308825)),
        Country(id: "483", countryName: "Georgia", countryCode: "GE", currencyCode: "GEL", coords: CLLocationCoordinate2D(latitude: 42.315407, longitude: 43.356892)),
        Country(id: "589", countryName: "Ghana", countryCode: "GH", currencyCode: "GHS", coords: CLLocationCoordinate2D(latitude: 7.946527, longitude: -1.023194)),
        Country(id: "492", countryName: "Gibraltar", countryCode: "GI", currencyCode: "GIP", coords: CLLocationCoordinate2D(latitude: 36.137741, longitude: -5.345374)),
        Country(id: "503", countryName: "Greece", countryCode: "GR", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 39.074208, longitude: 21.824312)),
        Country(id: "404", countryName: "Greenland", countryCode: "GL", currencyCode: "DKK", coords: CLLocationCoordinate2D(latitude: 71.706936, longitude: -42.604303)),
        Country(id: "431", countryName: "Grenada", countryCode: "GD", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 12.262776, longitude: -61.604171)),
        Country(id: "436", countryName: "Guadeloupe", countryCode: "GP", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 16.995971, longitude: -62.067641)),
        Country(id: "637", countryName: "Guam", countryCode: "GU", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 13.444304, longitude: 144.793731)),
        Country(id: "408", countryName: "Guatemala", countryCode: "GT", currencyCode: "GTQ", coords: CLLocationCoordinate2D(latitude: 15.783471, longitude: -90.230759)),
        Country(id: "586", countryName: "Guinea", countryCode: "GN", currencyCode: "GNF", coords: CLLocationCoordinate2D(latitude: 9.945587, longitude: -9.696645)),
        Country(id: "602", countryName: "Guinea-Bissau", countryCode: "GW", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 11.803749, longitude: -15.180413)),
        Country(id: "440", countryName: "Guyana", countryCode: "GY", currencyCode: "GYD", coords: CLLocationCoordinate2D(latitude: 4.860416, longitude: -58.93018)),
        Country(id: "421", countryName: "Haiti", countryCode: "HT", currencyCode: "HTG", coords: CLLocationCoordinate2D(latitude: 18.971187, longitude: -72.285215)),
        Country(id: "553", countryName: "Heard and McDonald Islands", countryCode: "HM", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -53.08181, longitude: 73.504158)),
        Country(id: "411", countryName: "Honduras", countryCode: "HN", currencyCode: "HNL", coords: CLLocationCoordinate2D(latitude: 15.199999, longitude: -86.241905)),
        Country(id: "546", countryName: "Hong Kong", countryCode: "HK", currencyCode: "HKD", coords: CLLocationCoordinate2D(latitude: 22.396428, longitude: 114.109497)),
        Country(id: "471", countryName: "Hungary", countryCode: "HU", currencyCode: "HUF", coords: CLLocationCoordinate2D(latitude: 47.162494, longitude: 19.503304)),
        Country(id: "452", countryName: "Iceland", countryCode: "IS", currencyCode: "ISK", coords: CLLocationCoordinate2D(latitude: 64.963051, longitude: -19.020835)),
        Country(id: "524", countryName: "India", countryCode: "IN", currencyCode: "INR", coords: CLLocationCoordinate2D(latitude: 20.593684, longitude: 78.96288)),
        Country(id: "536", countryName: "Indonesia", countryCode: "ID", currencyCode: "IDR", coords: CLLocationCoordinate2D(latitude: -0.789275, longitude: 113.921327)),
        Country(id: "511", countryName: "Iran", countryCode: "IR", currencyCode: "IRR", coords: CLLocationCoordinate2D(latitude: 32.427908, longitude: 53.688046)),
        Country(id: "510", countryName: "Iraq", countryCode: "IQ", currencyCode: "IQD", coords: CLLocationCoordinate2D(latitude: 33.223191, longitude: 43.679291)),
        Country(id: "460", countryName: "Ireland", countryCode: "IE", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 53.41291, longitude: -8.24389)),
        Country(id: "512", countryName: "Israel", countryCode: "IL", currencyCode: "ILS", coords: CLLocationCoordinate2D(latitude: 31.046051, longitude: 34.851612)),
        Country(id: "496", countryName: "Italy", countryCode: "IT", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 41.87194, longitude: 12.56738)),
        Country(id: "588", countryName: "Ivory Coast", countryCode: "CI", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 7.539989, longitude: -5.54708)),
        Country(id: "418", countryName: "Jamaica", countryCode: "JM", currencyCode: "JMD", coords: CLLocationCoordinate2D(latitude: 18.109581, longitude: -77.297508)),
        Country(id: "548", countryName: "Japan", countryCode: "JP", currencyCode: "JPY", coords: CLLocationCoordinate2D(latitude: 36.204824, longitude: 138.252924)),
        Country(id: "515", countryName: "Jordan", countryCode: "JO", currencyCode: "JOD", coords: CLLocationCoordinate2D(latitude: 30.585164, longitude: 36.238414)),
        Country(id: "484", countryName: "Kazakhstan", countryCode: "KZ", currencyCode: "KZT", coords: CLLocationCoordinate2D(latitude: 48.019573, longitude: 66.923684)),
        Country(id: "614", countryName: "Kenya", countryCode: "KE", currencyCode: "KES", coords: CLLocationCoordinate2D(latitude: -0.023559, longitude: 37.906193)),
        Country(id: "563", countryName: "Kiribati", countryCode: "KI", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -3.370417, longitude: -168.734039)),
        Country(id: "545", countryName: "South Korea", countryCode: "KR", currencyCode: "KRW", coords: CLLocationCoordinate2D(latitude: 35.9078, longitude: 127.7669)),
        Country(id: "516", countryName: "Kuwait", countryCode: "KW", currencyCode: "KWD", coords: CLLocationCoordinate2D(latitude: 29.31166, longitude: 47.481766)),
        Country(id: "485", countryName: "Kyrgyzstan", countryCode: "KG", currencyCode: "KGS", coords: CLLocationCoordinate2D(latitude: 41.20438, longitude: 74.766098)),
        Country(id: "532", countryName: "Laos", countryCode: "LA", currencyCode: "LAK", coords: CLLocationCoordinate2D(latitude: 19.85627, longitude: 102.495496)),
        Country(id: "475", countryName: "Latvia", countryCode: "LV", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 56.879635, longitude: 24.603189)),
        Country(id: "509", countryName: "Lebanon", countryCode: "LB", currencyCode: "LBP", coords: CLLocationCoordinate2D(latitude: 33.854721, longitude: 35.862285)),
        Country(id: "631", countryName: "Lesotho", countryCode: "LS", currencyCode: "LSL", coords: CLLocationCoordinate2D(latitude: -29.609988, longitude: 28.233608)),
        Country(id: "605", countryName: "Liberia", countryCode: "LR", currencyCode: "LRD", coords: CLLocationCoordinate2D(latitude: 6.428055, longitude: -9.429499)),
        Country(id: "577", countryName: "Libya", countryCode: "LY", currencyCode: "LYD", coords: CLLocationCoordinate2D(latitude: 26.3351, longitude: 17.228331)),
        Country(id: "472", countryName: "Liechtenstein", countryCode: "LI", currencyCode: "CHF", coords: CLLocationCoordinate2D(latitude: 47.166, longitude: 9.555373)),
        Country(id: "476", countryName: "Lithuania", countryCode: "LT", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 55.169438, longitude: 23.881275)),
        Country(id: "463", countryName: "Luxembourg", countryCode: "LU", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 49.815273, longitude: 6.129583)),
        Country(id: "539", countryName: "Macao", countryCode: "MO", currencyCode: "MOP", coords: CLLocationCoordinate2D(latitude: 22.198745, longitude: 113.543873)),
        Country(id: "500", countryName: "Macedonia (Skopje)", countryCode: "MK", currencyCode: "MKD", coords: CLLocationCoordinate2D(latitude: 41.608635, longitude: 21.745275)),
        Country(id: "620", countryName: "Madagascar", countryCode: "MG", currencyCode: "MGA", coords: CLLocationCoordinate2D(latitude: -18.766947, longitude: 46.869107)),
        Country(id: "630", countryName: "Malawi", countryCode: "MW", currencyCode: "MWK", coords: CLLocationCoordinate2D(latitude: -13.254308, longitude: 34.301525)),
        Country(id: "534", countryName: "Malaysia", countryCode: "MY", currencyCode: "MYR", coords: CLLocationCoordinate2D(latitude: 4.210484, longitude: 101.975766)),
        Country(id: "541", countryName: "Maldives", countryCode: "MV", currencyCode: "MVR", coords: CLLocationCoordinate2D(latitude: 3.202778, longitude: 73.22068)),
        Country(id: "585", countryName: "Mali", countryCode: "ML", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 17.570692, longitude: -3.996166)),
        Country(id: "493", countryName: "Malta", countryCode: "MT", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 35.937496, longitude: 14.375416)),
        Country(id: "568", countryName: "Marshall Islands", countryCode: "MH", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 7.131474, longitude: 171.184478)),
        Country(id: "437", countryName: "Martinique", countryCode: "MQ", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 14.641528, longitude: -61.024174)),
        Country(id: "582", countryName: "Mauritania", countryCode: "MR", currencyCode: "MRU", coords: CLLocationCoordinate2D(latitude: 21.00789, longitude: -10.940835)),
        Country(id: "618", countryName: "Mauritius", countryCode: "MU", currencyCode: "MUR", coords: CLLocationCoordinate2D(latitude: -20.348404, longitude: 57.552152)),
        Country(id: "407", countryName: "Mexico", countryCode: "MX", currencyCode: "MXN", coords: CLLocationCoordinate2D(latitude: 23.634501, longitude: -102.552784)),
        Country(id: "486", countryName: "Moldova", countryCode: "MD", currencyCode: "MDL", coords: CLLocationCoordinate2D(latitude: 47.411631, longitude: 28.369885)),
        Country(id: "465", countryName: "Monaco", countryCode: "MC", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 43.750298, longitude: 7.412841)),
        Country(id: "543", countryName: "Mongolia", countryCode: "MN", currencyCode: "MNT", coords: CLLocationCoordinate2D(latitude: 46.862496, longitude: 103.846656)),
        Country(id: "427", countryName: "Montserrat", countryCode: "MS", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 16.742498, longitude: -62.187366)),
        Country(id: "574", countryName: "Morocco", countryCode: "MA", currencyCode: "MAD", coords: CLLocationCoordinate2D(latitude: 31.791702, longitude: -7.09262)),
        Country(id: "619", countryName: "Mozambique", countryCode: "MZ", currencyCode: "MZN", coords: CLLocationCoordinate2D(latitude: -18.665695, longitude: 35.529562)),
        Country(id: "625", countryName: "Namibia", countryCode: "NA", currencyCode: "NAD", coords: CLLocationCoordinate2D(latitude: -22.95764, longitude: 18.49041)),
        Country(id: "571", countryName: "Nauru", countryCode: "NR", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -0.522778, longitude: 166.931503)),
        Country(id: "526", countryName: "Nepal", countryCode: "NP", currencyCode: "NPR", coords: CLLocationCoordinate2D(latitude: 28.394857, longitude: 84.124008)),
        Country(id: "461", countryName: "Netherlands", countryCode: "NL", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 52.132633, longitude: 5.291266)),
        Country(id: "434", countryName: "Netherlands Antilles", countryCode: "AN", currencyCode: "ANG", coords: CLLocationCoordinate2D(latitude: 12.226079, longitude: -69.060087)),
        Country(id: "565", countryName: "New Caledonia", countryCode: "NC", currencyCode: "XPF", coords: CLLocationCoordinate2D(latitude: -20.904305, longitude: 165.618042)),
        Country(id: "555", countryName: "New Zealand", countryCode: "NZ", currencyCode: "NZD", coords: CLLocationCoordinate2D(latitude: -40.900557, longitude: 174.885971)),
        Country(id: "412", countryName: "Nicaragua", countryCode: "NI", currencyCode: "NIO", coords: CLLocationCoordinate2D(latitude: 12.865416, longitude: -85.207229)),
        Country(id: "591", countryName: "Niger", countryCode: "NE", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 17.607789, longitude: 8.081666)),
        Country(id: "593", countryName: "Nigeria", countryCode: "NG", currencyCode: "NGN", coords: CLLocationCoordinate2D(latitude: 9.081999, longitude: 8.675277)),
        Country(id: "558", countryName: "Niue", countryCode: "NU", currencyCode: "NZD", coords: CLLocationCoordinate2D(latitude: -19.054445, longitude: -169.867233)),
        Country(id: "550", countryName: "Norfolk Island", countryCode: "NF", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -29.040835, longitude: 167.954712)),
        Country(id: "544", countryName: "North Korea", countryCode: "KP", currencyCode: "KPW", coords: CLLocationCoordinate2D(latitude: 40.339852, longitude: 127.510093)),
        Country(id: "639", countryName: "Northern Mariana Islands", countryCode: "MP", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 17.33083, longitude: 145.38469)),
        Country(id: "455", countryName: "Norway", countryCode: "NO", currencyCode: "NOK", coords: CLLocationCoordinate2D(latitude: 60.472024, longitude: 8.468946)),
        Country(id: "521", countryName: "Oman", countryCode: "OM", currencyCode: "OMR", coords: CLLocationCoordinate2D(latitude: 21.512583, longitude: 55.923255)),
        Country(id: "525", countryName: "Pakistan", countryCode: "PK", currencyCode: "PKR", coords: CLLocationCoordinate2D(latitude: 30.375321, longitude: 69.345116)),
        Country(id: "570", countryName: "Palau", countryCode: "PW", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 7.51498, longitude: 134.58252)),
        Country(id: "414", countryName: "Panama", countryCode: "PA", currencyCode: "PAB", coords: CLLocationCoordinate2D(latitude: 8.537981, longitude: -80.782127)),
        Country(id: "554", countryName: "Papua New Guinea", countryCode: "PG", currencyCode: "PGK", coords: CLLocationCoordinate2D(latitude: -6.314993, longitude: 143.95555)),
        Country(id: "448", countryName: "Paraguay", countryCode: "PY", currencyCode: "PYG", coords: CLLocationCoordinate2D(latitude: -23.442503, longitude: -58.443832)),
        Country(id: "444", countryName: "Peru", countryCode: "PE", currencyCode: "PEN", coords: CLLocationCoordinate2D(latitude: -9.189967, longitude: -75.015152)),
        Country(id: "538", countryName: "Philippines", countryCode: "PH", currencyCode: "PHP", coords: CLLocationCoordinate2D(latitude: 12.879721, longitude: 121.774017)),
        Country(id: "562", countryName: "Pitcairn Island", countryCode: "PN", currencyCode: "NZD", coords: CLLocationCoordinate2D(latitude: -24.703615, longitude: -127.439308)),
        Country(id: "477", countryName: "Poland", countryCode: "PL", currencyCode: "PLN", coords: CLLocationCoordinate2D(latitude: 51.919438, longitude: 19.145136)),
        Country(id: "491", countryName: "Portugal", countryCode: "PT", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 39.399872, longitude: -8.224454)),
        Country(id: "635", countryName: "Puerto Rico", countryCode: "PR", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 18.220833, longitude: -66.590149)),
        Country(id: "518", countryName: "Qatar", countryCode: "QA", currencyCode: "QAR", coords: CLLocationCoordinate2D(latitude: 25.354826, longitude: 51.183884)),
        Country(id: "520", countryName: "Republic of Yemen", countryCode: "YE", currencyCode: "YER", coords: CLLocationCoordinate2D(latitude: 15.552727, longitude: 48.516388)),
        Country(id: "622", countryName: "Reunion", countryCode: "RE", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: -21.115141, longitude: 55.536384)),
        Country(id: "504", countryName: "Romania", countryCode: "RO", currencyCode: "RON", coords: CLLocationCoordinate2D(latitude: 45.943161, longitude: 24.96676)),
        Country(id: "478", countryName: "Russia", countryCode: "RU", currencyCode: "RUB", coords: CLLocationCoordinate2D(latitude: 61.52401, longitude: 105.318756)),
        Country(id: "608", countryName: "Rwanda", countryCode: "RW", currencyCode: "RWF", coords: CLLocationCoordinate2D(latitude: -1.940278, longitude: 29.873888)),
        Country(id: "494", countryName: "San Marino", countryCode: "SM", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 43.94236, longitude: 12.457777)),
        Country(id: "604", countryName: "Sao Tome and Principe", countryCode: "ST", currencyCode: "STN", coords: CLLocationCoordinate2D(latitude: 0.18636, longitude: 6.613081)),
        Country(id: "517", countryName: "Saudi Arabia", countryCode: "SA", currencyCode: "SAR", coords: CLLocationCoordinate2D(latitude: 23.885942, longitude: 45.079162)),
        Country(id: "584", countryName: "Senegal", countryCode: "SN", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 14.497401, longitude: -14.452362)),
        Country(id: "615", countryName: "Seychelles", countryCode: "SC", currencyCode: "SCR", coords: CLLocationCoordinate2D(latitude: -4.679574, longitude: 55.491977)),
        Country(id: "587", countryName: "Sierra Leone", countryCode: "SL", currencyCode: "SLE", coords: CLLocationCoordinate2D(latitude: 8.460555, longitude: -11.779889)),
        Country(id: "535", countryName: "Singapore", countryCode: "SG", currencyCode: "SGD", coords: CLLocationCoordinate2D(latitude: 1.352083, longitude: 103.819836)),
        Country(id: "470", countryName: "Slovakia", countryCode: "SK", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 48.669026, longitude: 19.699024)),
        Country(id: "498", countryName: "Slovenia", countryCode: "SI", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 46.151241, longitude: 14.995463)),
        Country(id: "560", countryName: "Solomon Islands", countryCode: "SB", currencyCode: "SBD", coords: CLLocationCoordinate2D(latitude: -9.64571, longitude: 160.156194)),
        Country(id: "609", countryName: "Somalia", countryCode: "SO", currencyCode: "SOS", coords: CLLocationCoordinate2D(latitude: 5.152149, longitude: 46.199616)),
        Country(id: "624", countryName: "South Africa", countryCode: "ZA", currencyCode: "ZAR", coords: CLLocationCoordinate2D(latitude: -30.559482, longitude: 22.937506)),
        Country(id: "490", countryName: "Spain", countryCode: "ES", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 40.463667, longitude: -3.74922)),
        Country(id: "528", countryName: "Sri Lanka", countryCode: "LK", currencyCode: "LKR", coords: CLLocationCoordinate2D(latitude: 7.873054, longitude: 80.771797)),
        Country(id: "597", countryName: "St Helena", countryCode: "SH", currencyCode: "SHP", coords: CLLocationCoordinate2D(latitude: -24.143474, longitude: -10.030696)),
        Country(id: "425", countryName: "St Kitts and Nevis", countryCode: "KN", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 17.357822, longitude: -62.782998)),
        Country(id: "429", countryName: "St Lucia", countryCode: "LC", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 13.909444, longitude: -60.978893)),
        Country(id: "406", countryName: "St Pierre and Miquelon", countryCode: "PM", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 46.941936, longitude: -56.27111)),
        Country(id: "430", countryName: "St Vincent and the Grenadines", countryCode: "VC", currencyCode: "XCD", coords: CLLocationCoordinate2D(latitude: 12.984305, longitude: -61.287228)),
        Country(id: "579", countryName: "Sudan", countryCode: "SD", currencyCode: "SDG", coords: CLLocationCoordinate2D(latitude: 12.862807, longitude: 30.217636)),
        Country(id: "441", countryName: "Suriname", countryCode: "SR", currencyCode: "SRD", coords: CLLocationCoordinate2D(latitude: 3.919305, longitude: -56.027783)),
        Country(id: "628", countryName: "Swaziland", countryCode: "SZ", currencyCode: "SZL", coords: CLLocationCoordinate2D(latitude: -26.522503, longitude: 31.465866)),
        Country(id: "453", countryName: "Sweden", countryCode: "SE", currencyCode: "SEK", coords: CLLocationCoordinate2D(latitude: 60.128161, longitude: 18.643501)),
        Country(id: "473", countryName: "Switzerland", countryCode: "CH", currencyCode: "CHF", coords: CLLocationCoordinate2D(latitude: 46.818188, longitude: 8.227512)),
        Country(id: "508", countryName: "Syria", countryCode: "SY", currencyCode: "SYP", coords: CLLocationCoordinate2D(latitude: 34.802075, longitude: 38.996815)),
        Country(id: "547", countryName: "Taiwan", countryCode: "TW", currencyCode: "TWD", coords: CLLocationCoordinate2D(latitude: 23.69781, longitude: 120.960515)),
        Country(id: "487", countryName: "Tajikistan", countryCode: "TJ", currencyCode: "TJS", coords: CLLocationCoordinate2D(latitude: 38.861034, longitude: 71.276093)),
        Country(id: "617", countryName: "Tanzania", countryCode: "TZ", currencyCode: "TZS", coords: CLLocationCoordinate2D(latitude: -6.369028, longitude: 34.888822)),
        Country(id: "530", countryName: "Thailand", countryCode: "TH", currencyCode: "THB", coords: CLLocationCoordinate2D(latitude: 15.870032, longitude: 100.992541)),
        Country(id: "592", countryName: "Togo", countryCode: "TG", currencyCode: "XOF", coords: CLLocationCoordinate2D(latitude: 8.619543, longitude: 0.824782)),
        Country(id: "557", countryName: "Tokelau", countryCode: "TK", currencyCode: "NZD", coords: CLLocationCoordinate2D(latitude: -8.967363, longitude: -171.855881)),
        Country(id: "573", countryName: "Tonga", countryCode: "TO", currencyCode: "TOP", coords: CLLocationCoordinate2D(latitude: -21.178986, longitude: -175.198242)),
        Country(id: "433", countryName: "Trinidad and Tobago", countryCode: "TT", currencyCode: "TTD", coords: CLLocationCoordinate2D(latitude: 10.691803, longitude: -61.222503)),
        Country(id: "576", countryName: "Tunisia", countryCode: "TN", currencyCode: "TND", coords: CLLocationCoordinate2D(latitude: 33.886917, longitude: 9.537499)),
        Country(id: "506", countryName: "Turkey", countryCode: "TR", currencyCode: "TRY", coords: CLLocationCoordinate2D(latitude: 38.963745, longitude: 35.243322)),
        Country(id: "488", countryName: "Turkmenistan", countryCode: "TM", currencyCode: "TMT", coords: CLLocationCoordinate2D(latitude: 38.969719, longitude: 59.556278)),
        Country(id: "419", countryName: "Turks and Caicos Islands", countryCode: "TC", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 21.694025, longitude: -71.797928)),
        Country(id: "564", countryName: "Tuvalu", countryCode: "TV", currencyCode: "AUD", coords: CLLocationCoordinate2D(latitude: -7.109535, longitude: 177.64933)),
        Country(id: "613", countryName: "Uganda", countryCode: "UG", currencyCode: "UGX", coords: CLLocationCoordinate2D(latitude: 1.373333, longitude: 32.290275)),
        Country(id: "480", countryName: "Ukraine", countryCode: "UA", currencyCode: "UAH", coords: CLLocationCoordinate2D(latitude: 48.379433, longitude: 31.16558)),
        Country(id: "519", countryName: "United Arab Emirates", countryCode: "AE", currencyCode: "AED", coords: CLLocationCoordinate2D(latitude: 23.424076, longitude: 53.847818)),
        Country(id: "459", countryName: "United Kingdom", countryCode: "GB", currencyCode: "GBP", coords: CLLocationCoordinate2D(latitude: 55.378051, longitude: -3.435973)),
        Country(id: "449", countryName: "Uruguay", countryCode: "UY", currencyCode: "UYU", coords: CLLocationCoordinate2D(latitude: -32.522779, longitude: -55.765835)),
        Country(id: "640", countryName: "US minor outlying Islands", countryCode: "UM", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 00.000000, longitude: 00.000000)),
        Country(id: "489", countryName: "Uzbekistan", countryCode: "UZ", currencyCode: "UZS", coords: CLLocationCoordinate2D(latitude: 41.377491, longitude: 64.585262)),
        Country(id: "561", countryName: "Vanuatu", countryCode: "VU", currencyCode: "VUV", coords: CLLocationCoordinate2D(latitude: -15.376706, longitude: 166.959158)),
        Country(id: "495", countryName: "Vatican City", countryCode: "VA", currencyCode: "EUR", coords: CLLocationCoordinate2D(latitude: 41.902916, longitude: 12.453389)),
        Country(id: "439", countryName: "Venezuela", countryCode: "VE", currencyCode: "VES", coords: CLLocationCoordinate2D(latitude: 6.42375, longitude: -66.58973)),
        Country(id: "531", countryName: "Vietnam", countryCode: "VN", currencyCode: "VND", coords: CLLocationCoordinate2D(latitude: 14.058324, longitude: 108.277199)),
        Country(id: "636", countryName: "Virgin Islands of the United States", countryCode: "VI", currencyCode: "USD", coords: CLLocationCoordinate2D(latitude: 18.335765, longitude: -64.896335)),
        Country(id: "566", countryName: "Wallis and Futuna", countryCode: "WF", currencyCode: "XPF", coords: CLLocationCoordinate2D(latitude: -13.768752, longitude: -177.156097)),
        Country(id: "580", countryName: "Western Sahara", countryCode: "EH", currencyCode: "MAD", coords: CLLocationCoordinate2D(latitude: 24.215527, longitude: -12.885834)),
        Country(id: "559", countryName: "Western Samoa", countryCode: "WS", currencyCode: "WST", coords: CLLocationCoordinate2D(latitude: -13.759029, longitude: -172.104629)),
        Country(id: "627", countryName: "Zambia", countryCode: "ZM", currencyCode: "ZMW", coords: CLLocationCoordinate2D(latitude: -13.133897, longitude: 27.849332)),
        Country(id: "629", countryName: "Zimbabwe", countryCode: "ZW", currencyCode: "ZWG", coords: CLLocationCoordinate2D(latitude: -19.015438, longitude: 29.154857))
    ]
    
    static func fetchCountryPiece(id: String?) -> Country? {
        guard id != nil else {return nil}
        let countryPiece = Countries.countriesArray.filter { $0.id == String(id!) }.first
        return countryPiece
    }
    
    static func fetchCountryString(piece: Country) -> String? {
        let countryString = Countries.countriesArray.filter { $0 == piece }.first?.countryName
        return countryString
    }
    
    static func fetchCoordinates(id: String) -> CLLocationCoordinate2D {
        let countryPiece = Countries.countriesArray.filter { $0.id == id }
        return countryPiece[0].coords
    }
    
    static func convert(amount: Double, from: Country, to: Country) -> Double? {
        guard
            let fromRate = from.exchangeRate,
            let toRate = to.exchangeRate
        else {
            return nil
        }

        /// Convert source currency to USD
        let usd = amount / fromRate

        /// Convert USD to destination currency
        return usd * toRate
    }
}
