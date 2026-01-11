# Crypto Investor Mobile

A professional Flutter application for real-time cryptocurrency tracking. Built with a robust architecture using **Riverpod** for state management and **Dio** for resilient networking.

## 🚀 Features
* **Real-time Data:** Live price tracking and market insights via FastAPI backend.
* **Resilient Networking:** Advanced HTTP client with automatic request retries and connection monitoring.
* **Local Persistence:** On-device data storage using **SQLite** for offline access.
* **State Management:** Modern, reactive state handling with compile-time safety.
* **Clean UI:** Material Design implementation with custom loaders and asset management.

## 🛠 Tech Stack
* **State Management:** `flutter_riverpod`
* **Networking:** `dio` with `dio_smart_retry` & `internet_connection_checker_plus`
* **Database:** `sqflite` (with `path_provider` for storage)
* **Dependency Injection:** `get_it`
* **UI Utilities:** `flutter_spinkit`, `flutter_easyloading`, `cached_network_image`
* **Architecture Tools:** `equatable`, `intl`, `logger`, `flutter_dotenv`

## 🏗 Setup, Running & Testing

1. **Prerequisites:**
   * Flutter SDK: `>=3.4.3 <4.0.0`
   * Backend Service: Ensure the [Crypto Microservice](../microservice) is running.

2. **Installation & Configuration:**
   ```bash
   cd mobile_app
   flutter pub get

3. **Create a .env file in the mobile_app/ root:**
   
   API_BASE_URL=http://your-api-url:8000

   CRYPTO_API_KEY=your_secret_key

5. **Running the App:**  
   ```bash
   # Generate code (if using mockito/riverpod generators)
   flutter pub run build_runner build 

6. **Launch the application**
   ```bash
   flutter run

7. **Execution of Tests: The project includes unit and mock tests using mockito to ensure business logic reliability:**
   ```bash
   flutter test

## 📝 License
   MIT License
