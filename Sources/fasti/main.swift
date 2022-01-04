import EventKit
import SwiftCLI

class GreetCommand: Command {
    let name = "greet"

    @Param var person: String

    func execute() throws {
        stdout <<< "Hello \(person)!"
    }
}

func completion(granted: Bool, error: Error!){
  // print("granted: \(granted)")
}
let calendar = Calendar.autoupdatingCurrent

EKEventStore().requestAccess(to:.event, completion: completion)

let eventStore = EKEventStore()

let calendars = eventStore.calendars(for: .event)

let now = Date()
let weekFromNow = now.addingTimeInterval(7.0 * 24.0 * 3600.0)
// for (_, calendar) in calendars.enumerated(){
//   print(calendar.title)
//   let predicate = eventStore.predicateForEvents(withStart: now, end: weekFromNow, calendars: [calendar])
//   let matchingEvents = eventStore.events(matching: predicate)
//   for event in matchingEvents{
//     print("\t\(event.title!) - \(event.calendar.title!)\n\t\t\(event.startDate!)-\(event.endDate!)")
//   }
// }
  let predicate = eventStore.predicateForEvents(withStart: now, end: weekFromNow, calendars: calendars)
  let matchingEvents = eventStore.events(matching: predicate)
  for event in matchingEvents{
    print("\(event.title!) - \(event.calendar.title)\n\t\(event.startDate!)-\(event.endDate!)")
    // print(event)
  }

  let greeter = CLI(name: "greeter")
  greeter.commands = [GreetCommand()]
  greeter.go()
