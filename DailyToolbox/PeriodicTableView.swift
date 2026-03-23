/*

Copyright 2020-2026 Marcus Deuß

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

//
//  PeriodicTableView.swift
//  DailyToolbox
//

import SwiftUI

// MARK: - Element Category

enum ElementCategory: String, CaseIterable {
    case alkaliMetal         = "Alkali Metal"
    case alkalineEarth       = "Alkaline Earth"
    case transitionMetal     = "Transition Metal"
    case postTransitionMetal = "Post-Transition Metal"
    case metalloid           = "Metalloid"
    case nonmetal            = "Nonmetal"
    case halogen             = "Halogen"
    case nobleGas            = "Noble Gas"
    case lanthanide          = "Lanthanide"
    case actinide            = "Actinide"

    var color: Color {
        switch self {
        case .alkaliMetal:         return Color(red: 0.96, green: 0.36, blue: 0.36)
        case .alkalineEarth:       return Color(red: 0.96, green: 0.63, blue: 0.25)
        case .transitionMetal:     return Color(red: 0.36, green: 0.62, blue: 0.92)
        case .postTransitionMetal: return Color(red: 0.55, green: 0.58, blue: 0.80)
        case .metalloid:           return Color(red: 0.20, green: 0.80, blue: 0.73)
        case .nonmetal:            return Color(red: 0.35, green: 0.88, blue: 0.50)
        case .halogen:             return Color(red: 0.73, green: 0.92, blue: 0.25)
        case .nobleGas:            return Color(red: 0.73, green: 0.38, blue: 0.93)
        case .lanthanide:          return Color(red: 0.22, green: 0.83, blue: 0.60)
        case .actinide:            return Color(red: 0.93, green: 0.58, blue: 0.22)
        }
    }
}

// MARK: - Element State

enum ElementState: String {
    case solid   = "Solid"
    case liquid  = "Liquid"
    case gas     = "Gas"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .solid:   return "square.fill"
        case .liquid:  return "drop.fill"
        case .gas:     return "wind"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Chemical Element

struct ChemElement: Identifiable, Hashable, Sendable {
    let atomicNumber: Int
    let symbol: String
    let name: String
    let germanName: String
    let atomicMass: Double
    let period: Int
    let group: Int          // 1-18 for main table, 0 for f-block
    let category: ElementCategory
    let state: ElementState
    let electronConfig: String
    let electronegativity: Double?

    var id: Int { atomicNumber }

    /// Column in the 18-column layout grid (1-18).
    var gridColumn: Int {
        if group > 0 { return group }
        if atomicNumber >= 58 && atomicNumber <= 71 { return atomicNumber - 54 }  // Ce(4)…Lu(17)
        if atomicNumber >= 90 && atomicNumber <= 103 { return atomicNumber - 86 } // Th(4)…Lr(17)
        return 1
    }

    /// Row in the layout grid (1-7 main table, 9 lanthanides, 10 actinides).
    var gridRow: Int {
        if group > 0 { return period }
        if atomicNumber >= 58 && atomicNumber <= 71 { return 9 }
        if atomicNumber >= 90 && atomicNumber <= 103 { return 10 }
        return period
    }

    static func == (lhs: ChemElement, rhs: ChemElement) -> Bool { lhs.atomicNumber == rhs.atomicNumber }
    func hash(into hasher: inout Hasher) { hasher.combine(atomicNumber) }
}

// MARK: - Element Database

extension ChemElement {

    /// Precomputed 2-D lookup: gridByPosition[row][col] → element (if present).
    static let gridByPosition: [Int: [Int: ChemElement]] = {
        var dict: [Int: [Int: ChemElement]] = [:]
        for el in all {
            let r = el.gridRow, c = el.gridColumn
            if dict[r] == nil { dict[r] = [:] }
            dict[r]![c] = el
        }
        return dict
    }()

    // swiftlint:disable line_length
    static let all: [ChemElement] = [
        // ── Period 1 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber:  1, symbol: "H",  name: "Hydrogen",      germanName: "Wasserstoff",   atomicMass:   1.0080, period: 1, group:  1, category: .nonmetal,           state: .gas,     electronConfig: "1s\u{00B9}",                              electronegativity: 2.20),
        ChemElement(atomicNumber:  2, symbol: "He", name: "Helium",        germanName: "Helium",         atomicMass:   4.0026, period: 1, group: 18, category: .nobleGas,           state: .gas,     electronConfig: "1s\u{00B2}",                              electronegativity: nil),
        // ── Period 2 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber:  3, symbol: "Li", name: "Lithium",       germanName: "Lithium",        atomicMass:   6.9410, period: 2, group:  1, category: .alkaliMetal,        state: .solid,   electronConfig: "[He] 2s\u{00B9}",                         electronegativity: 0.98),
        ChemElement(atomicNumber:  4, symbol: "Be", name: "Beryllium",     germanName: "Beryllium",      atomicMass:   9.0122, period: 2, group:  2, category: .alkalineEarth,      state: .solid,   electronConfig: "[He] 2s\u{00B2}",                         electronegativity: 1.57),
        ChemElement(atomicNumber:  5, symbol: "B",  name: "Boron",         germanName: "Bor",            atomicMass:  10.8100, period: 2, group: 13, category: .metalloid,          state: .solid,   electronConfig: "[He] 2s\u{00B2} 2p\u{00B9}",             electronegativity: 2.04),
        ChemElement(atomicNumber:  6, symbol: "C",  name: "Carbon",        germanName: "Kohlenstoff",    atomicMass:  12.0110, period: 2, group: 14, category: .nonmetal,           state: .solid,   electronConfig: "[He] 2s\u{00B2} 2p\u{00B2}",             electronegativity: 2.55),
        ChemElement(atomicNumber:  7, symbol: "N",  name: "Nitrogen",      germanName: "Stickstoff",     atomicMass:  14.0070, period: 2, group: 15, category: .nonmetal,           state: .gas,     electronConfig: "[He] 2s\u{00B2} 2p\u{00B3}",             electronegativity: 3.04),
        ChemElement(atomicNumber:  8, symbol: "O",  name: "Oxygen",        germanName: "Sauerstoff",     atomicMass:  15.9990, period: 2, group: 16, category: .nonmetal,           state: .gas,     electronConfig: "[He] 2s\u{00B2} 2p\u{2074}",             electronegativity: 3.44),
        ChemElement(atomicNumber:  9, symbol: "F",  name: "Fluorine",      germanName: "Fluor",          atomicMass:  18.9984, period: 2, group: 17, category: .halogen,            state: .gas,     electronConfig: "[He] 2s\u{00B2} 2p\u{2075}",             electronegativity: 3.98),
        ChemElement(atomicNumber: 10, symbol: "Ne", name: "Neon",          germanName: "Neon",           atomicMass:  20.1800, period: 2, group: 18, category: .nobleGas,           state: .gas,     electronConfig: "[He] 2s\u{00B2} 2p\u{2076}",             electronegativity: nil),
        // ── Period 3 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber: 11, symbol: "Na", name: "Sodium",        germanName: "Natrium",        atomicMass:  22.9898, period: 3, group:  1, category: .alkaliMetal,        state: .solid,   electronConfig: "[Ne] 3s\u{00B9}",                         electronegativity: 0.93),
        ChemElement(atomicNumber: 12, symbol: "Mg", name: "Magnesium",     germanName: "Magnesium",      atomicMass:  24.3050, period: 3, group:  2, category: .alkalineEarth,      state: .solid,   electronConfig: "[Ne] 3s\u{00B2}",                         electronegativity: 1.31),
        ChemElement(atomicNumber: 13, symbol: "Al", name: "Aluminium",     germanName: "Aluminium",      atomicMass:  26.9815, period: 3, group: 13, category: .postTransitionMetal, state: .solid,  electronConfig: "[Ne] 3s\u{00B2} 3p\u{00B9}",             electronegativity: 1.61),
        ChemElement(atomicNumber: 14, symbol: "Si", name: "Silicon",       germanName: "Silicium",       atomicMass:  28.0855, period: 3, group: 14, category: .metalloid,          state: .solid,   electronConfig: "[Ne] 3s\u{00B2} 3p\u{00B2}",             electronegativity: 1.90),
        ChemElement(atomicNumber: 15, symbol: "P",  name: "Phosphorus",    germanName: "Phosphor",       atomicMass:  30.9738, period: 3, group: 15, category: .nonmetal,           state: .solid,   electronConfig: "[Ne] 3s\u{00B2} 3p\u{00B3}",             electronegativity: 2.19),
        ChemElement(atomicNumber: 16, symbol: "S",  name: "Sulfur",        germanName: "Schwefel",       atomicMass:  32.0600, period: 3, group: 16, category: .nonmetal,           state: .solid,   electronConfig: "[Ne] 3s\u{00B2} 3p\u{2074}",             electronegativity: 2.58),
        ChemElement(atomicNumber: 17, symbol: "Cl", name: "Chlorine",      germanName: "Chlor",          atomicMass:  35.4500, period: 3, group: 17, category: .halogen,            state: .gas,     electronConfig: "[Ne] 3s\u{00B2} 3p\u{2075}",             electronegativity: 3.16),
        ChemElement(atomicNumber: 18, symbol: "Ar", name: "Argon",         germanName: "Argon",          atomicMass:  39.9480, period: 3, group: 18, category: .nobleGas,           state: .gas,     electronConfig: "[Ne] 3s\u{00B2} 3p\u{2076}",             electronegativity: nil),
        // ── Period 4 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber: 19, symbol: "K",  name: "Potassium",     germanName: "Kalium",         atomicMass:  39.0983, period: 4, group:  1, category: .alkaliMetal,        state: .solid,   electronConfig: "[Ar] 4s\u{00B9}",                         electronegativity: 0.82),
        ChemElement(atomicNumber: 20, symbol: "Ca", name: "Calcium",       germanName: "Calcium",        atomicMass:  40.0780, period: 4, group:  2, category: .alkalineEarth,      state: .solid,   electronConfig: "[Ar] 4s\u{00B2}",                         electronegativity: 1.00),
        ChemElement(atomicNumber: 21, symbol: "Sc", name: "Scandium",      germanName: "Scandium",       atomicMass:  44.9559, period: 4, group:  3, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{00B9} 4s\u{00B2}",             electronegativity: 1.36),
        ChemElement(atomicNumber: 22, symbol: "Ti", name: "Titanium",      germanName: "Titan",          atomicMass:  47.8670, period: 4, group:  4, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{00B2} 4s\u{00B2}",             electronegativity: 1.54),
        ChemElement(atomicNumber: 23, symbol: "V",  name: "Vanadium",      germanName: "Vanadium",       atomicMass:  50.9415, period: 4, group:  5, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{00B3} 4s\u{00B2}",             electronegativity: 1.63),
        ChemElement(atomicNumber: 24, symbol: "Cr", name: "Chromium",      germanName: "Chrom",          atomicMass:  51.9961, period: 4, group:  6, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{2075} 4s\u{00B9}",             electronegativity: 1.66),
        ChemElement(atomicNumber: 25, symbol: "Mn", name: "Manganese",     germanName: "Mangan",         atomicMass:  54.9380, period: 4, group:  7, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{2075} 4s\u{00B2}",             electronegativity: 1.55),
        ChemElement(atomicNumber: 26, symbol: "Fe", name: "Iron",          germanName: "Eisen",          atomicMass:  55.8450, period: 4, group:  8, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{2076} 4s\u{00B2}",             electronegativity: 1.83),
        ChemElement(atomicNumber: 27, symbol: "Co", name: "Cobalt",        germanName: "Kobalt",         atomicMass:  58.9332, period: 4, group:  9, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{2077} 4s\u{00B2}",             electronegativity: 1.88),
        ChemElement(atomicNumber: 28, symbol: "Ni", name: "Nickel",        germanName: "Nickel",         atomicMass:  58.6934, period: 4, group: 10, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{2078} 4s\u{00B2}",             electronegativity: 1.91),
        ChemElement(atomicNumber: 29, symbol: "Cu", name: "Copper",        germanName: "Kupfer",         atomicMass:  63.5460, period: 4, group: 11, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B9}",    electronegativity: 1.90),
        ChemElement(atomicNumber: 30, symbol: "Zn", name: "Zinc",          germanName: "Zink",           atomicMass:  65.3800, period: 4, group: 12, category: .transitionMetal,    state: .solid,   electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2}",    electronegativity: 1.65),
        ChemElement(atomicNumber: 31, symbol: "Ga", name: "Gallium",       germanName: "Gallium",        atomicMass:  69.7230, period: 4, group: 13, category: .postTransitionMetal, state: .solid,  electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2} 4p\u{00B9}", electronegativity: 1.81),
        ChemElement(atomicNumber: 32, symbol: "Ge", name: "Germanium",     germanName: "Germanium",      atomicMass:  72.6300, period: 4, group: 14, category: .metalloid,          state: .solid,   electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2} 4p\u{00B2}", electronegativity: 2.01),
        ChemElement(atomicNumber: 33, symbol: "As", name: "Arsenic",       germanName: "Arsen",          atomicMass:  74.9216, period: 4, group: 15, category: .metalloid,          state: .solid,   electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2} 4p\u{00B3}", electronegativity: 2.18),
        ChemElement(atomicNumber: 34, symbol: "Se", name: "Selenium",      germanName: "Selen",          atomicMass:  78.9710, period: 4, group: 16, category: .nonmetal,           state: .solid,   electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2} 4p\u{2074}", electronegativity: 2.55),
        ChemElement(atomicNumber: 35, symbol: "Br", name: "Bromine",       germanName: "Brom",           atomicMass:  79.9040, period: 4, group: 17, category: .halogen,            state: .liquid,  electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2} 4p\u{2075}", electronegativity: 2.96),
        ChemElement(atomicNumber: 36, symbol: "Kr", name: "Krypton",       germanName: "Krypton",        atomicMass:  83.7980, period: 4, group: 18, category: .nobleGas,           state: .gas,     electronConfig: "[Ar] 3d\u{00B9}\u{2070} 4s\u{00B2} 4p\u{2076}", electronegativity: 3.00),
        // ── Period 5 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber: 37, symbol: "Rb", name: "Rubidium",      germanName: "Rubidium",       atomicMass:  85.4678, period: 5, group:  1, category: .alkaliMetal,        state: .solid,   electronConfig: "[Kr] 5s\u{00B9}",                         electronegativity: 0.82),
        ChemElement(atomicNumber: 38, symbol: "Sr", name: "Strontium",     germanName: "Strontium",      atomicMass:  87.6200, period: 5, group:  2, category: .alkalineEarth,      state: .solid,   electronConfig: "[Kr] 5s\u{00B2}",                         electronegativity: 0.95),
        ChemElement(atomicNumber: 39, symbol: "Y",  name: "Yttrium",       germanName: "Yttrium",        atomicMass:  88.9058, period: 5, group:  3, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{00B9} 5s\u{00B2}",             electronegativity: 1.22),
        ChemElement(atomicNumber: 40, symbol: "Zr", name: "Zirconium",     germanName: "Zirconium",      atomicMass:  91.2240, period: 5, group:  4, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{00B2} 5s\u{00B2}",             electronegativity: 1.33),
        ChemElement(atomicNumber: 41, symbol: "Nb", name: "Niobium",       germanName: "Niob",           atomicMass:  92.9064, period: 5, group:  5, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{2074} 5s\u{00B9}",             electronegativity: 1.60),
        ChemElement(atomicNumber: 42, symbol: "Mo", name: "Molybdenum",    germanName: "Molybd\u{00E4}n", atomicMass: 95.9500, period: 5, group:  6, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{2075} 5s\u{00B9}",             electronegativity: 2.16),
        ChemElement(atomicNumber: 43, symbol: "Tc", name: "Technetium",    germanName: "Technetium",     atomicMass:  97.0000, period: 5, group:  7, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{2075} 5s\u{00B2}",             electronegativity: 1.90),
        ChemElement(atomicNumber: 44, symbol: "Ru", name: "Ruthenium",     germanName: "Ruthenium",      atomicMass: 101.0700, period: 5, group:  8, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{2077} 5s\u{00B9}",             electronegativity: 2.20),
        ChemElement(atomicNumber: 45, symbol: "Rh", name: "Rhodium",       germanName: "Rhodium",        atomicMass: 102.9055, period: 5, group:  9, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{2078} 5s\u{00B9}",             electronegativity: 2.28),
        ChemElement(atomicNumber: 46, symbol: "Pd", name: "Palladium",     germanName: "Palladium",      atomicMass: 106.4200, period: 5, group: 10, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{00B9}\u{2070}",                electronegativity: 2.20),
        ChemElement(atomicNumber: 47, symbol: "Ag", name: "Silver",        germanName: "Silber",         atomicMass: 107.8682, period: 5, group: 11, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B9}",    electronegativity: 1.93),
        ChemElement(atomicNumber: 48, symbol: "Cd", name: "Cadmium",       germanName: "Cadmium",        atomicMass: 112.4140, period: 5, group: 12, category: .transitionMetal,    state: .solid,   electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2}",    electronegativity: 1.69),
        ChemElement(atomicNumber: 49, symbol: "In", name: "Indium",        germanName: "Indium",         atomicMass: 114.8180, period: 5, group: 13, category: .postTransitionMetal, state: .solid,  electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2} 5p\u{00B9}", electronegativity: 1.78),
        ChemElement(atomicNumber: 50, symbol: "Sn", name: "Tin",           germanName: "Zinn",           atomicMass: 118.7100, period: 5, group: 14, category: .postTransitionMetal, state: .solid,  electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2} 5p\u{00B2}", electronegativity: 1.96),
        ChemElement(atomicNumber: 51, symbol: "Sb", name: "Antimony",      germanName: "Antimon",        atomicMass: 121.7600, period: 5, group: 15, category: .metalloid,          state: .solid,   electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2} 5p\u{00B3}", electronegativity: 2.05),
        ChemElement(atomicNumber: 52, symbol: "Te", name: "Tellurium",     germanName: "Tellur",         atomicMass: 127.6000, period: 5, group: 16, category: .metalloid,          state: .solid,   electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2} 5p\u{2074}", electronegativity: 2.10),
        ChemElement(atomicNumber: 53, symbol: "I",  name: "Iodine",        germanName: "Iod",            atomicMass: 126.9045, period: 5, group: 17, category: .halogen,            state: .solid,   electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2} 5p\u{2075}", electronegativity: 2.66),
        ChemElement(atomicNumber: 54, symbol: "Xe", name: "Xenon",         germanName: "Xenon",          atomicMass: 131.2930, period: 5, group: 18, category: .nobleGas,           state: .gas,     electronConfig: "[Kr] 4d\u{00B9}\u{2070} 5s\u{00B2} 5p\u{2076}", electronegativity: 2.60),
        // ── Period 6 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber: 55, symbol: "Cs", name: "Cesium",        germanName: "C\u{00E4}sium",  atomicMass: 132.9055, period: 6, group:  1, category: .alkaliMetal,        state: .solid,   electronConfig: "[Xe] 6s\u{00B9}",                         electronegativity: 0.79),
        ChemElement(atomicNumber: 56, symbol: "Ba", name: "Barium",        germanName: "Barium",         atomicMass: 137.3270, period: 6, group:  2, category: .alkalineEarth,      state: .solid,   electronConfig: "[Xe] 6s\u{00B2}",                         electronegativity: 0.89),
        ChemElement(atomicNumber: 57, symbol: "La", name: "Lanthanum",     germanName: "Lanthan",        atomicMass: 138.9055, period: 6, group:  3, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 5d\u{00B9} 6s\u{00B2}",             electronegativity: 1.10),
        // f-block (group = 0): Ce–Lu
        ChemElement(atomicNumber: 58, symbol: "Ce", name: "Cerium",        germanName: "Cer",            atomicMass: 140.1160, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9} 5d\u{00B9} 6s\u{00B2}",  electronegativity: 1.12),
        ChemElement(atomicNumber: 59, symbol: "Pr", name: "Praseodymium",  germanName: "Praseodym",      atomicMass: 140.9077, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B3} 6s\u{00B2}",             electronegativity: 1.13),
        ChemElement(atomicNumber: 60, symbol: "Nd", name: "Neodymium",     germanName: "Neodym",         atomicMass: 144.2420, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{2074} 6s\u{00B2}",             electronegativity: 1.14),
        ChemElement(atomicNumber: 61, symbol: "Pm", name: "Promethium",    germanName: "Promethium",     atomicMass: 145.0000, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{2075} 6s\u{00B2}",             electronegativity: nil),
        ChemElement(atomicNumber: 62, symbol: "Sm", name: "Samarium",      germanName: "Samarium",       atomicMass: 150.3600, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{2076} 6s\u{00B2}",             electronegativity: 1.17),
        ChemElement(atomicNumber: 63, symbol: "Eu", name: "Europium",      germanName: "Europium",       atomicMass: 151.9640, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{2077} 6s\u{00B2}",             electronegativity: nil),
        ChemElement(atomicNumber: 64, symbol: "Gd", name: "Gadolinium",    germanName: "Gadolinium",     atomicMass: 157.2500, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{2077} 5d\u{00B9} 6s\u{00B2}",  electronegativity: 1.20),
        ChemElement(atomicNumber: 65, symbol: "Tb", name: "Terbium",       germanName: "Terbium",        atomicMass: 158.9254, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{2079} 6s\u{00B2}",             electronegativity: nil),
        ChemElement(atomicNumber: 66, symbol: "Dy", name: "Dysprosium",    germanName: "Dysprosium",     atomicMass: 162.5000, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2070} 6s\u{00B2}",     electronegativity: 1.22),
        ChemElement(atomicNumber: 67, symbol: "Ho", name: "Holmium",       germanName: "Holmium",        atomicMass: 164.9303, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{00B9} 6s\u{00B2}",     electronegativity: 1.23),
        ChemElement(atomicNumber: 68, symbol: "Er", name: "Erbium",        germanName: "Erbium",         atomicMass: 167.2590, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{00B2} 6s\u{00B2}",     electronegativity: 1.24),
        ChemElement(atomicNumber: 69, symbol: "Tm", name: "Thulium",       germanName: "Thulium",        atomicMass: 168.9342, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{00B3} 6s\u{00B2}",     electronegativity: 1.25),
        ChemElement(atomicNumber: 70, symbol: "Yb", name: "Ytterbium",     germanName: "Ytterbium",      atomicMass: 173.0450, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 6s\u{00B2}",     electronegativity: nil),
        ChemElement(atomicNumber: 71, symbol: "Lu", name: "Lutetium",      germanName: "Lutetium",       atomicMass: 174.9668, period: 6, group:  0, category: .lanthanide,         state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9} 6s\u{00B2}", electronegativity: 1.27),
        // Back to main table, period 6
        ChemElement(atomicNumber: 72, symbol: "Hf", name: "Hafnium",       germanName: "Hafnium",        atomicMass: 178.4860, period: 6, group:  4, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B2} 6s\u{00B2}", electronegativity: 1.30),
        ChemElement(atomicNumber: 73, symbol: "Ta", name: "Tantalum",      germanName: "Tantal",         atomicMass: 180.9479, period: 6, group:  5, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B3} 6s\u{00B2}", electronegativity: 1.50),
        ChemElement(atomicNumber: 74, symbol: "W",  name: "Tungsten",      germanName: "Wolfram",        atomicMass: 183.8400, period: 6, group:  6, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{2074} 6s\u{00B2}", electronegativity: 2.36),
        ChemElement(atomicNumber: 75, symbol: "Re", name: "Rhenium",       germanName: "Rhenium",        atomicMass: 186.2070, period: 6, group:  7, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{2075} 6s\u{00B2}", electronegativity: 1.90),
        ChemElement(atomicNumber: 76, symbol: "Os", name: "Osmium",        germanName: "Osmium",         atomicMass: 190.2300, period: 6, group:  8, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{2076} 6s\u{00B2}", electronegativity: 2.20),
        ChemElement(atomicNumber: 77, symbol: "Ir", name: "Iridium",       germanName: "Iridium",        atomicMass: 192.2170, period: 6, group:  9, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{2077} 6s\u{00B2}", electronegativity: 2.20),
        ChemElement(atomicNumber: 78, symbol: "Pt", name: "Platinum",      germanName: "Platin",         atomicMass: 195.0840, period: 6, group: 10, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{2079} 6s\u{00B9}", electronegativity: 2.28),
        ChemElement(atomicNumber: 79, symbol: "Au", name: "Gold",          germanName: "Gold",           atomicMass: 196.9666, period: 6, group: 11, category: .transitionMetal,    state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B9}", electronegativity: 2.54),
        ChemElement(atomicNumber: 80, symbol: "Hg", name: "Mercury",       germanName: "Quecksilber",    atomicMass: 200.5920, period: 6, group: 12, category: .transitionMetal,    state: .liquid,  electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2}", electronegativity: 2.00),
        ChemElement(atomicNumber: 81, symbol: "Tl", name: "Thallium",      germanName: "Thallium",       atomicMass: 204.3833, period: 6, group: 13, category: .postTransitionMetal, state: .solid,  electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2} 6p\u{00B9}", electronegativity: 1.62),
        ChemElement(atomicNumber: 82, symbol: "Pb", name: "Lead",          germanName: "Blei",           atomicMass: 207.2000, period: 6, group: 14, category: .postTransitionMetal, state: .solid,  electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2} 6p\u{00B2}", electronegativity: 2.33),
        ChemElement(atomicNumber: 83, symbol: "Bi", name: "Bismuth",       germanName: "Bismut",         atomicMass: 208.9804, period: 6, group: 15, category: .postTransitionMetal, state: .solid,  electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2} 6p\u{00B3}", electronegativity: 2.02),
        ChemElement(atomicNumber: 84, symbol: "Po", name: "Polonium",      germanName: "Polonium",       atomicMass: 209.0000, period: 6, group: 16, category: .postTransitionMetal, state: .solid,  electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2} 6p\u{2074}", electronegativity: 2.00),
        ChemElement(atomicNumber: 85, symbol: "At", name: "Astatine",      germanName: "Astat",          atomicMass: 210.0000, period: 6, group: 17, category: .halogen,            state: .solid,   electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2} 6p\u{2075}", electronegativity: 2.20),
        ChemElement(atomicNumber: 86, symbol: "Rn", name: "Radon",         germanName: "Radon",          atomicMass: 222.0000, period: 6, group: 18, category: .nobleGas,           state: .gas,     electronConfig: "[Xe] 4f\u{00B9}\u{2074} 5d\u{00B9}\u{2070} 6s\u{00B2} 6p\u{2076}", electronegativity: nil),
        // ── Period 7 ───────────────────────────────────────────────────────────
        ChemElement(atomicNumber: 87, symbol: "Fr", name: "Francium",      germanName: "Francium",       atomicMass: 223.0000, period: 7, group:  1, category: .alkaliMetal,        state: .solid,   electronConfig: "[Rn] 7s\u{00B9}",                         electronegativity: 0.70),
        ChemElement(atomicNumber: 88, symbol: "Ra", name: "Radium",        germanName: "Radium",         atomicMass: 226.0000, period: 7, group:  2, category: .alkalineEarth,      state: .solid,   electronConfig: "[Rn] 7s\u{00B2}",                         electronegativity: 0.90),
        ChemElement(atomicNumber: 89, symbol: "Ac", name: "Actinium",      germanName: "Actinium",       atomicMass: 227.0000, period: 7, group:  3, category: .actinide,           state: .solid,   electronConfig: "[Rn] 6d\u{00B9} 7s\u{00B2}",             electronegativity: 1.10),
        // f-block (group = 0): Th–Lr
        ChemElement(atomicNumber: 90, symbol: "Th", name: "Thorium",       germanName: "Thorium",        atomicMass: 232.0381, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 6d\u{00B2} 7s\u{00B2}",             electronegativity: 1.30),
        ChemElement(atomicNumber: 91, symbol: "Pa", name: "Protactinium",  germanName: "Protactinium",   atomicMass: 231.0359, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B2} 6d\u{00B9} 7s\u{00B2}",  electronegativity: 1.50),
        ChemElement(atomicNumber: 92, symbol: "U",  name: "Uranium",       germanName: "Uran",           atomicMass: 238.0289, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B3} 6d\u{00B9} 7s\u{00B2}",  electronegativity: 1.38),
        ChemElement(atomicNumber: 93, symbol: "Np", name: "Neptunium",     germanName: "Neptunium",      atomicMass: 237.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{2074} 6d\u{00B9} 7s\u{00B2}",  electronegativity: 1.36),
        ChemElement(atomicNumber: 94, symbol: "Pu", name: "Plutonium",     germanName: "Plutonium",      atomicMass: 244.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{2076} 7s\u{00B2}",             electronegativity: 1.28),
        ChemElement(atomicNumber: 95, symbol: "Am", name: "Americium",     germanName: "Americium",      atomicMass: 243.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{2077} 7s\u{00B2}",             electronegativity: 1.30),
        ChemElement(atomicNumber: 96, symbol: "Cm", name: "Curium",        germanName: "Curium",         atomicMass: 247.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{2077} 6d\u{00B9} 7s\u{00B2}",  electronegativity: 1.30),
        ChemElement(atomicNumber: 97, symbol: "Bk", name: "Berkelium",     germanName: "Berkelium",      atomicMass: 247.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{2079} 7s\u{00B2}",             electronegativity: 1.30),
        ChemElement(atomicNumber: 98, symbol: "Cf", name: "Californium",   germanName: "Californium",    atomicMass: 251.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B9}\u{2070} 7s\u{00B2}",     electronegativity: 1.30),
        ChemElement(atomicNumber: 99, symbol: "Es", name: "Einsteinium",   germanName: "Einsteinium",    atomicMass: 252.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B9}\u{00B9} 7s\u{00B2}",     electronegativity: 1.30),
        ChemElement(atomicNumber: 100, symbol: "Fm", name: "Fermium",      germanName: "Fermium",        atomicMass: 257.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B9}\u{00B2} 7s\u{00B2}",     electronegativity: 1.30),
        ChemElement(atomicNumber: 101, symbol: "Md", name: "Mendelevium",  germanName: "Mendelevium",    atomicMass: 258.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B9}\u{00B3} 7s\u{00B2}",     electronegativity: 1.30),
        ChemElement(atomicNumber: 102, symbol: "No", name: "Nobelium",     germanName: "Nobelium",       atomicMass: 259.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B9}\u{2074} 7s\u{00B2}",     electronegativity: 1.30),
        ChemElement(atomicNumber: 103, symbol: "Lr", name: "Lawrencium",   germanName: "Lawrencium",     atomicMass: 266.0000, period: 7, group:  0, category: .actinide,           state: .solid,   electronConfig: "[Rn] 5f\u{00B9}\u{2074} 7s\u{00B2} 7p\u{00B9}", electronegativity: nil),
        // Back to main table, period 7
        ChemElement(atomicNumber: 104, symbol: "Rf", name: "Rutherfordium", germanName: "Rutherfordium", atomicMass: 267.0000, period: 7, group:  4, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B2} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 105, symbol: "Db", name: "Dubnium",      germanName: "Dubnium",        atomicMass: 268.0000, period: 7, group:  5, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B3} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 106, symbol: "Sg", name: "Seaborgium",   germanName: "Seaborgium",     atomicMass: 269.0000, period: 7, group:  6, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{2074} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 107, symbol: "Bh", name: "Bohrium",      germanName: "Bohrium",        atomicMass: 270.0000, period: 7, group:  7, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{2075} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 108, symbol: "Hs", name: "Hassium",      germanName: "Hassium",        atomicMass: 277.0000, period: 7, group:  8, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{2076} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 109, symbol: "Mt", name: "Meitnerium",   germanName: "Meitnerium",     atomicMass: 278.0000, period: 7, group:  9, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{2077} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 110, symbol: "Ds", name: "Darmstadtium", germanName: "Darmstadtium",  atomicMass: 281.0000, period: 7, group: 10, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{2078} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 111, symbol: "Rg", name: "Roentgenium",  germanName: "Roentgenium",    atomicMass: 282.0000, period: 7, group: 11, category: .transitionMetal,    state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B9}", electronegativity: nil),
        ChemElement(atomicNumber: 112, symbol: "Cn", name: "Copernicium",  germanName: "Copernicium",    atomicMass: 285.0000, period: 7, group: 12, category: .transitionMetal,    state: .gas,     electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 113, symbol: "Nh", name: "Nihonium",     germanName: "Nihonium",       atomicMass: 286.0000, period: 7, group: 13, category: .postTransitionMetal, state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2} 7p\u{00B9}", electronegativity: nil),
        ChemElement(atomicNumber: 114, symbol: "Fl", name: "Flerovium",    germanName: "Flerovium",      atomicMass: 289.0000, period: 7, group: 14, category: .postTransitionMetal, state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2} 7p\u{00B2}", electronegativity: nil),
        ChemElement(atomicNumber: 115, symbol: "Mc", name: "Moscovium",    germanName: "Moscovium",      atomicMass: 290.0000, period: 7, group: 15, category: .postTransitionMetal, state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2} 7p\u{00B3}", electronegativity: nil),
        ChemElement(atomicNumber: 116, symbol: "Lv", name: "Livermorium",  germanName: "Livermorium",    atomicMass: 293.0000, period: 7, group: 16, category: .postTransitionMetal, state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2} 7p\u{2074}", electronegativity: nil),
        ChemElement(atomicNumber: 117, symbol: "Ts", name: "Tennessine",   germanName: "Tennessine",     atomicMass: 294.0000, period: 7, group: 17, category: .halogen,            state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2} 7p\u{2075}", electronegativity: nil),
        ChemElement(atomicNumber: 118, symbol: "Og", name: "Oganesson",    germanName: "Oganesson",      atomicMass: 294.0000, period: 7, group: 18, category: .nobleGas,           state: .unknown, electronConfig: "[Rn] 5f\u{00B9}\u{2074} 6d\u{00B9}\u{2070} 7s\u{00B2} 7p\u{2076}", electronegativity: nil),
    ]
    // swiftlint:enable line_length
}

// MARK: - Element Cell View

struct ElementCellView: View {
    let element: ChemElement
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Text("\(element.atomicNumber)")
                    .font(.system(size: max(6.5, width * 0.185)))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer(minLength: 0)
            }
            Text(element.symbol)
                .font(.system(size: max(11, width * 0.355), weight: .bold))
                .foregroundStyle(.white)
            Text(element.name)
                .font(.system(size: max(5, width * 0.138)))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, max(2, width * 0.06))
        .padding(.vertical, max(2, height * 0.05))
        .frame(width: width, height: height)
        .glassEffect(.regular.tint(element.category.color.opacity(0.28)), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Element Detail View

struct ElementDetailView: View {
    let element: ChemElement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                detailBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        symbolHero
                        GlassEffectContainer { infoGrid }
                        GlassEffectContainer { configCard }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(element.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.glass)
                }
            }
        }
    }

    private var detailBackground: some View {
        LinearGradient(
            colors: [
                element.category.color.opacity(0.35),
                Color(red: 0.05, green: 0.06, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var symbolHero: some View {
        ZStack {
            Circle()
                .fill(element.category.color.opacity(0.22))
                .frame(width: 140, height: 140)
                .glassEffect(.regular.tint(element.category.color.opacity(0.35)), in: Circle())
            VStack(spacing: 2) {
                Text("\(element.atomicNumber)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(element.symbol)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                Text(element.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
    }

    private var infoGrid: some View {
        VStack(spacing: 0) {
            detailRow(label: "German Name",    value: element.germanName)
            Divider().background(.white.opacity(0.15))
            detailRow(label: "Atomic Mass",    value: String(format: "%.4f u", element.atomicMass))
            Divider().background(.white.opacity(0.15))
            detailRow(label: "Period",         value: "\(element.period)")
            Divider().background(.white.opacity(0.15))
            detailRow(label: "Group",          value: element.group == 0 ? NSLocalizedString("f-block", comment: "") : "\(element.group)")
            Divider().background(.white.opacity(0.15))
            detailRow(label: "Category",       value: NSLocalizedString(element.category.rawValue, comment: ""), accent: element.category.color)
            Divider().background(.white.opacity(0.15))
            detailRow(label: "State (25 °C)",  value: NSLocalizedString(element.state.rawValue, comment: ""), icon: element.state.icon)
            if let en = element.electronegativity {
                Divider().background(.white.opacity(0.15))
                detailRow(label: "Electronegativity", value: String(format: "%.2f (Pauling)", en))
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    private var configCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Electron Configuration", systemImage: "atom")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))
            Text(element.electronConfig)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func detailRow(label: LocalizedStringKey, value: String, accent: Color? = nil, icon: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            if let icon {
                Label(value, systemImage: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            } else if let accent {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accent)
                        .frame(width: 10, height: 10)
                    Text(value)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
            } else {
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 9)
    }
}

// MARK: - Category Legend View

struct CategoryLegendView: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(ElementCategory.allCases, id: \.self) { cat in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(cat.color)
                            .frame(width: 11, height: 11)
                        Text(LocalizedStringKey(cat.rawValue))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Periodic Table Grid View

struct PeriodicTableGridView: View {
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let spacing: CGFloat
    let onSelect: (ChemElement) -> Void

    private let mainRows  = Array(1...7)
    private let fRows     = [9, 10]
    private let columns   = Array(1...18)

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(mainRows, id: \.self) { row in
                gridRow(row)
            }
            Spacer(minLength: 10)
            fBlockLabel
            ForEach(fRows, id: \.self) { row in
                gridRow(row)
            }
        }
        .padding(14)
    }

    private var fBlockLabel: some View {
        HStack(spacing: 14) {
            Text("Lanthanides (57\u{2013}71)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
            Text("Actinides (89\u{2013}103)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 6)
    }

    private func gridRow(_ row: Int) -> some View {
        HStack(spacing: spacing) {
            ForEach(columns, id: \.self) { col in
                if let element = ChemElement.gridByPosition[row]?[col] {
                    Button {
                        onSelect(element)
                    } label: {
                        ElementCellView(element: element, width: cellWidth, height: cellHeight)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(element.name), symbol \(element.symbol), atomic number \(element.atomicNumber)")
                } else {
                    Color.clear
                        .frame(width: cellWidth, height: cellHeight)
                }
            }
        }
    }
}

// MARK: - Search Results View

struct ElementSearchResultsView: View {
    let query: String
    let onSelect: (ChemElement) -> Void

    private var matches: [ChemElement] {
        let q = query.lowercased()
        return ChemElement.all.filter {
            $0.name.lowercased().contains(q)
            || $0.germanName.lowercased().contains(q)
            || $0.symbol.lowercased().contains(q)
            || String($0.atomicNumber) == query
        }.sorted { $0.atomicNumber < $1.atomicNumber }
    }

    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 10)]

    var body: some View {
        if matches.isEmpty {
            ContentUnavailableView.search
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(matches) { element in
                    Button {
                        onSelect(element)
                    } label: {
                        searchCard(element)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(element.name), \(element.symbol), atomic number \(element.atomicNumber)")
                }
            }
            .padding(14)
        }
    }

    private func searchCard(_ element: ChemElement) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.category.color.opacity(0.3))
                    .frame(width: 42, height: 48)
                    .glassEffect(.regular.tint(element.category.color.opacity(0.3)), in: RoundedRectangle(cornerRadius: 8))
                VStack(spacing: 1) {
                    Text("\(element.atomicNumber)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(element.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(element.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(element.germanName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text(element.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(element.category.color)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .glassEffect(.regular.tint(element.category.color.opacity(0.15)), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Periodic Table View

struct PeriodicTableView: View {
    @State private var searchText = ""
    @State private var selectedElement: ChemElement?
    @State private var zoomScale: CGFloat = 1.0
    @State private var molarFormula: String = ""
    @State private var molarResult: MolarMassResult? = nil
    @State private var molarError: String? = nil

    private let baseCellWidth:  CGFloat = 44
    private let baseCellHeight: CGFloat = 52
    private let cellSpacing:    CGFloat = 3

    private var cellWidth:  CGFloat { baseCellWidth  * zoomScale }
    private var cellHeight: CGFloat { baseCellHeight * zoomScale }

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                if searchText.isEmpty {
                    ScrollView([.horizontal, .vertical]) {
                        PeriodicTableGridView(
                            cellWidth: cellWidth,
                            cellHeight: cellHeight,
                            spacing: cellSpacing,
                            onSelect: { selectedElement = $0 }
                        )
                    }
                    Divider().background(.white.opacity(0.15))
                    CategoryLegendView()
                    Divider().background(.white.opacity(0.15))
                    molarMassCard
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                    Divider().background(.white.opacity(0.15))
                    zoomControl
                } else {
                    ScrollView {
                        ElementSearchResultsView(
                            query: searchText,
                            onSelect: { selectedElement = $0 }
                        )
                    }
                }
            }
        }
        .background { tableBackground.ignoresSafeArea() }
        .navigationTitle("Periodic Table")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: Text("Name, symbol, or atomic number"))
        .sheet(item: $selectedElement) { element in
            ElementDetailView(element: element)
        }
    }

    private var zoomControl: some View {
        HStack(spacing: 10) {
            Image(systemName: "minus.magnifyingglass")
                .foregroundStyle(.white.opacity(0.65))
            Slider(value: $zoomScale, in: 0.60...1.55)
                .tint(.white.opacity(0.75))
            Image(systemName: "plus.magnifyingglass")
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Molar Mass Calculator

    private struct MolarMassResult {
        struct Component {
            let symbol: String
            let name: String
            let count: Int
            let massContribution: Double
        }
        let formula: String
        let totalMass: Double
        let components: [Component]
    }

    /// Parses a chemical formula string and returns element symbol → count map.
    /// Handles: H2O, NaCl, C6H12O6, Ca(OH)2, Fe2(SO4)3, Al2(SO4)3
    private func parseFormula(_ formula: String) -> [String: Int]? {
        var stack: [[String: Int]] = [[:]]
        var i = formula.startIndex

        while i < formula.endIndex {
            let ch = formula[i]

            if ch == "(" {
                stack.append([:])
                i = formula.index(after: i)
            } else if ch == ")" {
                guard stack.count > 1 else { return nil }
                i = formula.index(after: i)
                var numStr = ""
                while i < formula.endIndex, formula[i].isNumber { numStr.append(formula[i]); i = formula.index(after: i) }
                let mult = Int(numStr) ?? 1
                let top = stack.removeLast()
                for (sym, cnt) in top { stack[stack.count - 1][sym, default: 0] += cnt * mult }
            } else if ch.isUppercase {
                var sym = String(ch)
                i = formula.index(after: i)
                while i < formula.endIndex, formula[i].isLowercase { sym.append(formula[i]); i = formula.index(after: i) }
                var numStr = ""
                while i < formula.endIndex, formula[i].isNumber { numStr.append(formula[i]); i = formula.index(after: i) }
                let count = Int(numStr) ?? 1
                stack[stack.count - 1][sym, default: 0] += count
            } else {
                return nil
            }
        }
        guard stack.count == 1 else { return nil }
        return stack[0].isEmpty ? nil : stack[0]
    }

    private func computeMolarMass() {
        let trimmed = molarFormula.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { molarResult = nil; molarError = nil; return }

        guard let counts = parseFormula(trimmed) else {
            molarResult = nil
            molarError = NSLocalizedString("Invalid formula", comment: "")
            return
        }

        let lookup = Dictionary(uniqueKeysWithValues: ChemElement.all.map { ($0.symbol, $0) })
        var components: [MolarMassResult.Component] = []
        var totalMass = 0.0

        for (sym, count) in counts.sorted(by: { $0.key < $1.key }) {
            guard let elem = lookup[sym] else {
                molarError = String(format: NSLocalizedString("Unknown element: %@", comment: ""), sym)
                molarResult = nil
                return
            }
            let contribution = elem.atomicMass * Double(count)
            totalMass += contribution
            components.append(.init(symbol: sym, name: elem.name, count: count, massContribution: contribution))
        }

        molarResult = MolarMassResult(formula: trimmed, totalMass: totalMass, components: components)
        molarError = nil
    }

    private var molarMassCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.20, green: 0.75, blue: 0.55))
                Text("Molar Mass Calculator")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.65))
                Spacer()
                if molarResult != nil || molarError != nil {
                    Button {
                        molarFormula = ""
                        molarResult = nil
                        molarError = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.primary.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                TextField("H₂O, NaCl, C₆H₁₂O₆…", text: $molarFormula)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.primary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: molarFormula) { _, _ in computeMolarMass() }
                if !molarFormula.isEmpty {
                    Button { UIPasteboard.general.string = String(format: "%.4f g/mol", molarResult?.totalMass ?? 0) } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.55))
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))

            if let err = molarError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.80))
            } else if let res = molarResult {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.4f", res.totalMass))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.20, green: 0.75, blue: 0.55))
                    Text("g/mol")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.55))
                }
                .contentTransition(.numericText())

                if res.components.count > 1 {
                    VStack(spacing: 4) {
                        ForEach(res.components, id: \.symbol) { comp in
                            HStack {
                                Text(comp.symbol)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color(red: 0.20, green: 0.75, blue: 0.55))
                                    .frame(width: 30, alignment: .leading)
                                Text(comp.name)
                                    .font(.caption)
                                    .foregroundStyle(Color.primary.opacity(0.55))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if comp.count > 1 {
                                    Text("×\(comp.count)")
                                        .font(.caption)
                                        .foregroundStyle(Color.primary.opacity(0.45))
                                }
                                Text(String(format: "%.4f", comp.massContribution))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Color.primary.opacity(0.65))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    }

    private var tableBackground: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.04, green: 0.10, blue: 0.20), Color(red: 0.05, green: 0.14, blue: 0.24), Color(red: 0.04, green: 0.10, blue: 0.20),
                Color(red: 0.05, green: 0.12, blue: 0.22), Color(red: 0.08, green: 0.18, blue: 0.30), Color(red: 0.05, green: 0.12, blue: 0.22),
                Color(red: 0.03, green: 0.08, blue: 0.18), Color(red: 0.05, green: 0.12, blue: 0.22), Color(red: 0.03, green: 0.08, blue: 0.18)
            ]
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PeriodicTableView()
    }
}
