# AgriMart: Full Project Context Overview

This document provides a comprehensive overview of the AgriMart platform. You can provide this file to any LLM (like Claude or ChatGPT) so it instantly understands the architecture, tech stack, and state of development.

---

## 1. Project Overview
AgriMart is an end-to-end Agri-Tech platform built to empower Indian farmers and agricultural suppliers. It eliminates the middleman, offering direct market access, AI-powered agricultural tools, live market prices (Mandi), and a seamless e-commerce experience.

**Target Output Locations:**
- Backend: Platform APIs & Services
- Admin Dashboard: Platform management
- Mobile App: The primary user-facing client for Farmers and Suppliers.

---

## 2. Technology Stack

### Backend (`/agrimart-backend`)
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database ORM:** Prisma
- **Database:** Supabase (PostgreSQL with Connection Pooling / Session Pooler enabled for IPv4 handling on Railway)
- **Deployment:** Railway.app (formerly Render)

### Admin Panel (`/agrimart-admin`)
- **Framework:** React.js (built with Vite)
- **Styling:** Tailwind CSS + shadcn/ui components
- **State Management:** Zustand
- **Data Fetching:** TanStack React Query

### Mobile App (`/agrimart_flutter`)
- **Framework:** Flutter
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** go_router
- **Networking:** Dio
- **Storage:** `shared_preferences` & `flutter_secure_storage`
- **Charts:** `fl_chart` (for premium Mandi price tracking)

---

## 3. Core Features & App Flows

### The Farmer Flow
1. **Onboarding:** OTP login via Phone -> Select "Farmer" role -> Fill profile (Name, Location, PIN).
2. **Dashboard / Home:** Displays dynamic language greetings, weather widgets, dynamic quick links, and recent orders.
3. **Shop & Cart:** E-commerce flow. Browse fertilizers/seeds, add to cart, and checkout using Cash on Delivery or Razorpay.
4. **AI Hub:** 
   - **Kisan AI:** Chatbot powered by Google Gemini.
   - **Disease Detection:** Upload images of crops for AI diagnosis.
   - **Soil Analysis & Crop Advisor:** AI tools based on location & soil data.
5. **Mandi Prices:** Live integration with AGMARKNET API. Premium UI featuring interactive line charts for 1D, 5D, 1M, 6M, and 1Y price trends.
6. **Govt Schemes:** Lists active agricultural schemes available in India.

### The Supplier Flow
1. **Onboarding:** Registers as an "Agri-Supplier" -> Requires admin approval to be marked "VERIFIED".
2. **Supplier Dashboard:** View total sales revenue, active orders, and pending shipments.
3. **Inventory Management:** CRUD operations to add new products (Fertilizers, Tractors, Seeds, Pesticides) to the global marketplace.

---

## 4. Key Integrations & APIs

- **Razorpay:** Order/Checkout Integration for secure payments.
- **Twilio:** Used for sending Phone OTPs via WhatsApp Sandbox or SMS.
- **Supabase (PostgreSQL):** Primary relational data store. Requires Port 6543 Session Pooler configuration (`pgbouncer=true`).
- **Google Gemini:** Powers the `Kisan AI` chatbot, Crop advisor, and Plant Disease Detection tools.
- **OpenWeather API:** Real-time weather reporting on the farmer's dashboard.
- **AGMARKNET (data.gov.in):** Fetches official Indian Government Mandi prices.

---

## 5. Database Schema (Prisma)
A simplified outline of the core `schema.prisma`:
- **User:** Tracks `role`, `phone`, `name`, `language`, `location`.
- **Product:** Added by Suppliers. Tracks `price`, `stock`, `category`, `imageUrl`.
- **Order / OrderItem:** E-commerce transactions. States include `PENDING`, `SHIPPED`, `DELIVERED`, `CANCELLED`.
- **Cart / CartItem:** Ephemeral state before checkout.
- **MandiPrice:** Cached entries of daily market rates mapped by commodity and state.

---

## 6. Known Context & Recent Updates
- The codebase relies deeply on Riverpod. Providers are organized via a central `app_providers.dart` file.
- The UI is built to replicate "Premium Startup/Trading Apps" (e.g., Zerodha, Groww). Design priorities include `fl_chart` integration, rich gradients, and custom vertical order-tracking steppers.
- Language Handling: Built a custom `LanguageProvider` that persists the locale (English, Marathi, Hindi) and dynamically drives UI text formatting on the dashboard and settings screens without relying on heavy `flutter_localizations` wrappers for now.

*(Provide this file directly to Claude and prompt it with your next feature request!)*
