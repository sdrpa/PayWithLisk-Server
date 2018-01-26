// Created by Sinisa Drpa on 1/21/18.

import Foundation
import KituraWebSocket
import KituraCache

protocol SocketServiceDelegate: class {
   func socketServiceDidReceive(order: Order)
}

final class SocketService {
   private let conn = KituraCache(defaultTTL: 0, checkFrequency: 600)
   weak var delegate: SocketServiceDelegate?
}

extension SocketService {
   func broadcast(data: Data) {
      guard let keys = conn.keys() as? [String] else {
         return
      }
      for key in keys {
         if let connection = conn.object(forKey: key) as? WebSocketConnection {
            connection.send(message: data, asBinary: false)
         }
      }
   }
}

// https://developer.ibm.com/swift/2017/01/17/working-websockets-kitura-based-server/
// http://www.websocket.org/echo.html
extension SocketService: WebSocketService {
   func connected(connection: WebSocketConnection) {
      conn.setObject(connection, forKey: connection.id)
   }

   func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
      conn.removeObject(forKey: connection.id)
   }

   func received(message: Data, from: WebSocketConnection) {
      from.close(reason: .invalidDataType, description: "Server only accepts text messages.")
      conn.removeObject(forKey: from.id)
   }

   func received(message: String, from: WebSocketConnection) {
      guard let data = message.data(using: .utf8) else {
         fatalError("Data is nil.")
      }
      do {
         struct _Order: Codable {
            let senderId: String
            let item: String
         }
         // Create order struct (by default the order status is set to pending)
         let _order = try JSONDecoder().decode(_Order.self, from: data)
         // Advise delegate that order has been received
         delegate?.socketServiceDidReceive(order: Order(senderId: _order.senderId, item: _order.item))
      } catch let e {
         print(e.localizedDescription)
      }
   }
}
