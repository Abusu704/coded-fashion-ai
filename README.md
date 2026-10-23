# Track 3 — AI Fashion Campaign Generator

A Flutter application for creating AI-powered fashion marketing campaigns from product details and images.

## Tech Stack

- Flutter and Dart
- Node.js and Express
- Google Gemini API
- Sharp for image processing

## Prerequisites

Install the following before running the project:

- Git
- Flutter SDK
- Node.js and npm
- A Google Gemini API key

Check your installations:

```bash
flutter --version
node --version
npm --version
```

## 1. Clone the Project

```bash
git clone -b feature/track3-campaign-generator https://github.com/Abusu704/coded-fashion-ai.git
cd coded-fashion-ai
```

This repository contains multiple team projects. The Track 3 campaign generator is on the branch shown above.

## 2. Configure the Backend

Open a terminal in the project directory:

```bash
cd backend
npm install
```

Create a local environment file:

```bash
touch .env
```

Add your own Gemini API key to `backend/.env`, using the exact variable name expected by `backend/server.js`.

Never upload your `.env` file or share your API key publicly.

Start the backend:

```bash
node server.js
```

The API runs on port 5001 by default.

Check that it is running from another terminal:

```bash
curl http://localhost:5001/api/health
```

A successful response should report the service status as `ok`.

## 3. Run the Flutter App

Open a second terminal and return to the project root:

```bash
cd "$HOME/Desktop/project hackathon/GroupProject/track3/track3_campaign_demo"
flutter pub get
flutter run
```

To run on a connected Android phone, enable Developer Options and USB debugging, connect the phone, and check available devices:

```bash
flutter devices
```

Select your phone when Flutter asks which device to use.

## 4. Mobile Backend Connection

The Android app must be able to reach the computer running the backend.

1. Connect the computer and phone to the same Wi-Fi network or hotspot.
2. Find the computer's local IP address:

   ```bash
   hostname -I
   ```

3. In `lib/main.dart`, update the Android API host to the computer's current local IP address, keeping port `5001`.
4. Keep the backend running while using the app.
5. Allow local network access through the computer's firewall if necessary.

The IP address may change when you reconnect to a different network. Do not use `localhost` as the backend host on a physical Android phone, because it refers to the phone itself.

## 5. Troubleshooting

**Backend connection failed**
- Make sure the backend is running.
- Check `http://localhost:5001/api/health` on the computer.
- Check that the phone and computer are on the same network.
- Confirm the Android API URL uses the computer's current IP address.

**Missing Flutter packages**

```bash
flutter pub get
```

**Missing Node.js packages**

```bash
cd backend
npm install
```

**Gemini errors**
- Confirm your API key is valid.
- Check the backend terminal for error messages.
- Confirm the environment variable matches the name used by the backend code.

## 6. Before Committing Changes

Run:

```bash
flutter analyze
flutter test
git status
```

Do not commit API keys, `.env` files, or other secrets.

## Team Branch

Track 3 branch: `feature/track3-campaign-generator`

Repository: https://github.com/Abusu704/coded-fashion-ai
