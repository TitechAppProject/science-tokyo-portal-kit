//
//  LMSPageRequest.swift
//  ScienceTokyoPortalKit
//
//  Created by 中島正矩 on 2025/04/09.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct LMSPageRequest: HTTPRequest {
    let url: URL = URL(string: LMSBaseURL.origin)!
    
    var method: HTTPMethod = .get
    
    var headerFields: [String: String]? = [
        "Connection": "keep-alive",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
        "Accept-Encoding": "br, gzip, deflate",
        "Accept-Language": "ja-jp",
    ]
    
    var body: [String: String]? = nil
}
