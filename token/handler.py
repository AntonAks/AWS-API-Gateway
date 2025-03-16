import json
import boto3
import os


def lambda_handler(event, context):
    client = boto3.client('cognito-idp')
    try:
        request_body = json.loads(event['body']) if event.get('body') else {}
    except Exception:
        request_body = {"error": "Invalid JSON"}

    username = request_body.get("username")
    password = request_body.get("password")

    client_id = os.getenv("COGNITO_CLIENT_ID")

    if not username or not password:
        return {
            "statusCode": 400,
            "body": {"error": "Missing username or password"}
        }

    try:
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )

        return {
            "statusCode": 200,
            "body": json.dumps({"token": response['AuthenticationResult']['IdToken']})
        }
    except client.exceptions.NotAuthorizedException:
        return {
            "statusCode": 401,
            "body": json.dumps({"error": "Invalid credentials"})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
