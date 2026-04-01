//
//  Consent.swift
//  OCKSample
//
//  Created by Faye on 3/23/26.
//

import Foundation

let informedConsentHTML = """
    <!DOCTYPE html>
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta name="viewport" content="width=400, user-scalable=no">
        <style>
            body { font: 14px -apple-system; padding: 16px; }
            h2  { text-align: center; }
            .section { margin-bottom: 16px; }
        </style>
    </head>
    <body>
        <h2>BioMesh Study — Informed Consent</h2>

        <div class="section">
            <h3>Purpose</h3>
            <p>This study explores how daily caffeine intake relates to anxiety levels,
               with sleep quality as a mediating variable. By participating, you help
               researchers understand the caffeine–anxiety connection.</p>
        </div>

        <div class="section">
            <h3>What You Will Do</h3>
            <p>You will log caffeine and water intake, record anxiety episodes, complete
               a nightly wind-down checklist, and periodically answer brief check-in
               surveys and perform range-of-motion measurements.</p>
        </div>

        <div class="section">
            <h3>Data & Privacy</h3>
            <p>Your data is stored securely and shared only with the research team.
               HealthKit data (steps, sleep) stays on your device unless you choose
               to sync it. You may withdraw at any time without penalty.</p>
        </div>

        <div class="section">
            <h3>Risks & Benefits</h3>
            <p>There are no known risks beyond those of everyday smartphone use.
               Benefits include personalized insights into how caffeine affects your
               well-being.</p>
        </div>

        <div class="section">
            <h3>Consent</h3>
            <p>By signing below, you confirm that you have read and understand this
               information, and you voluntarily agree to participate in the BioMesh
               Caffeine &amp; Anxiety study.</p>
        </div>
    </body>
    </html>
    """
