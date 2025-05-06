//
//  LMSRedirectPageRequest.swift
//  ScienceTokyoPortalKit
//
//  Created by 中島正矩 on 2025/04/09.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct LMSRedirectPageRequest: HTTPRequest {
    let url: URL = URL(string: LMSBaseURL.origin + "auth/saml2/sp/saml2-acs.php/lms.isct.ac.jp")!

    var method: HTTPMethod = .post

    var headerFields: [String: String]? = [
        "Referer": BaseURL.origin,
        "Host": LMSBaseURL.host,
        "Origin": BaseURL.origin,
        "Connection": "keep-alive",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "cross-site",
        "Priority": "u=3, i"
    ]

    var body: [String: String]?

    init(htmlInputs: [HTMLInput], htmlMetas: [HTMLMeta]) {
        body = htmlInputs.reduce(into: [String: String]()) {
            $0[$1.name] = $1.value
        }
        // headerFieldsにhtmlMetasを追加
        htmlMetas.forEach {
            headerFields?[$0.name] = $0.content
        }
    }
}
