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

let statuses: [String] = ["scheduled", "confirmed", "tentative", "canceled"]

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
    @Key("-s", "--start")
    var start: String?
    @Key("-e", "--end")
    var end: String?
    @Key("-t", "--title")
    var title: String?
    var defaultValue: String = ""
    func execute() throws {
        let calendars = eventStore.calendars(for: .event)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.date(from: start!)
        let endDate = dateFormatter.date(from: end!)
        
        print(start!)
        print(end!)
        print(startDate)
        print(endDate)
        
        let predicate = eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: calendars)
        let matchingEvents = eventStore.events(matching: predicate)
        for event in matchingEvents{
            if event.title!.localizedCaseInsensitiveContains(title!){
                print(event.title!, event.eventIdentifier)
            }
        }
    }
}

class ListEventsCommand: Command {
    let name = "events"
    
    @Key("-n", "--next")
    var next: Int?
    
    @Key("-s", "--start")
    var start: String?
    
    @Key("-o", "--output")
    var outputFormat: String?
    
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
        let next = next ?? 0
        let calendars = eventStore.calendars(for: .event)
        
        let endOfToday = Calendar.current.date(bySettingHour:23, minute:59, second: 59, of: startDate!) ?? startDate!
        let later = Calendar.current.date(byAdding: .day, value: next, to:endOfToday) ?? startDate!
        
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd hh:mm a EEEEE"
        
        let predicate = eventStore.predicateForEvents(withStart: startDate!, end: later, calendars: calendars)
        let matchingEvents = eventStore.events(matching: predicate)
        
        var output = "table"
        if let outputFormat = outputFormat {
            if outputFormat.count == 0 {
                output = "table"
            } else {
                output = outputFormat
            }
        }
        
        if output == "table"{
            let eventCol = TextTableColumn(header: "Event")
            let startCol = TextTableColumn(header: "Start")
            let endCol = TextTableColumn(header: "End")
            let statusCol = TextTableColumn(header: "Status")
            let calendarCol = TextTableColumn(header: "Calendar")
            var table = TextTable(columns: [startCol, endCol, eventCol, statusCol, calendarCol])
            for event in matchingEvents{
                table.addRow(values:[localDateFormatter.string(from:event.startDate!),localDateFormatter.string(from:event.endDate!),event.title!, statuses[event.status.rawValue],
                                     event.calendar.source.title+"/"+event.calendar.title])
            }
            let tableString = table.render()
            print(tableString)
        }else if output == "report" {
            for event in matchingEvents{
                print(event.title!)
                print("  \(localDateFormatter.string(from:event.startDate!))-\(localDateFormatter.string(from:event.endDate!)), \(statuses[event.status.rawValue]), \(event.eventIdentifier!)")
                if event.organizer != nil{
                    let emptyString = ""
                    print("  Organizer: \(event.organizer!.name ?? emptyString)")
                }
                if event.attendees != nil{
                    print("  Attendees: ", terminator: "")
                    for attendee in event.attendees!{
                        print("\(attendee.name!)", terminator: ", ")
                    }
                    print("")
                }
                print("--")
            }
        }
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
