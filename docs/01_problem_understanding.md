# Phase 1 — Understanding the Problem

**Project:** Duolingo Language Learning Database  
**Team:** T0077 | Section A

## Context

Duolingo's learning experience depends on several connected operations: tracking lessons and XP, maintaining streaks, updating league standings, and analysing learner activity. These operations serve different purposes, but all depend on the same underlying data.

In this project, we are working with an existing system whose database schema is undocumented. We have been given CSV exports and a workload of 30 SQL queries. Our task is to reconstruct the database, understand where performance and correctness problems arise, and improve it without compromising the data or expected results.

## Problems Identified

| ID | What needs to be addressed | Stakeholders | Nature |
|---|---|---|---|
| **P1** | The home screen takes too long to retrieve a learner's course path, XP, daily goal, current streak and next unfinished lesson. These are basic details users expect immediately when opening the app. | Learners, Learner App | Real-time |
| **P2** | League standings are slow to display, and processing weekly rankings, promotions and demotions takes too long. Both leaderboard retrieval and end-of-week updates need attention. | Learners, Gamification Team | Real-time / Batch |
| **P3** | Starting or completing a lesson and updating daily XP must happen without noticeable delay. Slow writes can interrupt the learning flow or leave progress temporarily inconsistent. | Learners, Learner App | Real-time |
| **P4** | The curriculum team needs reliable reports on mistakes, abandoned attempts, hearts lost and lesson completion. These patterns help identify lessons that learners struggle with. | Curriculum Team | Analytics |
| **P5** | The query identifying learners who have never referred anyone returns an empty result. This points to a query-logic problem that must be corrected, not merely made faster. | Growth Team | Analytics / Correctness |
| **P6** | Growth and retention reports are timing out. The system must efficiently analyse daily active users, cohort retention, XP trends, course popularity and learners who may need streak reminders. | Growth, Retention, Notifications | Analytics |
| **P7** | Sign-in, username search, achievement processing and support-console queries are slow. The database must also handle monetisation-related queries and an expected 20× increase in activity. | Learners, Platform, Support, Monetisation | Real-time / Analytics |

## Working Assumptions

1. The supplied CSV exports are our starting point for reconstructing the schema; we will verify their relationships, null values and constraints before finalising the design.
2. Learner-facing reads and writes need faster responses than scheduled reports. Weekly league processing may be treated as batch work, although users still depend on timely results.
3. Some missing values are meaningful: an unfinished lesson may have no completion timestamp, and a learner may have no referrer.
4. Query correctness takes priority over speed. Optimisation should preserve valid results, while known logical errors must be identified and fixed.
5. We will first measure performance on the supplied dataset, then compare improvements under the same conditions. Larger-scale testing will use the faculty-provided growth dataset.

## Our Approach

We will begin by reconstructing and validating the relational schema, then establish baseline timings for the 30 supplied queries. Those measurements will guide indexing and query rewrites, followed by a scalability assessment. The goal is not simply to reduce execution time, but to make the database dependable for both day-to-day learning operations and the teams relying on its data.
