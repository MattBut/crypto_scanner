# 🚀 Crypto Scanner Ecosystem 
A comprehensive full-stack solution for cryptocurrency market monitoring. This project demonstrates a production-ready architecture using Flutter for the mobile experience and Python for backend data orchestration.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a3a10279-840a-4595-8b51-6f91dc5d36f7" width="800">
</p>

[![Download APK]

(https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](ТВОЯ_ССЫЛКА_НА_APK)

The project is built with Separation of Concerns in mind, split into two primary modules:

Backend (Python Microservice): * Aggregates data from multiple exchange APIs.

Normalizes and cleans raw JSON data into a unified format.

Optimizes payloads to reduce mobile bandwidth consumption.

Mobile App (Flutter): * Follows Clean Architecture principles (Data, Domain, Presentation layers).

Implements a reactive UI with high-performance list rendering.

# 🛠 Technical Stack
Mobile Frontend (Flutter)
State Management: Riverpod (reactive state handling).

Dependency Injection: GetIt (Service Locator pattern).

Networking: Dio with an advanced Fault-Tolerant Retry Policy (dio_smart_retry) to handle unstable connections and DNS lookup issues.

Architecture: Clean Architecture with a strict decoupling of business logic and UI.

UI/UX: Custom mapping systems for price formatting, dynamic color-coding, and "Pull-to-refresh" mechanisms.

Backend & Data (Python)
Core: High-performance data processing.

Networking: Requests/Aiohttp for efficient external API communication.

Reliability: Built-in error handling for "Ghost Wi-Fi" and server-side timeouts.

# 💎 Key Engineering Highlights
Robust Networking: The app handles the common "Failed host lookup" and "DNS latency" issues during cold starts by implementing a smart retry interceptor.

Modular Data Mapping: Uses dedicated DomainDataConvertor logic to handle complex price and volume formatting outside of the UI layer.

Performance: Optimized for smooth scrolling and minimal memory footprint, even with large data lists.

# 📂 Project Structure
/mobile_app — Flutter source code (Clean Architecture).

/microservice — Python backend scripts for data aggregation.
