// Created by Sinisa Drpa on 12/31/17.

import Foundation

extension URLRequest {
   enum URLRequestMethod: String {
      case get = "GET"
      case post = "POST"
   }

   init(path: String, method: URLRequestMethod, timeoutInterval: TimeInterval) {
      self.init(path: path, method: method, params: [:], timeoutInterval: timeoutInterval)
   }

   init(path: String, method: URLRequestMethod, params: [String: String], timeoutInterval: TimeInterval) {
      precondition(timeoutInterval >= 1.0)
      guard var url = URL(string: path) else {
         fatalError()
      }
      url = url.appendingQueryParameters(params)
      self = URLRequest(url: url)
      self.httpMethod = method.rawValue
      self.timeoutInterval = timeoutInterval
   }
}

// MARK: -

protocol URLQueryParameterStringConvertible {
   var queryParameters: String { get }
}

extension Dictionary: URLQueryParameterStringConvertible {
   /**
    This computed property returns a query parameters string from the given NSDictionary. For
    example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
    string will be @"day=Tuesday&month=January".
    @return The computed parameters string.
    */
   var queryParameters: String {
      var parts: [String] = []
      for (aKey, aValue) in self {
         let key = String(describing: aKey).encodingAddingPercent()
         let value = String(describing: aValue).encodingAddingPercent()
         parts.append("\(key)=\(value)")
      }
      return parts.joined(separator: "&")
   }
}

extension URL {
   /**
    Creates a new URL by adding the given query parameters.
    @param parametersDictionary The query parameter dictionary to add.
    @return A new URL.
    */
   func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
      let URLString : String = "\(self.absoluteString)?\(parametersDictionary.queryParameters)"
      return URL(string: URLString)!
   }
}

extension String {
   func lastIndexOf(target: String) -> Int? {
      if let range = self.range(of: target, options: .backwards) {
         return self.distance(from: startIndex, to: range.lowerBound)
      } else {
         return nil
      }
   }

   func encodingAddingPercent() -> String {
      guard let string = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
         fatalError()
      }
      return string
   }
}

// MARK -

extension Decimal {
   var doubleValue:Double {
      return NSDecimalNumber(decimal:self).doubleValue
   }

   func round(precision: Int) -> Decimal {
      var result = self
      var number = self
      NSDecimalRound(&result, &number, precision, .bankers)
      return result
   }
}

extension String {
   init(_ double: Double, rounded fractionDigits: Int) {
      self = double.string(rounded: fractionDigits)
   }
}

fileprivate extension Double {
   func string(rounded fractionDigits: Int) -> String {
      let formatter = NumberFormatter()
      formatter.minimumFractionDigits = fractionDigits
      formatter.maximumFractionDigits = fractionDigits
      return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
   }
}

// MARK: - Date

extension Date {
   struct Formatter {
      static let iso8601: DateFormatter = {
         let formatter = DateFormatter()
         formatter.calendar = Calendar(identifier: .iso8601)
         formatter.locale = Locale(identifier: "en_US_POSIX")
         formatter.timeZone = TimeZone(identifier: "UTC")
         formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
         return formatter
      }()
   }

   var iso8601: String {
      var data = Formatter.iso8601.string(from: self)
      if let fractionStart = data.range(of: "."),
         let fractionEnd = data.index(fractionStart.lowerBound, offsetBy: 7, limitedBy: data.endIndex) {
         let fractionRange = fractionStart.lowerBound..<fractionEnd
         let intVal = Int64(1000000 * self.timeIntervalSince1970)
         let newFraction = String(format: ".%06d", intVal % 1000000)
         data.replaceSubrange(fractionRange, with: newFraction)
      }
      return data
   }

   var startOfWeek: Date? {
      var calendar = Calendar(identifier: .gregorian)
      guard let tz = TimeZone(identifier: "UTC") else {
         return nil
      }
      calendar.timeZone = tz
      guard let date = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
         return nil
      }
      return date
   }

   var endOfWeek: Date? {
      guard let startOfWeek = self.startOfWeek else {
         return nil
      }
      var calendar = Calendar(identifier: .gregorian)
      guard let tz = TimeZone(identifier: "UTC") else {
         return nil
      }
      calendar.timeZone = tz
      return calendar.date(byAdding: .second, value: 604799, to: startOfWeek)
   }
}

extension String {
   var dateFromISO8601: Date? {
      guard let parsedDate = Date.Formatter.iso8601.date(from: self) else {
         return nil
      }

      var preliminaryDate = Date(timeIntervalSinceReferenceDate: floor(parsedDate.timeIntervalSinceReferenceDate))

      if let fractionStart = self.range(of: "."),
         let fractionEnd = self.index(fractionStart.lowerBound, offsetBy: 7, limitedBy: self.endIndex) {
         let fractionRange = fractionStart.lowerBound..<fractionEnd
         //let fractionStr = self.substring(with: fractionRange)
         let fractionStr = self[fractionRange]

         if var fraction = Double(fractionStr) {
            fraction = Double(floor(1000000*fraction)/1000000)
            preliminaryDate.addTimeInterval(fraction)
         }
      }
      return preliminaryDate
   }

   func toDate(format: String) -> Date {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = format
      dateFormatter.timeZone = TimeZone(identifier: "UTC")
      if let date = dateFormatter.date(from: self) {
         return date
      }
      fatalError()
   }
}
