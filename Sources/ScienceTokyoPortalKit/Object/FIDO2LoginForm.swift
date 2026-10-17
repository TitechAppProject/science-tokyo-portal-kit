import Foundation
import Kanna

struct FIDO2LoginForm {
    let authenticityToken: String
    let optionsURL: URL
    let submitURL: URL
    let pageURL: URL
    let origin: FIDO2Origin

    init?(element: Kanna.XMLElement, pageURL: URL) {
        guard element["method"]?.lowercased() == "post",
            let token = element.css("input[name='authenticity_token']").first?["value"], !token.isEmpty,
            let optionsPath = element["data-options-path"], !optionsPath.isEmpty,
            let optionsURL = URL(string: optionsPath, relativeTo: pageURL)?.absoluteURL,
            let submitURL = URL(string: element["action"] ?? "", relativeTo: pageURL)?.absoluteURL,
            let origin = FIDO2Origin(url: pageURL),
            FIDO2Origin(url: optionsURL) == origin, FIDO2Origin(url: submitURL) == origin
        else {
            return nil
        }
        self.authenticityToken = token
        self.optionsURL = optionsURL
        self.submitURL = submitURL
        self.pageURL = pageURL
        self.origin = origin
    }
}
