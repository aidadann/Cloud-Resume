# pyrefly: ignore [missing-import]
import azure.functions as func
import json
import os
import logging
# pyrefly: ignore [missing-import]
import azure.cosmos.cosmos_client as cosmos_client
# pyrefly: ignore [missing-import]
from azure.cosmos.exceptions import CosmosResourceNotFoundError

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="GetVisitorCount")
def GetVisitorCount(req: func.HttpRequest) -> func.HttpResponse:
    try:
        connection_string = os.environ["CosmosDBConnectionString"]
        
        client = cosmos_client.CosmosClient.from_connection_string(connection_string)
        database = client.get_database_client("ResumeDB")
        container = database.get_container_client("Counter")
        
        try:
            item = container.read_item(item="1", partition_key="1")
            item['count'] += 1
        except CosmosResourceNotFoundError:
            logging.info("Counter document not found. Initializing at 1.")
            item = {
                "id": "1",
                "count": 1
            }
        
        container.upsert_item(body=item)
        
        return func.HttpResponse(
            body=json.dumps({"count": item['count']}),
            mimetype="application/json",
            status_code=200
        )
        
    except Exception as e:
        logging.error(f"Database operation failed: {str(e)}")
        return func.HttpResponse(
            body=json.dumps({"error": "Failed to fetch or update visitor count"}),
            mimetype="application/json",
            status_code=500
        )