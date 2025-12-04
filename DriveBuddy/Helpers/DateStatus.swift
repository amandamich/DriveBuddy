////
////  DateStatus.swift
////  DriveBuddy
////
////  Created by student on 04/12/25.
////
//
//import Foundation
//
//enum StatusBadge {
//    case overdue
//    case dueSoon
//    case upToDate
//
//    var label: String {
//        switch self {
//        case .overdue: return "Overdue"
//        case .dueSoon: return "Due Soon"
//        case .upToDate: return "Up to Date"
//        }
//    }
//
//    var color: String {
//        switch self {
//        case .overdue: return "red"
//        case .dueSoon: return "yellow"
//        case .upToDate: return "green"
//        }
//    }
//}
//
//extension Date {
//    func getStatusBadge() -> StatusBadge {
//        
//        let now = Date()
//
//        if self < now {
//            return .overdue
//        }
//
//        let daysDiff = Calendar.current.dateComponents([.day], from: now, to: self).day ?? 0
//
//        if daysDiff <= 14 {
//            return .dueSoon
//        }
//
//        return .upToDate
//    }
//}
