//(C) 2022 Paco Gomez

import EventKit
import SwiftCLI
import Rainbow

import SwiftyTextTable

func completion(granted: Bool, error: Error!){
    // print("granted: \(granted)")
}

let calendar = Calendar.autoupdatingCurrent

EKEventStore().requestAccess(to:.event, completion: completion)

let eventStore = EKEventStore()

let sources = eventStore.sources

let statuses: [String] = ["scheduled", "confirmed", "tentative", "canceled"]

let dayFormatter = DateFormatter()
let timeFormatter = DateFormatter()
dayFormatter.dateFormat = "yyyy-MM-dd EEEEE"
timeFormatter.dateFormat = "hh:mm a"

class GetGroup: CommandGroup {
    let name = "list"
    let children: [Routable] = [ListEventsCommand(), ListCalendarsCommand()]
    let shortDescription = "list"
}

class AddGroup: CommandGroup {
    let name = "add"
    let children: [Routable] = [AddEventCommand()]
    let shortDescription = "add"
}

class AddEventCommand: Command {
    let name = "event"
    @Param var source: String
    @Param var calendar: String
    @Param var eventTitle: String
    @Param var startDate: String
    @Key("-m", "--minutes")
    var minutes: Int?
    func execute() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let calendar = getCalendar(source: source, calendar: calendar)
        if calendar == nil {
            stderr <<< "calendar not found".red
            return
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = eventTitle
        event.startDate = dateFormatter.date(from: startDate)
        event.endDate = event.startDate + (60 * (Double(minutes ?? 60)))
        do {
            if #available(macOS 10.14, *) {
                try eventStore.save(event, span: .thisEvent)
                printEvent(event: event)
                stdout <<< "event added".blue
            } else {
                stderr <<< "not supported".red
            }
        }
        catch {
            print("Error saving event in calendar".red)
        }
    }
}

class DelGroup: CommandGroup {
    let name = "del"
    let children: [Routable] = [DelEventCommand()]
    let shortDescription = "del"
}

class DelEventCommand: Command {
    let name = "event"
    
    @Param var eventIdentifier: String
    func execute() throws {
        let event = eventStore.event(withIdentifier: eventIdentifier)
        if event != nil {
            printEvent(event: event!)
            print("delete event \"\(event!.title.blue)\"? (" + "Y".bold + "es/" + "N".bold + "o): ", terminator: "")
            
            let response = readLine(strippingNewline: true)!
            if response.compare("y", options: .caseInsensitive) == .orderedSame {
                do {
                    try eventStore.remove(event!, span: .thisEvent, commit: true)
                    stdout <<< "event deleted".blue
                }
                catch let error {
                    print(error)
                }
            } else{
                stdout <<< "event not deleted"
            }
        }else{
            Term.stderr <<< "event not found".red
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
            let dayCol = TextTableColumn(header: "Date")
            let eventCol = TextTableColumn(header: "Event".blue)
            let startCol = TextTableColumn(header: "Start".green)
            let endCol = TextTableColumn(header: "End".red)
            let statusCol = TextTableColumn(header: "Status")
            let calendarCol = TextTableColumn(header: "Calendar")
            let idCol = TextTableColumn(header: "Id")
            var table = TextTable(columns: [dayCol, startCol, endCol, eventCol, statusCol, calendarCol, idCol])
            for event in matchingEvents{
                table.addRow(values:[dayFormatter.string(from: event.startDate!), timeFormatter.string(from:event.startDate!).green, timeFormatter.string(from:event.endDate!).red, event.title!.blue, statuses[event.status.rawValue],
                                     event.calendar.source.title+"/"+event.calendar.title,
                                     event.eventIdentifier])
            }
            if !matchingEvents.isEmpty{
                print(table.render())
            }
        }else if output == "report" {
            for event in matchingEvents{
                print(event.title!.blue)
                print("  \(timeFormatter.string(from:event.startDate!).green) - \(timeFormatter.string(from:event.endDate!).red), \(statuses[event.status.rawValue]), \(event.eventIdentifier!), \(event.calendarItemExternalIdentifier!)")
                if event.organizer != nil{
                    let emptyString = ""
                    print("  Organizer: \(event.organizer!.name ?? emptyString)")
                }
                if event.attendees != nil{
                    print("  Attendees: ", terminator: "")
                    for (n, attendee) in event.attendees!.enumerated(){
                        if (n>0){
                            print(", ", terminator: "")
                        }
                        print("\(attendee.name!)", terminator: "")
                    }
                    print("")
                }
                print("")
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

func getCalendar(source: String, calendar: String) -> EKCalendar? {
    for (_, s) in sources.enumerated(){
        if s.title.compare(source, options: .caseInsensitive) == .orderedSame {
            for (_, c) in s.calendars(for: .event).enumerated(){
                if c.title.compare(calendar, options: .caseInsensitive) == .orderedSame {
                    return c
                }
            }
        }
    }
    return nil
}

func printEvent(event: EKEvent){
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    print("Calendar: \(event.calendar!.source!.title)/\(event.calendar!.title)")
    print("Event:    \(event.title!.blue)")
    print("From:     \(dateFormatter.string(from: event.startDate!).green)")
    print("To:       \(dateFormatter.string(from: event.endDate!).red)")
}

let fastiCli = CLI(name: "fasti")
fastiCli.commands = [GetGroup(), AddGroup(), DelGroup()]
fastiCli.go()
