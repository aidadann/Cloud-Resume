# pyrefly: ignore [missing-import]
import azure.functions as func
import json

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="GetVisitorCount")
def GetVisitorCount(req: func.HttpRequest) -> func.HttpResponse:
    visitor_count = 42
    
    response_data = {
        "count": visitor_count
    }

    return func.HttpResponse(
        body=json.dumps(response_data),
        mimetype="application/json",
        status_code=200
    )