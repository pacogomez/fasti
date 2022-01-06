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

    func execute() throws {
      let nextDays : Int = next ?? 1
      let calendars = eventStore.calendars(for: .event)

      let now = Date()
      let endOfToday = Calendar.current.date(bySettingHour:23, minute:59, second: 59, of: now) ?? now
      let later = Calendar.current.date(byAdding: .day, value: nextDays, to:endOfToday) ?? now

      let localDateFormatter = DateFormatter()
      localDateFormatter.dateFormat = "yyyy-MM-dd hh:mm a EEEEE"

      let eventCol = TextTableColumn(header: "Event")
      let startCol = TextTableColumn(header: "Start")
      let endCol = TextTableColumn(header: "End")
      let calendarCol = TextTableColumn(header: "Calendar")

      var table = TextTable(columns: [startCol, endCol, eventCol, calendarCol])

        let predicate = eventStore.predicateForEvents(withStart: now, end: later, calendars: calendars)
        let matchingEvents = eventStore.events(matching: predicate)
        for event in matchingEvents{
          table.addRow(values:[localDateFormatter.string(from:event.startDate!),localDateFormatter.string(from:event.endDate!),event.title!, event.calendar.source.title+"/"+event.calendar.title])
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
