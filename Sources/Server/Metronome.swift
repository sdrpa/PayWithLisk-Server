// Created by Sinisa Drpa on 11/17/17.

import Dispatch
import Foundation

final class Metronome {
   // The Lisk network forges blocks in 10s intervals
   static let delay = 10.0
   var tick: (() -> Void)?
   
   private let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))

   init() {
      timer.setEventHandler() { [unowned self] in
         self.tick?()
      }

      let now = DispatchTime.now()
      let deadline = DispatchTime(uptimeNanoseconds: now.uptimeNanoseconds + (UInt64(Metronome.delay * 1e9)))
      timer.schedule(deadline: deadline, repeating: Metronome.delay)
      timer.resume()
   }

   deinit {
      timer.suspend()
   }
}
