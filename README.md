# Pocketly - Personal Finance Management App for Students

Pocketly is a modern mobile finance application designed for students (mahasiswa & pelajar) to take control of their personal money. Built with Flutter and powered by an Express API, Pocketly lets users record every rupiah that goes in and out, plan a monthly budget, and understand their spending habits through interactive reports — all secured with JWT authentication.

## Features

- **Secure Auth & Session:** Register and login with bcrypt-hashed passwords, JWT-authenticated sessions, "remember me", and encrypted token storage via flutter_secure_storage.
- **Dashboard:** Real-time overview of total balance, monthly income and expenses, budget usage progress, and the latest transactions at a glance.
- **Transaction Management:** Record income and expenses with categories, notes, dates, and quick filters (all / income / expense / category).
- **Monthly Budget:** Set a monthly spending target with a live progress bar, remaining balance, usage percentage, and saving tips.
- **Reports & Statistics:** Interactive pie chart and category breakdowns powered by fl_chart to visualize where the money goes.
- **Profile Management:** Edit personal profile and update avatar directly from camera or gallery.

## Tech Stack

Frontend: Flutter, Dart, Provider, fl_chart, Google Fonts
Backend: Node.js, Express, Drizzle ORM, JSON Web Token, bcrypt
Database: PostgreSQL (NeonDB)
Platforms: Android (primary), iOS, Web, Windows, macOS, Linux
