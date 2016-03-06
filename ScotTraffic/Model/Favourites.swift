//
//  Favourites.swift
//  ScotTraffic
//
//  Created by Neil Gall on 04/10/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

private let favouritesKey = "favouriteItems"
private let typeKey = "type"
private let typeSavedSearch = "savedSearch"
private let typeTrafficCamera = "trafficCamera"
private let termKey = "term"
private let identifierKey = "identifier"

enum FavouriteItem: Equatable {
    case SavedSearch(term: String)
    case TrafficCamera(identifier: String)
}

class Favourites {
    private let userDefaults: UserDefaultsProtocol
    let items: Input<[FavouriteItem]>
    
    private var receivers = [ReceiverType]()
    
    init(userDefaults: UserDefaultsProtocol) {
        self.userDefaults = userDefaults
        self.items = Input(initial: [])
        
        reloadFromUserDefaults()
        
        receivers.append(items --> {
            userDefaults.setObject($0.map(dictionaryFromFavouriteItem), forKey: favouritesKey)
        })
    }
    
    func containsItem(item: FavouriteItem) -> Bool {
        return self.items.value.contains({ $0 == item })
    }
    
    func addItem(item: FavouriteItem) {
        items.modify {
            return $0 + [item]
        }
        analyticsEvent(.AddFavourite, dictionaryFromFavouriteItem(item))
    }
    
    func deleteItem(item: FavouriteItem) {
        items.modify { items in
            return items.filter({ $0 != item })
        }
        analyticsEvent(.DeleteFavourite, dictionaryFromFavouriteItem(item))
    }

    func deleteItemAtIndex(index: Int) {
        items.modify { items in
            let item = items[index]
            analyticsEvent(.DeleteFavourite, dictionaryFromFavouriteItem(item))
            return items.filter({ $0 != item })
        }
    }
    
    func moveItemFromIndex(fromIndex: Int, toIndex: Int) {
        var items = self.items.value
        if fromIndex > toIndex {
            items.insert(items[fromIndex], atIndex: toIndex)
            items.removeAtIndex(fromIndex+1)
        } else if fromIndex < toIndex {
            items.insert(items[fromIndex], atIndex: toIndex+1)
            items.removeAtIndex(fromIndex)
        }
        analyticsEvent(.ReorderFavourites)
        self.items <-- items
    }
    
    func reloadFromUserDefaults() {
        let object = userDefaults.objectForKey(favouritesKey)
        guard let items = object as? [AnyObject] else {
            return
        }
        self.items <-- items.flatMap(favouriteItemFromObject)
    }
}

private func favouriteItemFromObject(object: AnyObject) -> FavouriteItem? {
    if let identifier = object as? String {
        // pre-1.2 favourite which is always a traffic camera
        return .TrafficCamera(identifier: identifier)
    }
    
    guard let dictionary = object as? [String: String] else {
        return nil
    }
    
    if let term = dictionary[termKey] where dictionary[typeKey] == typeSavedSearch {
        return .SavedSearch(term: term)
        
    } else if let identifier = dictionary[identifierKey] where dictionary[typeKey] == typeTrafficCamera {
        return .TrafficCamera(identifier: identifier)
        
    } else {
        return nil
    }
}

private func dictionaryFromFavouriteItem(favourite: FavouriteItem) -> [String:String] {
    switch favourite {
    case .SavedSearch(let term):
        return [ typeKey: typeSavedSearch, termKey: term ]
    case .TrafficCamera(let identifier):
        return [ typeKey: typeTrafficCamera, identifierKey: identifier ]
    }
}

func == (lhs: FavouriteItem, rhs: FavouriteItem) -> Bool {
    switch (lhs, rhs) {
    case (.SavedSearch(let lhsTerm), .SavedSearch(let rhsTerm)):
        return lhsTerm == rhsTerm
    case (.TrafficCamera(let lhsId), .TrafficCamera(let rhsId)):
        return lhsId == rhsId
    default:
        return false
    }
}

extension SequenceType where Generator.Element == FavouriteItem {
    var trafficCameraIdentifiers: Set<String> {
        return Set(flatMap({
            if case .TrafficCamera(let identifier) = $0 {
                return identifier
            } else {
                return nil
            }
        }))
    }
    
    func containsSavedSearch(searchTerm: String) -> Bool {
        return contains({
            if case .SavedSearch(let savedTerm) = $0 where savedTerm == searchTerm {
                return true
            } else {
                return false
            }
        })
    }
}
