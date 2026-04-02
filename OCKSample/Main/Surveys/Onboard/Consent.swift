//
//  Consent.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

let informedConsentHTML = """
    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta name="viewport" content="width=400, user-scalable=no">
        <meta charset="utf-8" />
        <style type="text/css">
            ul, p, h1, h3 {
                text-align: left;
            }
        </style>
    </head>
    <body>
        <h1>BioMesh Study Consent</h1>
        <h3>About This Study</h3>
        <p>BioMesh is a research study investigating the relationship between <strong>caffeine intake</strong>, <strong>sleep quality</strong>, and <strong>anxiety levels</strong>. By participating, you will help us understand how daily caffeine consumption affects mental well-being.</p>
        <h3>Study Expectations</h3>
        <ul>
            <li>You will log your daily caffeine and water intake using the app.</li>
            <li>You will record anxiety episodes as they occur throughout the day.</li>
            <li>You will complete a nightly sleep hygiene checklist.</li>
            <li>You will share step count and sleep duration data from HealthKit.</li>
            <li>You will complete periodic surveys about stress and quality of life.</li>
            <li>The study will send you reminders to complete daily tasks.</li>
            <li>The study is expected to last 8 weeks.</li>
            <li>Your data is kept private, encrypted, and stored securely.</li>
            <li>You can withdraw from the study at any time without penalty.</li>
        </ul>
        <h3>Eligibility Requirements</h3>
        <ul>
            <li>Must be 18 years or older.</li>
            <li>Must consume caffeine at least once per week.</li>
            <li>Must be able to read and understand English.</li>
            <li>Must be the only user of the device on which you are participating.</li>
            <li>Must be able to sign your own consent form.</li>
        </ul>
        <p>By signing below, I acknowledge that I have read this consent carefully, that I understand all of its terms, and that I enter into this study voluntarily. I understand that my information will only be used and disclosed for the purposes described in the consent and I can withdraw from the study at any time.</p>
        <p>Please sign using your finger below.</p>
        <br>
    </body>
    </html>
    """
