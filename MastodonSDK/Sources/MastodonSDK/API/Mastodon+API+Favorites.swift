//
//  Mastodon+API+Favorites.swift
//
//
//  Created by sxiaojian on 2021/2/7.
//

import Combine
import Foundation

extension Mastodon.API.Favorites {
    static func favoritesStatusesEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("favourites")
    }

    static func favoriteByUserListsEndpointURL(domain: String, statusID: String) -> URL {
        let pathComponent = "statuses/" + statusID + "/favourited_by"
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }

    static func favoriteActionEndpointURL(domain: String, statusID: String, favoriteKind: FavoriteKind) -> URL {
        var actionString: String
        switch favoriteKind {
        case .create:
            actionString = "/favourite"
        case .destroy:
            actionString = "/unfavourite"
        }
        let pathComponent = "statuses/" + statusID + actionString
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(pathComponent)
    }

    public static func favorites(domain: String, statusID: String, session: URLSession, authorization: Mastodon.API.OAuth.Authorization, favoriteKind: FavoriteKind) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Status>, Error> {
        let url: URL = favoriteActionEndpointURL(domain: domain, statusID: statusID, favoriteKind: favoriteKind)
        var request = Mastodon.API.post(url: url, query: nil, authorization: authorization)
        request.httpMethod = "POST"
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Status.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func getFavoriteByUserLists(domain: String, statusID: String, session: URLSession, authorization: Mastodon.API.OAuth.Authorization) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let url = favoriteByUserListsEndpointURL(domain: domain, statusID: statusID)
        let request = Mastodon.API.get(url: url, query: nil, authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func getFavoriteStatus(domain: String, session: URLSession, authorization: Mastodon.API.OAuth.Authorization, query: Mastodon.API.Favorites.ListQuery) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {
        let url = favoritesStatusesEndpointURL(domain: domain)
        let request = Mastodon.API.get(url: url, query: query, authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

public extension Mastodon.API.Favorites {
    enum FavoriteKind {
        case create
        case destroy
    }
    
    struct ListQuery: GetQuery,TimelineQueryType {
        
        public var limit: Int?
        public var minID: String?
        public var maxID: String?
        public var sinceID: Mastodon.Entity.Status.ID?
        
        public init(limit: Int? = nil, minID: String? = nil, maxID: String? = nil, sinceID: String? = nil) {
            self.limit = limit
            self.minID = minID
            self.maxID = maxID
            self.sinceID = sinceID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            if let limit = self.limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let minID = self.minID {
                items.append(URLQueryItem(name: "min_id", value: minID))
            }
            if let maxID = self.maxID {
                items.append(URLQueryItem(name: "max_id", value: maxID))
            }
            if let sinceID = self.sinceID {
                items.append(URLQueryItem(name: "since_id", value: sinceID))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
