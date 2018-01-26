// Created by Sinisa Drpa on 12/24/17.

import Foundation
import Then

struct Transaction: Decodable {
   let id: String
   let timestamp: Int
   let senderId: String
   let recipientId: String?
   let amount: Int
   let fee: Int
}

// https://docs.lisk.io/docs/lisk-api-080-transactions
final class Lisk {
   // http://node08.lisk.io:8000/api/transactions/get?id=
   private static var basePath: String {
      let port = String(8000)
      let path = "http://node08.lisk.io:" + port + "/api"
      return path
   }

   private let session = URLSession(configuration: .default)
   private var dataTask: URLSessionDataTask?
}

extension Lisk {
   enum err: Error, LocalizedError {
      case invalidTransactions

      var errorDescription: String? {
         switch self {
         case .invalidTransactions:
            return "Could not find the transactions."
         }
      }
   }
}

extension Lisk {
   // curl -k -X GET http://node08.lisk.io:8000/api/transactions?senderId=1440867060433296113
   func transactions(senderId: String, recipientId: String) throws -> [Transaction] {
      let request = URLRequest(path: Lisk.basePath + "/transactions",
                               method: .get,
                               params: ["senderId": senderId, "recipientId": recipientId],
                               timeoutInterval: 10.0)
      let transactions = try await(gettransactions(request: request))
      return transactions
   }
}

extension Lisk {
   private func gettransactions(request: URLRequest) -> Promise<[Transaction]> {
      func decode(transactions data: Data) throws -> [Transaction] {
         struct Result: Decodable {
            let success: Bool
            let transactions: [Transaction]?
         }
         let decoder = JSONDecoder()
         do {
            let result = try decoder.decode(Result.self, from: data)
            guard let txs = result.transactions else {
               throw err.invalidTransactions
            }
            let txs1 = txs.map { tx -> Transaction in
               let customEpoch = "2016-5-24 17:00:00 +0000".toDate(format: "yyyy-MM-dd HH:mm:ss ZZZ").timeIntervalSince1970
               let timestamp = Int(customEpoch + Double(tx.timestamp))

               let transaction = Transaction(id: tx.id, timestamp: timestamp, senderId: tx.senderId, recipientId: tx.recipientId, amount: tx.amount, fee: tx.fee)
               return transaction
            }
            return txs1
         } catch let e {
            throw e
         }
      }

      return Promise { [weak self] resolve, reject in
         self?.dataTask = self?.session.dataTask(with: request) { data, response, error in
            if let error = error {
               reject(error)
            } else if let data = data,
               let response = response as? HTTPURLResponse,
               response.statusCode == 200 {
                  do {
                     let t = try decode(transactions: data)
                     resolve(t)
                  } catch let e {
                     reject(e)
                  }
            }
         }
         self?.dataTask?.resume()
      }
   }
}
