# Asteria Scouting App

**Open Source Scouting Platform for FTC Teams**

Developed by **Asteria Robotics #32334** to help teams collect fast, organized, and reliable scouting data during competitions and qualifiers.

---

## ✨ Key Features

- **Simple & Fast Login** — Just enter your name
- **Comprehensive Scouting Form** — Match number, team number, score (1-100), detailed notes
- **Multiple Photo Support** — Add as many photos as you want per entry
- **My Records** — View, edit, and delete your own scouting entries
- **Admin Panel** — 
  - Real-time team rankings by average score
  - View all scouting data
  - Photo preview in detailed pop-up
- **Fully Responsive** — Works great on phones, tablets, and computers

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK installed
- A Supabase account (free)

### Installation

```bash
# Clone the repository
git clone https://github.com/asteria32334/asteria-scouting-app.git
cd asteria-scouting-app/asteria_scouting

# Install dependencies
flutter pub get

# Run the app
flutter run -d web-server

📋 Supabase Setup (Required)

Go to supabase.com and create a new project
Create table scouting_reports with the following columns:

Column Name,   Type,    Nullable,   Description
id,           uuid,         No,      Primary Key
match_number, int4,        Yes,    Match number
team_number, int4,         Yes,    Team number
score,       int4,         Yes,    Score (1-100)
notes,       text,         Yes,    Notes
scouted_by,  text,         Yes,    Scout name
photo_url,   text,         Yes,    Photo URLs (comma separated)
created_at,  timestamptz,  Yes,    Timestamp

In Storage, create a public bucket named scouting_photos

🔑 Default Admin Password
Password: admin
(You can change this in the code)

📱 How to Use
For Scouts

Enter your name
Fill in match and team information
Give a score between 1-100
Add notes and photos (optional)
Click Save

For Team Leaders (Admin)

Use the admin password on the login screen
View team rankings
Browse all scouting data with photos

**How to use the site as a native app on iPhone?**
 On iOS 26.0 or later:
-> open the website link
-> click the 3 dots
-> click share
-> click more
-> click add to the homepage
-> make sure 'open as a web application' is enabled
-> click add
on iOS 18 or before:
-> click share icon
-> click add to the homepage
-> make sure 'open as a web application' is enabled
-> click add

 Contributing
We welcome contributions from the FTC community!

Fork the project
Create a feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m 'Add amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request

 License
This project is licensed under the MIT License — feel free to use, modify, and distribute.


NOTE:
IF YOU EXPERIENCE ANY PROBLEMS WİTH SETUP PROCCESS, PLEASE REACH US AT-> asteria.32334@gmail.com or @asteria_32334 Instagram
