# AgriMart — Project Context for Claude

Hello Claude! This file is meant to give you a comprehensive overview of the **AgriMart** project, what has been built so far, the tech stack, and the overall architecture. Please refer to this document to understand the project structure and context before making changes.

## Project Overview
AgriMart is an Indian Agricultural Marketplace designed to connect **Farmers, Suppliers, and Dealers**. 
It features a mobile application for end-users, a backend API for business logic, and a web-based admin dashboard for platform management.

## Monorepo Structure (`d:\agrobee`)
The project is divided into three main workspaces/directories:
1. `agrimart-backend/` — Node.js & Express API
2. `agrimart-admin/` — React & Vite Admin Dashboard
3. `agrimart_flutter/` — Flutter Mobile Application

---

## 1. Backend (`agrimart-backend`)
A robust Node.js backend handling all business logic, payments, external API integrations, and AI features.

**Tech Stack:**
*   **Runtime/Framework:** Node.js, Express.js
*   **Database & ORM:** PostgreSQL (hosted on Supabase) managed via Prisma ORM.
*   **Caching:** Redis (Upstash) for caching API responses (e.g., Dashboard stats, Mandi prices) and rate-limiting.
*   **Authentication:** JWT-based auth with Twilio WhatsApp OTP integration.
*   **Storage:** Supabase Storage (Buckets) for image uploads (Multer).

**Key Integrations:**
*   **Google Gemini AI:** Used for analyzing soil reports via images.
*   **Razorpay:** Integrated for handling payments (Orders).
*   **OpenWeather API:** For providing weather forecasts to farmers.
*   **AGMARKNET API:** For fetching daily Mandi (market) crop prices.
*   **OneSignal & Firebase Admin:** For push notifications.

**Core Data Models (Prisma):**
*   `User`: Roles include `FARMER`, `SUPPLIER`, `DEALER`, and `ADMIN`.
*   `Farmer`: Can order products, get AI soil reports, and book trade slots with dealers to sell crops.
*   `Supplier`: Sellers of agricultural products (SEEDS, FERTILIZER, PESTICIDE, etc.). Requires document verification by Admin.
*   `Dealer`: Buyers of crops from farmers. They set daily crop rates and accept trade bookings. Requires document verification.
*   `Product`, `Order`, `Payment`, `SoilReport`, `TradeBooking`, `GovernmentScheme`, `MandiNews`.

---

## 2. Admin Dashboard (`agrimart-admin`)
A web-based dashboard used by platform administrators to oversee operations.

**Tech Stack:**
*   **Framework:** React 19, Vite
*   **Styling & UI:** Lucide React (Icons), Recharts (Charts/Analytics)
*   **State & Routing:** Context API for Auth (`useAuth`), React Router DOM
*   **API Client:** Axios

**Implemented Features:**
*   **Dashboard:** Displays platform stats, revenue trends, and recent orders.
*   **User Management:** Admins can view users and toggle active status.
*   **Verification System:** Admins can review government documents and approve/reject pending Suppliers and Dealers.
*   **Product Management:** Approving or rejecting new products added by suppliers.

*Note: Default Admin credentials for testing are Phone: `9999999999`, Password: `AgriMart@Admin2024`*

---

## 3. Mobile App (`agrimart_flutter`)
The cross-platform mobile application used by Farmers, Suppliers, and Dealers.

**Tech Stack:**
*   **Framework:** Flutter (SDK >= 3.0.0)
*   **State Management:** Riverpod (with `riverpod_annotation`)
*   **Routing:** GoRouter
*   **API Client:** Dio (with `pretty_dio_logger`)
*   **Local Storage:** Hive & Flutter Secure Storage

**Key Flutter Features / Packages:**
*   **Localization:** Multi-language support (English, Hindi, Marathi).
*   **UI/UX:** Shimmer loading effects, Lottie animations, FL Chart, Google Fonts.
*   **Hardware / Native:** Camera integration (for capturing soil/documents), Geolocator & Geocoding (for address and mandi mapping).
*   **Accessibility:** Speech-to-Text and Flutter TTS (Text-to-Speech) for illiterate/accessibility-focused farmers.

---

## Current Development Environment State
*   The backend API currently points to local network IP `10.59.22.186:3000` for physical device testing.
*   The admin panel is typically served on Vite default ports (e.g., `http://localhost:5173`).
*   The Flutter app uses `--dart-define=API_BASE_URL=...` for API endpoint overrides during local development.

**Development Guidelines:**
1. Check Prisma schema (`agrimart-backend/prisma/schema.prisma`) before modifying database logic.
2. Ensure you respect the existing Riverpod architecture and state management in the Flutter app.
3. Keep the UI modern and responsive, matching the existing design aesthetics.
