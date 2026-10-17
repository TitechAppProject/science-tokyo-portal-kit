import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FIDO2Relay1Request: HTTPRequest {
    let url: URL = URL(string: BaseURL.origin + "/idm/user/fido2_setting/add/relay1")!

    var method: HTTPMethod = .post

    var postContentType: PostContentType = .json

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin + "/idm/user/fido2_setting/",
        "Host": BaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "application/json",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "cors",
        "Sec-Fetch-Site": "same-origin",
        "Priority": "u=3, i",
        "Content-Type": "application/json;charset=UTF-8",
    ]

    var body: [String: String]? = nil

    var jsonBody: [String: Any]?

    init(csrfToken: String, username: String, displayName: String) {
        headerFields?["X-CSRF-Token"] = csrfToken
        jsonBody = [
            "siteId": ExticFIDO2Protocol.siteId,
            "svcId": ExticFIDO2Protocol.serviceId,
            "origin": BaseURL.origin,
            "user": [
                "name": username
            ],
            "rp": [
                "id": BaseURL.host
            ],
            "authnrAttachment": "",
            "credentialAlias": displayName,
            "reqProtocolType": ExticFIDO2Protocol.registrationProtocolType,
        ]
    }
}
