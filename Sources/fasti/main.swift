//(C) 2022 Paco Gomez

import EventKit
import SwiftCLI

import SwiftyTextTable

func completion(granted: Bool, error: Error!){
  // print("granted: \(granted)")
}

let calendar = Calendar.autoupdatingCurrent

EKEventStore().requestAccess(to:.event, completion: completion)

let eventStore = EKEventStore()

let sources = eventStore.sources

class GetGroup: CommandGroup {
    let name = "get"
    let children: [Routable] = [ListEventsCommand(), ListCalendarsCommand()]
    let shortDescription = "get"
}

class AddGroup: CommandGroup {
    let name = "add"
    let children: [Routable] = [AddEventCommand()]
    let shortDescription = "add"
}

class AddEventCommand: Command {
  let name = "event"
  func execute() throws {
    print("not implemented")
  }
}

class DelGroup: CommandGroup {
    let name = "del"
    let children: [Routable] = [DelEventCommand()]
    let shortDescription = "del"
}

class DelEventCommand: Command {
  let name = "event"
  func execute() throws {
    print("not implemented")
  }
}

class ListEventsCommand: Command {
    let name = "events"

    @Key("-n", "--next")
    var next: Int?

    @Key("-s", "--start")
    var start: String?

    // @Flag("-o", "--output")
    // var outputFormat: String

    func execute() throws {
      var startDate: Date? = Date()
      if let start = start {
        if start.count > 0 {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          startDate = dateFormatter.date(from: start)
          if startDate == nil {
            print("invalid start date: \(start)")
            return
          }
        }
      }
      let next = next ?? 1
      let calendars = eventStore.calendars(for: .event)

      let endOfToday = Calendar.current.date(bySettingHour:23, minute:59, second: 59, of: startDate!) ?? startDate!
      let later = Calendar.current.date(byAdding: .day, value: next, to:endOfToday) ?? startDate!

      let localDateFormatter = DateFormatter()
      localDateFormatter.dateFormat = "yyyy-MM-dd hh:mm a EEEEE"

      let eventCol = TextTableColumn(header: "Event")
      let startCol = TextTableColumn(header: "Start")
      let endCol = TextTableColumn(header: "End")
      let calendarCol = TextTableColumn(header: "Calendar")

      var table = TextTable(columns: [startCol, endCol, eventCol, calendarCol])

      let predicate = eventStore.predicateForEvents(withStart: startDate!, end: later, calendars: calendars)
      let matchingEvents = eventStore.events(matching: predicate)
      for event in matchingEvents{
        table.addRow(values:[localDateFormatter.string(from:event.startDate!),localDateFormatter.string(from:event.endDate!),event.title!, event.calendar.source.title+"/"+event.calendar.title])
        // print(event)
        // print(event.attendees)
        // print("--")
      }
      let tableString = table.render()
      print(tableString)
    }
}

class ListCalendarsCommand: Command {
    let name = "calendars"

    func execute() throws {
        for (_, source) in sources.enumerated(){
           print(source.title, source.value(forKey: "displayOrder")!)
           for (_, calendar) in source.calendars(for: .event).enumerated(){
             print("  \(calendar.title)", calendar.value(forKey: "displayOrder")!)
           }
        }
    }
}

let fastiCli = CLI(name: "fasti")
fastiCli.commands = [GetGroup(), AddGroup(), DelGroup()]
fastiCli.go()
