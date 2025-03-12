import json
import datetime

def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "This is the test message from the GET endpoint. Everything works fine!",
            "time": datetime.datetime.now().isoformat()
        })
    }