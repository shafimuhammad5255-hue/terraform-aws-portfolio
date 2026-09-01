import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    # EventBridge-ൽ നിന്നും വരുന്ന വിവരങ്ങളിൽ നിന്ന് ബക്കറ്റിന്റെ പേര് കണ്ടുപിടിക്കുന്നു
    detail = event.get('detail', {})
    request_parameters = detail.get('requestParameters', {})
    bucket_name = request_parameters.get('bucketName')
    
    if bucket_name:
        print(f"Alert! Public access attempted on bucket: {bucket_name}. Reverting...")
        # പബ്ലിക് ആക്സസ് അപ്പൊൾ തന്നെ ബ്ലോക്ക് ചെയ്യുന്നു (Auto-Remediation)
        s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        return {"status": "Success", "message": f"Secured {bucket_name}"}
    
    return {"status": "Skipped", "message": "No bucket name found in event"}