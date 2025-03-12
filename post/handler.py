import json
import datetime


def lambda_handler(event, context):
    try:
        request_body = json.loads(event['body']) if event.get('body') else {}
    except Exception:
        request_body = {"error": "Invalid JSON"}

    return {
        "statusCode": 201,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Your data was saved successfully! (Test POST response)",
            "received": request_body,
            "time": datetime.datetime.now().isoformat()
        })
    }