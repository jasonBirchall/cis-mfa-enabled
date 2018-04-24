import json
import boto3
import datetime

FIELD_ACCESS_KEY_1_ACTIVE = 8
FIELD_ACCESS_KEY_2_ACTIVE = 13

def lambda_handler(event, context):

is_compliant = True
annotation = ''

invoking_event = json.loads(event['invokingEvent'])
result_token = 'No token found.'
if 'resultToken' in event: result_token = event['resultToken']

client = boto3.client('iam')

# Determine whether the root account has MFA enabled.
summary = client.get_account_summary()['SummaryMap']
if 'AccountMFAEnabled' in summary and summary['AccountMFAEnabled'] == 1:
    is_compliant = is_compliant and True
else:
    is_compliant = is_compliant and False
    annotation = annotation + ' The root account does not have MFA enabled.'

# Determine whether the root account uses hardware-based MFA.
mfa_devices = client.list_virtual_mfa_devices()['VirtualMFADevices']
for mfa_device in mfa_devices:
    if not 'SerialNumber' in mfa_device:
        is_compliant = is_compliant and True
    else:
        is_compliant = is_compliant and False
        annotation = annotation + ' The root account does not have hardware-based MFA enabled.'

# Determine whether the root account has active access keys.
# The credential report will contain comma-separated values, so transform the users into a list.
response = client.generate_credential_report()
content = client.get_credential_report()['Content']
users = content.splitlines()

# Look for the '<root_account>' user value and determine whether acccess keys are active.
for user in users:
    if '<root_account>' in user:
        user_values = user.split(',')
        if user_values[FIELD_ACCESS_KEY_1_ACTIVE].lower() == 'false' and user_values[FIELD_ACCESS_KEY_2_ACTIVE].lower() == 'false':
            is_compliant = is_compliant and True
        else:
            is_compliant = is_compliant and False
            annotation = annotation + ' The root account has active access keys associated with it.'
        break

config = boto3.client('config')
config.put_evaluations(
    Evaluations=[
        {
            'ComplianceResourceType': 'AWS::::Account',
            'ComplianceResourceId': 'Root',
            'ComplianceType': 'COMPLIANT' if is_compliant else 'NON_COMPLIANT',
            'Annotation': annotation,
            'OrderingTimestamp': datetime.datetime.now(),
        },
    ],
    ResultToken=result_token
)