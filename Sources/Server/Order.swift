// Created by Sinisa Drpa on 1/25/18.

import Foundation

struct OrderResult: Codable {
   let senderid: String
   let status: String
}

enum OrderStatus: String, Codable {
   case pending
   case completed
}

struct Order: Codable {
   let transactionId: String?
   let senderId: String
   let item: String
   let status: OrderStatus

   init(transactionId: String? = nil, senderId: String, item: String, status: OrderStatus = .pending) {
      self.transactionId = transactionId
      self.senderId = senderId
      self.item = item
      self.status = status
   }
}
