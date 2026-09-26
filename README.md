# SecureChat - Monorepo

Group chat + realtime 1-to-1 chat PWA and a separate Admin Panel, built with Flutter.
Group / admin screens use mock data; the Direct (1-to-1) chat runs on the real backend in
`../securechat-backend` (Node.js, MongoDB, Socket.IO, Redis).

```
demoF/
├── pubspec.yaml              # Dart pub workspace (resolves all 3 packages together)
├── packages/
│   └── shared/               # Theme (black & white), widgets, models, mock data,
│                             # content filter engine, watermark, security badges
└── apps/
    ├── user_app/             # Chat app - Android + Web/PWA        (67 screens)
    │   └── lib/modules/
    │       ├── auth/             7  Splash, Welcome, Register, Login, OTP, Profile Setup, Terms
    │       ├── dashboard/        6  Chats | Groups | Profile tabs, Edit Profile, Account, Settings
    │       ├── groups/          10  Create (3 steps), Settings, Members, Member, Invite Link,
    │       │                        Join (link + login + location), Location Requirement, Security, Info
    │       ├── chat/            12  Group Chat, Composer, Options, Reply, Forward x2, Search,
    │       │                        Attach, Voice, Info, Deleted, Report
    │       ├── secure_message/   7  Privacy levels, Permissions, Forward Chain, Forwarded Details,
    │       │                        Delete for Everyone, Chain Deletion Status, Content Restriction
    │       ├── media/            7  Gallery, Image, Video, Document, Secure Viewer, File Permission, Warning
    │       ├── location/         6  Permission, Sharing (No/Join/Live), My Location, Members, Map, History
    │       ├── subscription/     6  Trial (7 days), Expired, Extension Request, Plans, Checkout, Status
    │       └── support/          6  Notifications, Reports, Report Member, Blocked, Help, Policies
    └── admin_app/            # Admin panel - responsive web         (30 screens)
        └── lib/modules/
            ├── auth/             Admin login + 2-step
            ├── dashboard/        Stats (users, trial, premium, groups, blocked, location)
            ├── users/            List, Details, Activity, Location, Blocked
            ├── groups/           List, Create/Edit, Details, Members, Location, Invite Links
            ├── subscription/     Trial Management, Premium Plans, Extension Requests, User Access
            ├── location/         Location Management
            ├── security/         Messages, Forward Chains, Moderation, Number Filter, Abuse Filter, Security
            ├── reports/          Abuse Reports, Reports & Analytics
            └── system/           Notifications, Audit Logs, Admin/Staff, System Settings
```

Each module owns its `screens/`, optional `widgets/` and a `<module>_routes.dart`;
the app router only composes module route lists.

## Core rules reflected in the UI
- Direct tab: realtime 1-to-1 chat (text, emoji, photos, video, voice notes, files, location, contacts,
  reply, forward, edit, delete, reactions, star, typing, online / last seen, read receipts, block).
  Phone number and email are never shown to other users.
- Groups: members see only the display (starting) name.
- Every message/file: Public / Private / Highly Protected (3 security levels).
- Content filter before send: numbers, number words (incl. `ONE1`, `T H R E E`), abuse, spam,
  links, external contacts, personal info - `packages/shared/lib/src/core/utils/content_filter.dart`.
- Forward chain with chain-aware Delete for Everyone (original or middle copy).
- Protected files only in the secure viewer with dynamic watermark; no download/share/open-with.
- Group location: Off / Optional / Mandatory, join blocked until location is shared.
- 7-day trial -> expired -> extension request -> admin Approve 7 / 30 days / Premium / Reject.

All permissions must also be enforced by the backend - the UI only mirrors them.

## Run
Start the backend first (see `../securechat-backend/README.md`), then:
```bash
flutter pub get                                                   # from repo root (workspace)
cd apps/user_app  && flutter run -d chrome --release --web-port=8080   # chat PWA (API: http://localhost:4000)
# other backend: flutter run --dart-define=API_URL=https://api.example.com  (Android emulator default: 10.0.2.2:4000)
cd apps/admin_app && flutter run -d chrome --release --web-port=8081   # admin panel
flutter test                                                      # inside each package
```

Debug web mode (`flutter run -d chrome` without `--release`) loads ~600 separate DDC scripts.
On slow machines the Chrome debugger attach times out after 5 s
(`TimeoutException ... WebkitDebugger.enable`) and the page stays blank - use `--release`.
If a page stays blank, make sure no older `flutter run` is still holding the same port
(`Get-NetTCPConnection -LocalPort 8080`).
