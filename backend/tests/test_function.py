import unittest
from unittest.mock import patch, MagicMock
# pyrefly: ignore [missing-import]
import azure.functions as func
import json
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../function_app')))
# Import your function app module
import function_app

class TestGetVisitorCount(unittest.TestCase):

    @patch('function_app.cosmos_client.CosmosClient')
    def test_get_visitor_count(self, mock_cosmos_client):
        # 1. Setup the Mock Database Response
        # We simulate the database already having a visitor count of 5
        mock_container = MagicMock()
        mock_container.read_item.return_value = {"id": "1", "count": 5}
        
        mock_database = MagicMock()
        mock_database.get_container_client.return_value = mock_container
        
        mock_client_instance = MagicMock()
        mock_client_instance.get_database_client.return_value = mock_database
        
        # Tie the mocked client instance to the from_connection_string method
        mock_cosmos_client.from_connection_string.return_value = mock_client_instance

        # 2. Setup the dummy HTTP Request
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/GetVisitorCount'
        )

        # 3. Call the function
        # We patch os.environ so the function doesn't crash looking for a real connection string
        with patch.dict('os.environ', {"CosmosDBConnectionString": "FakeString"}):
            resp = function_app.GetVisitorCount(req)

        # 4. Assert the results
        # Verify the HTTP status code is 200 OK
        self.assertEqual(resp.status_code, 200)
        
        # Decode the JSON body from the response and verify the count incremented correctly
        body = json.loads(resp.get_body().decode('utf-8'))
        self.assertEqual(body['count'], 6) 
        
        # Optional but recommended: Verify that upsert_item was actually called
        mock_container.upsert_item.assert_called_once()