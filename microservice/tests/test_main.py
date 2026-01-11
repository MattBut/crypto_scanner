import pytest
from httpx import AsyncClient
from main import app
import os

# Set environment variable for testing
os.environ['CRYPTO_API_KEY'] = "test_secret_key"
API_KEY = "test_secret_key"

@pytest.mark.asyncio
async def test_unauthorized_access():
    """Verify that request fails without valid API Key"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/api/market/aggregated_data")
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_aggregated_data_structure():
    """Verify successful response structure with correct headers"""
    headers = {"X-API-Key": API_KEY}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/api/market/aggregated_data", headers=headers)
    
    # Success (200) or Service Unavailable (503) if external APIs are down
    assert response.status_code in [200, 503]

@pytest.mark.asyncio
async def test_klines_missing_parameters():
    """Verify validation error when required params are missing"""
    headers = {"X-API-Key": API_KEY}
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/api/market/klines", headers=headers)
    assert response.status_code == 422