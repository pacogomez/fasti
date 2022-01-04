import EventKit
import SwiftCLI

import SwiftyTextTable

// First create some columns
let eventCol = TextTableColumn(header: "Event")
let startCol = TextTableColumn(header: "Start")
let endCol = TextTableColumn(header: "End")
let calendarCol = TextTableColumn(header: "Calendar")

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
let weekFromNow = now.addingTimeInterval(1 * 24.0 * 3600.0)

let localDateFormatter = DateFormatter()
localDateFormatter.dateStyle = .medium
localDateFormatter.timeStyle = .medium

// for (_, calendar) in calendars.enumerated(){
//   print(calendar.title)
//   let predicate = eventStore.predicateForEvents(withStart: now, end: weekFromNow, calendars: [calendar])
//   let matchingEvents = eventStore.events(matching: predicate)
//   for event in matchingEvents{
//     print("\t\(event.title!) - \(event.calendar.title!)\n\t\t\(event.startDate!)-\(event.endDate!)")
//   }
// }

var table = TextTable(columns: [eventCol, startCol, endCol, calendarCol])

  let predicate = eventStore.predicateForEvents(withStart: now, end: weekFromNow, calendars: calendars)
  let matchingEvents = eventStore.events(matching: predicate)
  for event in matchingEvents{
    table.addRow(values:[event.title!, localDateFormatter.string(from:event.startDate!),localDateFormatter.string(from:event.endDate!),event.calendar.title])
    // print("\(event.title!) - \(event.calendar.title)\n\t\(localDateFormatter.string(from:event.startDate!)) - \(localDateFormatter.string(from:event.endDate!))")
    // print(event)
  }


  // Then render the table and use
  let tableString = table.render()
  print(tableString)

  let greeter = CLI(name: "greeter")
  greeter.commands = [GreetCommand()]
  // greeter.go()
