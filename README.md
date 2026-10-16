# Mykoku Attendance

A **proof-of-concept** Flutter app for face-recognition–based attendance. Coaches
enroll students by capturing their face, then mark attendance by scanning faces
against the enrolled set. Face matching is handled by a separate Python/Flask
("deepmin") backend; this app handles on-device face **detection**, image
capture, and talking to that backend.

> ⚠️ This is a demo / PoC used to validate the face-attendance flow — not a
> production build. Auth, Firebase, and several screens are stubbed or
> commented out.

## How it works

The app uses [Google ML Kit](https://developers.google.com/ml-kit) on-device to
*detect* a face in the camera stream, captures a still frame, encodes it as
base64, and sends it to the deepmin backend which generates embeddings and
performs the actual *recognition*.

### Enrollment flow (`ScannerMode.enrollment`)
1. Start front-camera stream and detect a single face.
2. Capture a still and show a dialog to enter the student's name.
3. POST name + base64 image to `register-student` → backend creates an embedding.
4. Show success, cool down, and resume scanning for the next student.

### Recognition flow (`ScannerMode.recognition`)
1. Start stream and detect a single face.
2. Capture a still and POST base64 image to `get-all-students` → returns a `job_id`.
3. Poll `job-result/<job_id>` for the closest match.
4. Display the matched student name and allow uploading attendance.

## Tech stack

- **Flutter** (Dart SDK `>=3.4.0 <4.0.0`), managed via [FVM](https://fvm.app/)
- `camera` — live camera stream and still capture
- `google_mlkit_face_detection` — on-device face detection
- `flutter_bloc` — state management (authentication bloc, currently disabled)
- `http` — REST calls to the backend via `AppClient`
- `flutter_dotenv` — environment config (`lib/.env`)
- `firebase_*`, `flutter_appauth`, `flutter_secure_storage` — scaffolded for
  future auth/analytics (mostly commented out in this PoC)

## Project structure

```
lib/
├── main.dart                  # App entry, routes, repository providers
├── models/                    # coach, student, deepmin_result models
├── screens/
│   ├── authentication/        # landing + coach login (stubbed)
│   ├── home/                  # entry point: health check + enroll/recognize
│   ├── scanner/               # camera + face detection (enroll & recognize)
│   └── settings/              # settings (stubbed)
├── services/
│   ├── app_client.dart        # HTTP client for the deepmin backend
│   ├── app_storage.dart       # secure storage wrapper
│   ├── bloc/                  # authentication bloc
│   └── repositories/          # deepmin, coach, student, auth repositories
├── utils/                     # image conversions, dialogs, debouncer
└── widgets/                   # face bounding box, name input modal
```

## Backend

Face embeddings and matching run on the separate **deepmin** Flask backend
(a minimal DeepFace API). The app reaches it through endpoints:

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `health` | GET | Server status (shown on the home page) |
| `register-student` | POST | Enroll a face (name + base64 image) |
| `get-all-students` | POST | Submit a recognition job, returns `job_id` |
| `job-result/<job_id>` | GET | Fetch recognition result / matched name |
| `list-jobs` | GET | List pending jobs |

## Getting started

### Prerequisites
- Flutter via FVM (see `.fvmrc`)
- A running deepmin backend
- A physical device (camera + ML Kit are required; simulators won't work well)

### Configure environment
Copy the sample env file and fill in the values:

```sh
cp lib/.env.example lib/.env
```

`lib/.env` is gitignored and must never be committed. `FLASK_API_URL` points to
the deepmin backend and is the only URL the attendance flows actually use; the
other `*_API_URL` / `*_WEB_URL` keys are scaffolding for a future attendance
backend and are currently unused.

### Run

```sh
fvm flutter pub get
fvm flutter run
```

On iOS you may also need `cd ios && pod install`.
