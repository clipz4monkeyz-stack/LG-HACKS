//
//  Nutrition.swift
//  ALai
//
//  Created by Anwen Li on 10/5/25.
//

import Foundation

struct NutritionGoal: Codable {
    let calories: Int
    let water: Double // in liters
    let protein: Double // in grams
    let sugar: Double // in grams
    let sodium: Double // in mg
    let carb: Double // in grams
}

struct NutritionProgress: Codable {
    let calories: Int
    let water: Double // in liters
    let protein: Double // in grams
    let sugar: Double // in grams
    let sodium: Double // in mg
    let carb: Double // in grams
    let date: Date
    
    init(calories: Int = 0, water: Double = 0, protein: Double = 0, sugar: Double = 0, sodium: Double = 0, carb: Double = 0) {
        self.calories = calories
        self.water = water
        self.protein = protein
        self.sugar = sugar
        self.sodium = sodium
        self.carb = carb
        self.date = Date()
    }
}

extension NutritionGoal {
    static let sample = NutritionGoal(
        calories: 2500,
        water: 3.0,
        protein: 150.0,
        sugar: 50.0,
        sodium: 2300.0,
        carb: 300.0
    )
}

extension NutritionProgress {
    static let sample = NutritionProgress(
        calories: 1850,
        water: 2.2,
        protein: 95.0,
        sugar: 35.0,
        sodium: 1800.0,
        carb: 220.0
    )
    
    func progressPercentage(for goal: NutritionGoal) -> NutritionGoal {
        return NutritionGoal(
            calories: Int(Double(calories) / Double(goal.calories) * 100),
            water: (water / goal.water) * 100,
            protein: (protein / goal.protein) * 100,
            sugar: (sugar / goal.sugar) * 100,
            sodium: (sodium / goal.sodium) * 100,
            carb: (carb / goal.carb) * 100
        )
    }
}




