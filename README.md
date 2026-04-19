# BioMesh – CareKit Final Project

## Overview

BioMesh is a CareKit app that studies how caffeine habits, hydration, recovery, and stress patterns relate to each other over time. The app combines self-reported behaviors with HealthKit signals so users can see more than one isolated metric.

## 7 Tasks Counted for the Assignment

These are the 7 tasks I am counting toward the project requirement. Five are new custom `OCKTask`s, and two are new non-steps `OCKHealthKitTask`s.

1. **Caffeine Intake** (`biomesh.caffeine`)
   Button log for every caffeinated drink during the day.
2. **Hydration Checkpoint** (`biomesh.water`)
   Button log that appears twice per day to confirm the user stayed hydrated.
3. **Anxiety Check-in** (`biomesh.anxiety`)
   Button log for noticeable anxiety episodes.
4. **Evening Wind-Down** (`biomesh.sleep.hygiene`)
   Custom checklist card for pre-sleep habits.
5. **Weekly Pattern Reflection** (`biomesh.weekly.reflection`)
   Survey task asking whether the user stopped caffeine by 2 PM and how manageable stress felt that week.
6. **Heart Rate Trend** (`biomesh.heart.rate`)
   `OCKHealthKitTask` linked to HealthKit heart rate data.
7. **Resting Heart Rate** (`biomesh.resting.heart.rate`)
   `OCKHealthKitTask` linked to HealthKit resting heart rate data.

## Other Tasks Still Present

The app also still includes sample-compatible tasks such as `Steps`, `Sleep Duration`, onboarding, and the range-of-motion survey, but those are not the 7 tasks I am using for assignment counting.

## Schedule Requirements

At least 3 of the counted tasks use schedules that differ from the original sample app. In BioMesh, these include:

* **Hydration Checkpoint** uses two schedule elements each day, one in late morning and one in late afternoon.
* **Anxiety Check-in** appears every other day instead of every day.
* **Evening Wind-Down** appears nightly at 9:30 PM.
* **Weekly Pattern Reflection** appears once per week on Sunday evening.

## HealthKit Permissions

The onboarding survey was updated to request HealthKit permission for:

* Step count
* Sleep analysis
* Heart rate
* Resting heart rate

This supports the added `OCKHealthKitTask`s required by the assignment.

## App Idea

The app is organized around this relationship:

> Caffeine habits + hydration + recovery signals → stress patterns

Instead of only logging one symptom, BioMesh asks users to track a small set of habits and combines them with HealthKit data to show broader behavior patterns.

## Technologies Used

* Swift
* SwiftUI
* CareKit
* HealthKit
* ParseCareKit
