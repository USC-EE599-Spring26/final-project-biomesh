//
//  Consent.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/*
 TODO: The informedConsentHTML property allows you to display HTML
 on an ResearchKit Survey. Modify the consent so it properly
 represents the usecase of your application.
 */

let informedConsentHTML = """
    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta name="viewport" content="width=400, user-scalable=no">
        <meta charset="utf-8" />
        <style type="text/css">
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                padding: 8px;
            }
            ul, p, h1, h3 {
                text-align: left;
            }
        </style>
    </head>
    <body>
        <h1>BioMesh Informed Consent</h1>

        <h3>Purpose of BioMesh</h3>
        <p>
            BioMesh is designed to help users better understand how daily habits and health patterns
            are connected. In this app, you may track caffeine intake, hydration, anxiety check-ins,
            sleep-related habits, and activity data such as steps and sleep duration.
        </p>

        <h3>What You Will Be Asked to Do</h3>
        <ul>
            <li>You will be asked to complete short surveys and daily check-ins in the app.</li>
            <li>You may log information such as caffeine intake, water intake, and anxiety level.</li>
            <li>You may allow the app to read selected HealthKit data, such as steps and sleep data.</li>
            <li>You may receive notifications reminding you to complete tasks and maintain your routine.</li>
            <li>Your participation is voluntary, and you may stop using the app at any time.</li>
        </ul>

        <h3>Privacy and Data Use</h3>
        <ul>
            <li>Your information will be stored securely within the app system.</li>
            <li>Your data will only be used to support your care experience, self-tracking, and app-related research or evaluation purposes.</li>
            <li>Only the minimum necessary information should be collected to support the goals of BioMesh.</li>
            <li>You can withdraw your participation at any time.</li>
        </ul>

        <h3>Eligibility Requirements</h3>
        <ul>
            <li>Must be 18 years or older.</li>
            <li>Must be able to read and understand English.</li>
            <li>Must be the primary user of the device used for BioMesh.</li>
            <li>Must be able to provide consent independently.</li>
        </ul>

        <p>
            By signing below, I confirm that I have read and understood this consent form.
            I understand that BioMesh may collect the information described above to support
            tracking, care, and evaluation purposes. I understand that my participation is voluntary
            and that I may withdraw at any time.
        </p>

        <p>Please sign below using your finger.</p>
        <br>
    </body>
    </html>
    """
