# MediChain Store

Full-stack e-commerce project with:
- `backend/` -> Node.js + Express + MongoDB API
- `store/` -> Flutter app (Android, iOS, Web, Desktop)

## Project Structure

```text
medichain/
  backend/
  store/
```

## Features

- User auth and profile
- Product catalog and categories
- Cart, checkout, and orders
- Wishlist and reviews
- Promotions/discounts
- Admin dashboard and product management
- Inventory insights (low stock / out of stock)
- Shoes category support in storefront and admin

## Requirements

- Node.js 18+
- npm 9+
- Flutter SDK 3.8+
- MongoDB Atlas (or local MongoDB)

## 1) Backend Setup

From `backend/`:

```bash
npm install
```

Create local env file from example:

```bash
cp .env.example .env
```

Create or update `backend/.env`:

```env
NODE_ENV=development
PORT=5000
MONGODB_URI=your_mongodb_connection_string

JWT_SECRET=your_jwt_secret
JWT_EXPIRE=7d

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@example.com
EMAIL_PASS=your_email_app_password

CLIENT_URL=http://localhost:54587
```

Run backend:

```bash
npm run dev
```

Optional seed data:

```bash
npm run seed
```

API base URL:
- `http://localhost:5000/api/v1`

Health check:
- `http://localhost:5000/health`

## Backend Hosting (Render)

This repo now includes `render.yaml` at root for backend hosting.

Steps:

1. Push latest code to GitHub (already done).
2. In Render, choose `New +` -> `Blueprint` and select this repo.
3. Render will detect `render.yaml` and create `medichain-backend`.
4. Set secret env values in Render for:
  - `MONGODB_URI`
  - `JWT_SECRET`
  - `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
  - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
  - `EMAIL_USER`, `EMAIL_PASS` (and `EMAIL_HOST` if not Gmail)
5. Deploy and verify health endpoint:
  - `https://<your-render-service>.onrender.com/health`

Then point Flutter Web build to hosted backend API:

```bash
flutter build web --release --base-href /store/ --dart-define=API_BASE_URL=https://<your-render-service>.onrender.com/api/v1
```

## 2) Flutter App Setup

From `store/`:

```bash
flutter pub get
flutter run
```

For web:

```bash
flutter run -d chrome
```

If backend is running on a different host/port, override API URL at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5000/api/v1
```

## Frontend Hosting API Binding (GitHub Pages)

The GitHub Actions workflow builds web with `--dart-define=API_BASE_URL=...`.

Priority used by workflow:

1. `secrets.FRONTEND_API_BASE_URL`
2. `vars.FRONTEND_API_BASE_URL`
3. Default: `https://medichain-backend.onrender.com/api/v1`

Set this in GitHub:

1. Repo `Settings` -> `Secrets and variables` -> `Actions`
2. Add secret or variable: `FRONTEND_API_BASE_URL`
3. Value example: `https://<your-render-service>.onrender.com/api/v1`

## 3) App Icon

Launcher icon is configured via `flutter_launcher_icons` in `store/pubspec.yaml`.

Regenerate icon assets:

```bash
cd store
dart run flutter_launcher_icons
```

## Common Issues

### Product image upload returns 500

- Ensure Cloudinary credentials in `backend/.env` are valid.
- If Cloudinary is not configured, backend falls back to local uploads under `backend/uploads`.
- Restart backend after `.env` changes.

### Icon not updating

- Stop app and run again (hot reload is not enough for launcher icons).
- Web: hard refresh (`Ctrl+F5`) or open in incognito.
- Android: uninstall app from emulator/device and rerun.

## Scripts

### Backend (`backend/package.json`)

- `npm run dev` -> start API with nodemon
- `npm start` -> start API with node
- `npm run seed` -> seed sample products

### Flutter (`store/`)

- `flutter pub get` -> install dependencies
- `flutter run` -> run app
- `flutter test` -> run tests

## Notes

- Keep secrets out of source control.
- Use `NODE_ENV=development` while debugging to get full error details.
