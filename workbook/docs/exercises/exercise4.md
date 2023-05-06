## DevNotes

### ToDo
- [X] Write Objective text
- [ ] Write Exercise text
- [ ] Provide Commands / Scripts
- [ ] Provide Screenshots
-----

# Exercise 4: Creating the Detection Rule & Automation

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #0000ff;
}
</style>

**Estimated Time to Complete:** 30 minutes

## Objectives

* Discover where the blob storage events are located in Sentinel 
* Write a KQL query to find our access of the honeyfile  
* Create a Scheduled query rule leveraging automation for alert enrichment 

## Challenges

### Challenge 1: Analyze Storage Logs with Sentinel

Use Microsoft Sentinel to explore the data being forwarded from our blob storage into the Log Analytic workspace.

??? cmd "Solution"

    1. In your Azure Portal, navigate to the Microsoft Sentinel service and select the instance based on the `securitymonitoring` Log Analytics workspace.
    <!---ALEX:$SCREENSHOT--->

    2. In the ´General´ section on the left panel, select the `Logs` blade. Should you be greeted by the `Queries` dialog, deactivate the `Always show Queries` toggle and close the dialog with the `X` in the upper right corner.  
    <!---ALEX:$SCREENSHOT--->

    3. With the `Logs` blade in front of you, we need to find the table in which our blob storage events are stored: Select the `Tables` tab, open the `LogManagement` node and look for the aptly named `StorageBlobLogs` table.
    <!---ALEX:$SCREENSHOT--->
    
        !!! warning

            If there is no table with this name, the most likely causes are:
                
            1. The diagnostic setting were not properly applied
            
                Check the diagnostic setting for your blob storage from exercise 2 and make sure to select the `securitymonitoring` Log Analytics workspace.
            
            2. Events did not yet arrive in the Log Analytics workspace
    
                It can take a few minutes for events to arrive and be ingested. Use the time to double-check your diagnostic setting for the blob storage and return to Sentinel later. Don´t forget to reload your browser tab should you use multiple tabs! 
        
    4. Either double click on the `StorageBlobLogs` table to load it into the editor, or type out the name of the table yourself. Set the Time range to `Last 4 hours` and press the `Run` button.
    
        <!---ALEX:$SCREENSHOT--->

        !!! summary "Expected result"

            <!---ALEX:$SCREENSHOT--->
    
    
    5. Thats already quite some events! Let´s use [KQL](https://learn.microsoft.com/en-us/azure/data-explorer/kql-quick-reference) and the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/storagebloblogs) to get a better understanding of our data.   

        ```kql
            <!---ALEX:$QUERYS--->
        ```

        !!! summary "Sample result"

            <!---ALEX:$SCREENSHOT--->

    6. At this point we should have a fair understanding of how the data is structured. Great! Now let´s make sure that we can see read events in the data.  

        ```kql
            <!---ALEX:$QUERYS--->
        ```

        !!! summary "Sample result"

            <!---ALEX:$SCREENSHOT--->

### Challenge 2: Write a Detection Query in KQL

We now have the knowledge of `StorageBlobLogs` table structure, an true-positive event in the dataset, and the power of KQL at our fingertips! Build a robust query which can be turned into a Scheduled Analytics Rule, and make sure the [Account Entity](https://learn.microsoft.com/en-us/azure/sentinel/entities-reference#user-account) can be extracted from the alert.     

??? cmd "Solution"

    1. First, refine the query to only find `GetBlob` operations on the honey file in the `secretdata` container of the storage account starting with `productiondatamain`. Verify you get results at this stage.

        ```kql
            <!---ALEX:$QUERYS--->
        ```

        !!! summary "Sample result"

            <!---ALEX:$SCREENSHOT--->

    2. That query would actually already suffice to detect any download of the honey file! However, our goal in this workshop is finding access by Azure AD User Accounts only - investigating storage access authorized via Shared Access Signatures would require forwarding of additional logs unavailable on the free tier. So lets filter on the that.

        ```kql
            <!---ALEX:$QUERYS--->
        ```

        !!! summary "Sample result"

            <!---ALEX:$SCREENSHOT--->

    3. To later configure our Entities in the Scheduled Analytics Rule, we need to surface identifiers for the user account. As stated in the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/sentinel/entities-reference#user-account), the ObjectGUID of the user would already suffice to uniquely identify the Azure AD User Account. But let´s nevertheless surface the name and tenantId in addition to the objectGuid to practice KQL. 

        ```kql
            <!---ALEX:$QUERYS--->
        ```

        !!! summary "Sample result"

            <!---ALEX:$SCREENSHOT--->

### Challenge 3: Create a Scheduled Query Rule with Automation

With your detection query at hand, create a Scheduled Query Rule with an entity mapping for the User Account and triggers the playbook `SentinelIncident-GetEntityInformation` via an incident trigger. 

??? cmd "Solution"

    1. Let's start by looking at your downloaded data. Before that, we need to figure out how to get to the raw data. Since the data is GZIP-compressed, you could extract every one of these files, but there is a better way: using `zcat` to both extract and review the resulant data. View all file content in the `cloudtrail-logs` directory with `zcat`.

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz
        ```

        !!! summary "Expected result"

            WAY TOO MUCH DATA TO SHOW HERE!

    2. That data is quite a lot and is very hard to review manually. Luckily, there is a utility in CloudShell that can rescue you: `jq`. Use `jq` to both present the data in an easier-to-read format and also just view the first record of the first file to see the structure of the log data like so:

        ```bash
        zcat $(ls /home/cloudshell-user/cloudtrail-logs/*.json.gz | head -1) \
         | jq '.Records[0]'
        ```

        !!! summary "Sample results"

            ```bash
            {
            "eventVersion": "1.08",
            "userIdentity": {
                "type": "AWSService",
                "invokedBy": "cloudtrail.amazonaws.com"
            },
            "eventTime": "2023-03-18T10:30:51Z",
            "eventSource": "s3.amazonaws.com",
            "eventName": "GetBucketAcl",
            "awsRegion": "us-east-1",
            "sourceIPAddress": "cloudtrail.amazonaws.com",
            "userAgent": "cloudtrail.amazonaws.com",
            "requestParameters": {
                "bucketName": "cloudlogs-123456789010",
                "Host": "cloudlogs-123456789010.s3.us-east-1.amazonaws.com",
                "acl": ""
            },
            "responseElements": null,
            "additionalEventData": {
                "SignatureVersion": "SigV4",
                "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                "bytesTransferredIn": 0,
                "AuthenticationMethod": "AuthHeader",
                "x-amz-id-2": "pMA3dNprLD8n9BXHH02Z+VIiUGqIWlpn1JNCXBn5dV4Blk7yQ83bz9qG9Qb2E/ljZfpU82mOb80=",
                "bytesTransferredOut": 542
            },
            "requestID": "035F74YAQBE4N0B9",
            "eventID": "82c10c51-1f5d-4de1-b729-4d0c3c45e0d4",
            "readOnly": true,
            "resources": [
                {
                "accountId": "123456789010",
                "type": "AWS::S3::Bucket",
                "ARN": "arn:aws:s3:::cloudlogs-123456789010"
                }
            ],
            "eventType": "AwsApiCall",
            "managementEvent": true,
            "recipientAccountId": "123456789010",
            "sharedEventID": "66965521-4adc-40f5-b23e-ccb05b66bbfb",
            "eventCategory": "Management"
            }
            ```

    3. You may or may not have gotten a record related to a data event. We can fix that by using `jq` to extract only those records where the `managementEvent` is `false`. The command below will grab just data events from the event data using the `select()` filtering option.

        ```bash
        zcat $(ls /home/cloudshell-user/cloudtrail-logs/*.json.gz) \
         | jq -r '. | select(.Records[].managementEvent == false)'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "Records": [
                    {
                        "eventVersion": "1.08",
                        "userIdentity": {
                            "type": "Root",
                            "principalId": "123456789010",
                            "arn": "arn:aws:iam::123456789010:root",
                            "accountId": "123456789010",
                            "accessKeyId": "ASIATAI5Z633YGJXOFXZ",
                            "userName": "ryanryanic",
                            "sessionContext": {
                                "attributes": {
                                    "creationDate": "2023-03-19T04:54:36Z",
                                    "mfaAuthenticated": "false"
                                }
                            }
                        },
                        "eventTime": "2023-03-19T10:57:19Z",
                        "eventSource": "s3.amazonaws.com",
                        "eventName": "ListObjects",
                        "awsRegion": "us-east-1",
                        "sourceIPAddress": "44.202.147.98",
                        "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3.ls]",
                        "requestParameters": {
                            "list-type": "2",
                            "bucketName": "databackup-123456789010",
                            "encoding-type": "url",
                            "prefix": "",
                            "delimiter": "/",
                            "Host": "databackup-123456789010.s3.us-east-1.amazonaws.com"
                        },
                        "responseElements": null,
                        "additionalEventData": {
                            "SignatureVersion": "SigV4",
                            "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                            "bytesTransferredIn": 0,
                            "AuthenticationMethod": "AuthHeader",
                            "x-amz-id-2": "vEFGxniqw03bet/amSETCYdavMQRdTtpYCk+f1GPpsC184l16EZNRMuHBp3nYCUMuSrsyuogRo8ddMv5NtaEvg==",
                            "bytesTransferredOut": 523
                        },
                        "requestID": "5WDT0JW454734NF5",
                        "eventID": "da646419-bad0-4d64-bd4a-1e2b44276299",
                        "readOnly": true,
                        "resources": [
                            {
                                "type": "AWS::S3::Object",
                                "ARNPrefix": "arn:aws:s3:::databackup-123456789010/"
                            },
                            {
                                "accountId": "123456789010",
                                "type": "AWS::S3::Bucket",
                                "ARN": "arn:aws:s3:::databackup-123456789010"
                            }
                        ],
                        "eventType": "AwsApiCall",
                        "managementEvent": false,
                        "recipientAccountId": "123456789010",
                        "eventCategory": "Data",
                        "tlsDetails": {
                            "tlsVersion": "TLSv1.2",
                            "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                            "clientProvidedHostHeader": "databackup-123456789010.s3.us-east-1.amazonaws.com"
                        }
                    }
                ]
            }

            <snip>
            ```

    4. Now we're getting somewhere. You will likely see, if you scroll through the data, the access of the honey file, but let's create one more filter to match just the access of the honey file. To do this, you may have noticed that the file name is included in the `.requestParameters.key` field and the `eventName` is `GetObject`. You can combine both of those cases in the following command:

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz  | \
          jq -r '.Records[] | select((.eventName == "GetObject") and .requestParameters.key == "password-backup.txt")'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "eventVersion": "1.08",
                "userIdentity": {
                    "type": "Root",
                    "principalId": "123456789010",
                    "arn": "arn:aws:iam::123456789010:root",
                    "accountId": "123456789010",
                    "accessKeyId": "ASIATAI5Z633WXL7W5UQ",
                    "userName": "ryanryanic",
                    "sessionContext": {
                        "attributes": {
                            "creationDate": "2023-03-19T04:54:36Z",
                            "mfaAuthenticated": "false"
                        }
                    }
                },
                "eventTime": "2023-03-19T11:00:50Z",
                "eventSource": "s3.amazonaws.com",
                "eventName": "GetObject",
                "awsRegion": "us-east-1",
                "sourceIPAddress": "44.202.147.98",
                "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3.cp]",
                "requestParameters": {
                    "bucketName": "databackup-123456789010",
                    "Host": "databackup-123456789010.s3.us-east-1.amazonaws.com",
                    "key": "password-backup.txt"
                },
                "responseElements": null,
                "additionalEventData": {
                    "SignatureVersion": "SigV4",
                    "CipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "bytesTransferredIn": 0,
                    "AuthenticationMethod": "AuthHeader",
                    "x-amz-id-2": "nKl0ChcIi+IUpXN2b7DHChT9ivctg5wEOC+aoLZBVK8AF5GPuAcUCAco3SETgystQmjyabnMd3o=",
                    "bytesTransferredOut": 91
                },
                "requestID": "X3WAD8N3JFZKSY05",
                "eventID": "7adf0612-f936-4368-bccb-6a2afde40d15",
                "readOnly": true,
                "resources": [
                    {
                    "type": "AWS::S3::Object",
                    "ARN": "arn:aws:s3:::databackup-123456789010/password-backup.txt"
                    },
                    {
                    "accountId": "123456789010",
                    "type": "AWS::S3::Bucket",
                    "ARN": "arn:aws:s3:::databackup-123456789010"
                    }
                ],
                "eventType": "AwsApiCall",
                "managementEvent": false,
                "recipientAccountId": "123456789010",
                "eventCategory": "Data",
                "tlsDetails": {
                    "tlsVersion": "TLSv1.2",
                    "cipherSuite": "ECDHE-RSA-AES128-GCM-SHA256",
                    "clientProvidedHostHeader": "databackup-123456789010.s3.us-east-1.amazonaws.com"
                }
            }
            ```

    5. Now we're down to the single record (unless you downloaded the file multiple times). But that record is still quite busy. Let's extent that filter one final time to extract the following key details about the attacker:

        | Field | Description |
        |:------|:------------|
        | `userIdentity.userName` | The AWS username (IAM user) or account alias (root user) that made the request |
        | `sourceIPAddress` | The client IP address |
        | `eventTime` | The time of the request |
        | `eventName` | The name of the API call |
        | `requestParameters.bucketName` | The name of the S3 bucket where the file is stored |
        | `requestParameters.key` | The name of the downloaded file |
        | `userAgent` | The likely application that interacted with AWS |

        ```bash
        zcat /home/cloudshell-user/cloudtrail-logs/*.json.gz  | \
          jq -r '.Records[] | select((.eventName == "GetObject") and '\
        '.requestParameters.key == "password-backup.txt") | '\
        '{"userName": .userIdentity.userName, '\
        '"sourceIPAddress": .sourceIPAddress, '\
        '"eventTime": .eventTime, '\
        '"bucketName": .requestParameters.bucketName, '\
        '"fileName": .requestParameters.key, '\
        '"userAgent": .userAgent}'
        ```

        !!! summary "Sample result"

            ```bash
            {
                "userName": "ryanryanic",
                "sourceIPAddress": "44.202.147.98",
                "eventTime": "2023-03-19T11:00:50Z",
                "bucketName": "databackup-123456789010",
                "fileName": "password-backup.txt",
                "userAgent": "[aws-cli/2.11.2 Python/3.11.2 Linux/4.14.255-305-242.531.amzn2.x86_64 exec-env/CloudShell exe/x86_64.amzn.2 prompt/off command/s3.cp]"
            }
            ```

## Conclusion

In this exercise, you walked through an example hunt for ATT&CK technique T1530 (Data from Cloud Storage) using a honey file and some slicing and dicing of CloudTrail data events. That was a lot of manual effort. In the next exercise, you will automate this discovery with the assistance of a few cloud services.