// Created by Sinisa Drpa on 11/16/17.

import Foundation
import Kitura
import KituraCache
import KituraCORS
import KituraNet
import KituraWebSocket
import SwiftyJSON

struct Config {
   static let storeAddress = "17206648368948385036L"
}

public final class Server {
   private let socketService = SocketService()
   private let metronome = Metronome()
   private let lisk = Lisk()
   // Store [senderId: Order]
   private let store = KituraCache(defaultTTL: 0, checkFrequency: 600)

   public init() {
      // Set self as SocketServiceDelegate to be able to receive new order events
      self.socketService.delegate = self

      // Since there is no way to receive transaction completed event from a node,
      // we use Lisk API to get transactions for store wallet
      self.metronome.tick = { [unowned self] in
         do {
            // On metronome tick, loop through the pending orders and check whether transaction
            // for a pending order has been completed (whether a user has paid the order).
            // If the transaction for a pending order has been completed, update the store
            // (mark the order as completed).
            guard let keys = self.store.keys() as? [String] else {
               return
            }
            for senderId in keys {
               guard let order = self.store.object(forKey: senderId) as? Order,
                  // Process only pending orders
                  order.status == .pending else {
                  continue
               }
               // Prevent reusing previous transaction
               let prevTransactionIds = self.allOrders.map { $0.transactionId }
               //print(prevTransactionIds)
               if prevTransactionIds.contains(where: {
                  order.transactionId != nil && $0 == order.transactionId }) {
                     continue
               }
               print("Verify transaction for order, sender: \(order.senderId), item: \(order.item)")
               // Use Lisk API to get the store wallet transactions where
               // the senderId is equal to the pending order senderId
               let txs = try self.lisk.transactions(senderId: order.senderId,
                                                   recipientId: Config.storeAddress)
               // We use the most recent transaction
               guard let tx = txs.last else { continue }
               // Save the order to store, but this time set the status as completed

               // We should check if the amount paid is equal to the item price,
               // Skipped here to avoid complexity, basically we should get
               // the item price from a database and compare to tx amount
               let anOrder = Order(transactionId: tx.id, senderId: senderId, item: order.item, status: .completed)
               self.store.setObject(anOrder, forKey: anOrder.senderId)
               print("Order completed, sender: \(order.senderId), item: \(order.item)")
               // Broadcast the message
               let message = OrderResult(senderid: anOrder.senderId,
                                         status: OrderStatus.completed.rawValue)
               self.socketService.broadcast(data: try JSONEncoder().encode(message))
            }
         } catch let e {
            print(e.localizedDescription)
         }
      }
   }
   
   public func run() {
      var cors: CORS {
         let options = Options(allowedOrigin: .all, maxAge: 5)
         return CORS(options: options)
      }

      let router = Router()
      router.all("/",  middleware: cors)

      WebSocket.register(service: socketService, onPath: "/payment")

      let server = HTTP.createServer()
      server.delegate = router

      let port = Int(8182)
      do {
         try server.listen(on: port)
         ListenerGroup.waitForListeners()
      } catch {
         print("Could not listen on port \(port): \(error)")
      }
   }
}

extension Server: SocketServiceDelegate {
   func socketServiceDidReceive(order: Order) {
      // The received order is saved to store
      store.setObject(order, forKey: order.senderId)
   }
}

extension Server {
   var allOrders: [Order] {
      guard let keys = store.keys() as? [String] else {
         return []
      }
      var orders: [Order] = []
      for senderId in keys {
         guard let order = store.object(forKey: senderId) as? Order else {
            continue
         }
         orders.append(order)
      }
      return orders
   }
}
