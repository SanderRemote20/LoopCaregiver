//
//  Action.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 12/25/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation

public enum Action: Codable, Equatable {
    case temporaryScheduleOverride(OverrideAction)
    case cancelTemporaryOverride(OverrideCancelAction)
    case bolusEntry(BolusAction)
    case carbsEntry(CarbAction)
    case autobolus(AutobolusAction)
    case closedLoop(ClosedLoopAction)
    
    public var actionName: String {
        switch self {
        case .carbsEntry:
            return "Karbohydrater"
        case .bolusEntry:
            return "Bolus"
        case .cancelTemporaryOverride:
            return "Overstyring kansellert"
        case .temporaryScheduleOverride:
            return "Overstyring"
        case .closedLoop:
            return "Lukket Loop"
        case .autobolus:
            return "Autobolus"
        }
    }
    
    public var actionDetails: String {
        switch self {
        case .carbsEntry(let carbAction):
            return "\(carbAction.amountInGrams)g"
        case .bolusEntry(let bolusAction):
            return "\(bolusAction.amountInUnits)e"
        case .cancelTemporaryOverride:
            return ""
        case .temporaryScheduleOverride(let overrideAction):
            return "\(overrideAction.name)"
        case .autobolus(let autobolusAction):
            return autobolusAction.active ? "Aktiver" : "Deaktiver"
        case .closedLoop(let closeLoopAction):
            return closeLoopAction.active ? "Aktiver" : "Deaktiver"
        }
    }
}
