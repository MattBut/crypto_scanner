# Crypto Investment Data Aggregator

A high-performance FastAPI microservice that aggregates real-time cryptocurrency data from **Bybit** and **CoinGecko**. It features server-side caching, API Key protection, and is fully containerized.

## 🚀 Key Features
* **Data Aggregation:** Merges spot market prices from Bybit with market cap metadata from CoinGecko.
* **Performance:** Implements in-memory caching to reduce external API calls and latency.
* **Security:** Protected by mandatory API Key validation via request headers.
* **Asynchronous:** Built with `asyncio` and `httpx` for non-blocking I/O.
* **Reliability:** Includes an automated test suite with `pytest`.

## 🛠 Tech Stack
* **Framework:** FastAPI
* **HTTP Client:** HTTPX (Async)
* **Testing:** Pytest / Pytest-asyncio
* **Environment:** Conda / Docker
* **Web Server:** Uvicorn

---

## 🏗 Setup, Running & Testing

1. **Environment Configuration:**
   Create a `.env` file in the root directory based on the example:
   ```bash
   cp .env.example .env
   # Edit .env and add your CRYPTO_API_KEY

2. **Local Development (Conda):**
   ```bash
   conda create --name crypto_scanner python=3.10
   conda activate crypto_scanner
   pip install -r requirements.txt
   uvicorn main:app --reload

3. **Docker Deployment:**
   ```bash
   # Build the image
   docker build -t crypto-aggregator .
   # Run the container
   docker run -d -p 8000:8000 --env-file .env --name crypto-app crypto-aggregator

4. **Execution of Tests: The project uses pytest for integration testing to verify authentication and data logic:**
   ```bash
   pytest

## 📡 API Endpoints (Quick Reference)
   GET /api/market/aggregated_data — Get merged Bybit/CoinGecko data.
   GET /api/market/klines — Get historical candlestick data.
   Note: All requests require X-API-Key header.

## 📝 License
MIT License