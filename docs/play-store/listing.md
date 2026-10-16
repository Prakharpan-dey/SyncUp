# SyncUp: Play Store listing and Console answers

Everything to paste into Play Console. Assets are in this folder.

## Store listing

**App name** (30 max)
```
SyncUp: Tasks & Attendance
```

**Short description** (80 max, currently 77)
```
Plan your day, keep your streak, hit 75% attendance and study with friends.
```

**Full description** (4000 max)
```
SyncUp is a planner built for college life: your tasks, your attendance and your friends in one place.

PLAN YOUR DAY
• Add a task in seconds, with a priority, a due date and an optional reminder
• Repeating tasks for the things you do every day or every week
• Overdue tasks stay in view until they're done

KEEP THE STREAK
• Tick tasks off and watch your daily streak grow
• See what you got done today at a glance
• A weekly recap of how many days you showed up

NEVER MISS THE 75%
• Track attendance for every subject in one tap: present or absent
• See your percentage, and exactly how many classes you need to get back above the requirement
• Know how many classes you can safely skip

STUDY WITH FRIENDS
• Add friends and share today's plan so you keep each other on track
• Create study groups with their own feed
• React to your friends' progress
• You choose what's shared. Tasks marked private are never shown to friends.

WORKS OFFLINE
SyncUp saves everything on your phone first and syncs when you're back online, so a weak campus Wi-Fi never stops you planning.

YOUR DATA, YOUR CALL
• Control who can find you and what friends see
• Block or report anyone from their post or profile
• Delete your account any time, in the app or at api.zeusdotdev.app/account/delete

Light and dark themes included. No ads.
```

**Graphics**
| Asset | File |
|---|---|
| App icon 512×512 | `icon-512.png` |
| Feature graphic 1024×500 | `feature-graphic.png` |
| Phone screenshots (2–8) | `screenshots/` (to be captured from the 1.0.1 build) |
| Promo video | YouTube link to `syncup-launch-video/out/syncup-launch.mp4` (optional) |

**Category:** Productivity. **Tags:** Productivity, Education, To-do list.

**Contact:** the new support email (also set as `REPORTS_EMAIL` on Railway). Website optional.

## App content

**Privacy policy:** https://api.zeusdotdev.app/legal/privacy

**App access:** All or some functionality is restricted. Give the reviewer account's email and password with this note:
> Sign in with the account above. It already has tasks, a subject and a friend with a shared plan. Guest mode (on the sign-in screen) works for tasks and attendance but not for the social features.

**Ads:** No, the app does not contain ads.

**Content rating:** Category Utility, Productivity, Communication or Other.
- Violence, sexuality, language, controlled substances, gambling: No.
- Users can interact or exchange content: **Yes**.
- Shares the user's location: No.
- Digital purchases: No.

**Target audience:** 16–17 and 18 and over. Not designed for children.

**News app:** No. **Government app:** No. **Financial features:** None. **Health:** No.

## Data safety

The build has no analytics, crash reporting or ads SDKs. Firebase is used only for push messages.

**Data collection and security**
- Does your app collect or share any of the required user data types? **Yes**
- Is all user data encrypted in transit? **Yes** (HTTPS only)
- Do you provide a way for users to request that their data is deleted? **Yes**, in the app and at https://api.zeusdotdev.app/account/delete

**Data types.** All are collected, none are shared with third parties, and all are processed ephemerally: No.

| Category | Type | Required? | Purposes |
|---|---|---|---|
| Personal info | Name (display name) | Required | App functionality, Account management |
| Personal info | Email address | Required | App functionality, Account management |
| Personal info | User IDs (username) | Required | App functionality, Account management |
| Personal info | Other info (college, optional) | Optional | App functionality |
| App activity | Other user-generated content (tasks, attendance, shared plans, reactions) | Required | App functionality |
| Messages | Other in-app messages (reports sent to us) | Optional | App functionality, Fraud prevention, security and compliance |
| Device or other IDs | Device or other IDs (push token, device label for sessions) | Required | App functionality (notifications), Account management |

Not collected: location, financial info, health, photos and videos, audio, files, calendar, contacts, web browsing, app info and performance (no crash logs), and diagnostics.

## Release notes

**1.0.0 (closed test)**
```
First test build. Plan tasks, track attendance, keep your streak and share your day with friends.
```

**1.0.1**
```
• Report or block anyone from the ⋮ menu on their post, in your friends list or in a group
• Profile → Blocked users to see and undo blocks
• New look: the SyncUp logo and a fresh cobalt-and-lime theme
```
