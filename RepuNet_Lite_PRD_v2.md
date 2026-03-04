# RepuNet Lite -- Hybrid Campus Reputation System

Product Requirements Document (PRD) Version 2.0 -- Simplified & Feasible
(4th Semester Scope)

------------------------------------------------------------------------

# 1. Project Goal

Build a semester-feasible hybrid reputation system that combines peer
ratings with academic credibility (CGPA) and faculty validation, while
preventing manipulation through weighted logic and smoothing mechanisms.

------------------------------------------------------------------------

# 2. Context & Teacher Feedback

During evaluation, the following issues were identified:

1.  User input alone is unreliable.
2.  A group could inflate each other's ratings.
3.  High-rated users could unfairly downvote others.
4.  Review bombing (slow or sudden) could manipulate scores.
5.  System lacked clear decision logic.

This version directly addresses those concerns.

------------------------------------------------------------------------

# 3. Tech Stack

Frontend: - Flutter (Dart)

Backend: - Firebase Authentication - Firestore Database

Logic Layer: - Dart (Client-side reputation engine) - Optional future
migration to Firebase Cloud Functions

------------------------------------------------------------------------

# 4. Core Design Philosophy

The system must: - Not trust raw ratings - Limit influence power -
Combine academic and peer credibility - Smooth sudden changes - Be
implementable within 3--4 weeks

------------------------------------------------------------------------

# 5. Data Schema (Firestore)

## users collection

Fields: - userId (string) - name (string) - cgpa (double) - teacherScore
(double) - reputation (double) - credibility (double) - createdAt
(timestamp)

## interactions collection

Fields: - interactionId (auto) - fromUser (string) - toUser (string) -
rating (int 1--5) - timestamp (timestamp)

------------------------------------------------------------------------

# 6. Reputation Logic (Fixed Model)

Step 1 -- Weighted Peer Score

For each incoming interaction: weightedRating = rating ×
raterCredibility

peerScore = weightedAverage(weightedRating)

------------------------------------------------------------------------

Step 2 -- Hybrid Formula

normalizedCGPA = cgpa / 10

calculatedReputation = (0.5 × peerScore) + (0.3 × normalizedCGPA) + (0.2
× teacherScore)

------------------------------------------------------------------------

Step 3 -- Smoothing (Prevents Review Bombing)

newReputation = (oldReputation × 0.7) + (calculatedReputation × 0.3)

------------------------------------------------------------------------

# 7. Credibility Model

credibility = (0.6 × normalizedCGPA) + (0.4 × normalizedReputation)

Influence Cap: credibility = min(credibility, MAX_LIMIT)

This prevents powerful users from dominating others.

------------------------------------------------------------------------

# 8. Manipulation Protections

1.  One rating per user per target.
2.  Influence cap on all users.
3.  Smoothing to prevent sudden spikes/drops.
4.  Minimum unique raters threshold before full weight applied.
5.  CGPA baseline ensures peer-only manipulation is insufficient.

------------------------------------------------------------------------

# 9. System Flow

User submits rating → Store interaction in Firestore → Fetch all
interactions for target user → Apply weighting & hybrid formula → Apply
smoothing → Update user reputation

Recalculation occurs immediately on rating submission.

------------------------------------------------------------------------

# 10. Implementation Roadmap

Step 1 -- Firebase setup (Auth + Firestore) Step 2 -- Create user and
interaction models Step 3 -- Implement rating submission logic Step 4 --
Implement reputation calculation function Step 5 -- Add smoothing Step 6
-- Add influence cap Step 7 -- UI display of reputation breakdown

------------------------------------------------------------------------

# 11. Minimum Demo Requirements

-   User registration/login
-   Submit rating
-   Auto-update reputation
-   Display reputation breakdown (Peer + CGPA + Teacher)
-   Duplicate rating prevention

------------------------------------------------------------------------

# 12. Out of Scope (This Semester)

-   PageRank-style propagation
-   Graph database
-   Machine learning anomaly detection
-   Distributed architecture

------------------------------------------------------------------------

# 13. Final Positioning

RepuNet Lite is not a simple rating app. It is a hybrid weighted
reputation system designed to:

-   Combine academic credibility with peer feedback
-   Reduce manipulation risk
-   Remain feasible within semester constraints
