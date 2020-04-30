//
//  SearchQuery.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/03/22.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import Foundation

struct SearchQuery: Codable, Equatable {
  var page: Int
  let criteria: Int
  let alignment: Int
  let category: Int?
  let period: String?
  var keyword: String?

  init(_ page: Int = 0,
       _ criteria: Int = 0,
       _ alignment: Int = 0,
       _ category: Int? = nil,
       _ period: String? = nil,
       _ keyword: String? = nil) {
    self.page = page
    self.criteria = criteria
    self.alignment = alignment
    self.category = category
    self.period = period
    self.keyword = keyword
  }
}
