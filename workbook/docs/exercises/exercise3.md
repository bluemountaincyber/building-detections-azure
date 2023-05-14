## DevNotes

### ToDo
- [X] Write Objective text
- [X] Write Exercise text
- [X] Provide Commands / Scripts
- [X] Provide Screenshots

-----

# Exercise 3: Creating True-Positive Events 

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #ff0000;
}
</style>

**Estimated Time to Complete:** 20 minutes

## Objectives

* Execute the following techniques to generate true-positive log entries which will help build your detection and automation:
    * Perform discovery of blob storage resources - ATT&CK Technique T1619 (Cloud Storage Object Discovery)
    * Download an interesting file - ATT&CK Technique T1530 (Data from Cloud Storage)

## Challenges

### Challenge 1: Perform ATT&CK Technique T1619 (Cloud Storage Object Discovery)

Using the Azure Cloud Shell, perform reconnaissance of the storage account and the content of its blob containers. You will find that one has some interestingly named data that an attacker may be tempted to download.

??? cmd "Solution"

    1. Return to your Azure Cloud Shell session (you may need to refresh the page if it timed out).

    2. Discovering cloud resources in Azure is best done with the `az` command. Following the pattern of `az` - `reference name` - `command` we can programmatically interact with our cloud resources. First, verify which user the `az` tool is logged in with.

        ```powershell
        az account show | jq .user
        ```

        ??? summary "Sample results"

            ```json
            {                                                         
              "cloudShellID": true,
              "name": "abraulik@XXXXXXXXXX.onmicrosoft.com",
              "type": "user"
            }
            ```

    3. Now to your storage account in your **DetectionWorkshop** resource group. We pipe the result to jq and only want to see the `name` values of the returning items.

        ```powershell
        az storage account list --resource-group 'DetectionWorkshop' | jq .[].name 
        ```

        ??? summary "Sample results"

            ```
            "proddatadj35l13m5693m5" 
            ```

    4.  You should see a storage account beginning with `proddata` followed by some randomized numbers and lowercase characters. The storage account name is randomized for every run of the deployment script because storage account name need to be *GLOBALLY* unique. You want to store the name of your storage account (pun intended) in a variable to make the next steps easier to execute.

        ```powershell
        Write-Output ($storageAccount = az storage account list --resource-group 'DetectionWorkshop' | jq -r '.[] | select(.name | startswith("proddata")) | .name' ) 
        ``` 

        ??? summary "Sample results"

            ```
            proddatadj35l13m5693m5 
            ```

    5. So, what content awaits us in this storage account?   

        ```powershell
        az storage container list --account-name $storageAccount --auth-mode login | jq .
        ```

        ??? summary "Expected result"

            ```json
            [                                                         
                {
                    "deleted": null,
                    "encryptionScope": {
                        "defaultEncryptionScope": "$account-encryption-key",
                        "preventEncryptionScopeOverride": false
                    },
                    "immutableStorageWithVersioningEnabled": false,
                    "metadata": null,
                    "name": "hr-documents",
                    "properties": {
                        "etag": "\"0x8DB4B0EE81F1ED0\"",
                        "hasImmutabilityPolicy": false,
                        "hasLegalHold": false,
                        "lastModified": "2023-05-02T13:12:39+00:00",
                        "lease": {
                            "duration": null,
                            "state": "available",
                            "status": "unlocked"
                        },
                        "publicAccess": null
                    },
                    "version": null
                },
                {
                    "deleted": null,
                    "encryptionScope": {
                        "defaultEncryptionScope": "$account-encryption-key",
                        "preventEncryptionScopeOverride": false
                    },
                    "immutableStorageWithVersioningEnabled": false,
                    "metadata": null,
                    "name": "secretdata",
                    "properties": {
                        "etag": "\"0x8DB475AB5520450\"",
                        "hasImmutabilityPolicy": false,
                        "hasLegalHold": false,
                        "lastModified": "2023-04-27T20:05:11+00:00",
                        "lease": {
                            "duration": null,
                            "state": "available",
                            "status": "unlocked"
                        },
                        "publicAccess": null
                    },
                    "version": null
                }
            ]
            ```

    5. Looking at the `name` values here: `hr-documents` and `secretdata`? I wonder what´s in those containers...Let's list the content of those containers. 

        ```powershell
        az storage blob list --account-name $storageAccount --container 'hr-documents' --auth-mode login | jq .[].name
        ```

        ??? summary "Expected result"

            ```json
            "job-posting-personalassistent-draft.txt"
            "job-posting-secops-azure-draft.txt"
            ```

        ```powershell
        az storage blob list --account-name $storageAccount --container 'secretdata' --auth-mode login | jq .[].name
        ```

        ??? summary "Expected result"

            ```json
            "final-instructions.txt" 
            ```

    6. Looks like some job postings in the `hr-documents` container. Nothing out of the ordinary. But `secretdata` has something more interesting: `final-instructions.txt`.

        ??? tip "I wonder..." 
            ![](../img/ex3-ch1-attention.gif ""){: class="w600" }

### Challenge 2: Perform ATT&CK Technique T1530 (Data from Cloud Storage)

That certainly looks like something an adversary could not leave untouched. And to be fair, neither can we 😉. Let´s download this file to our Azure Cloud Shell session! 

??? cmd "Solution"

    1. Downloading can be easily achieved with the `az` command and the right parameters. For the purpose of this workshop we want to make sure we use our Azure AD User Account for authentication.   

        ```bash
        az storage blob download --account-name $storageAccount --container-name 'hr-documents' --name 'job-posting-personalassistent-draft.txt' --file '~/ex3-hr-data-job-posting-personalassistent-draft.txt' --auth-mode login | jq . ; az storage blob download --account-name $storageAccount --container-name 'hr-documents' --name 'job-posting-secops-azure-draft.txt' --file '~/ex3-hr-documents-job-posting-secops-azure-draft.txt' --auth-mode login | jq . ;az storage blob download --account-name $storageAccount --container-name 'secretdata' --name 'final-instructions.txt' --file '~/ex3-secretdata-final-instructions.txt' --auth-mode login | jq .
        ```

        ??? summary "Sample result"

            ```json
            Finished[#############################################################]  100.0000%
            {
            "container": "hr-documents",
            "content": "",
            "contentMd5": null,
            "deleted": false,
            "encryptedMetadata": null,
            "encryptionKeySha256": null,
            "encryptionScope": null,
            "hasLegalHold": null,
            "hasVersionsOnly": null,
            "immutabilityPolicy": {
                "expiryTime": null,
                "policyMode": null
            },
            "isAppendBlobSealed": null,
            "isCurrentVersion": null,
            "lastAccessedOn": null,
            "metadata": {},
            "name": "job-posting-personalassistent-draft.txt",
            ---- SNIP ----
            }
            Finished[#############################################################]  100.0000%
            {
            "container": "hr-documents",
            "content": "",
            "contentMd5": null,
            "deleted": false,
            "encryptedMetadata": null,
            "encryptionKeySha256": null,
            "encryptionScope": null,
            "hasLegalHold": null,
            "hasVersionsOnly": null,
            "immutabilityPolicy": {
                "expiryTime": null,
                "policyMode": null
            },
            "isAppendBlobSealed": null,
            "isCurrentVersion": null,
            "lastAccessedOn": null,
            "metadata": {},
            "name": "job-posting-secops-azure-draft.txt",
            ---- SNIP ----
            }
            Finished[#############################################################]  100.0000%
            {
            "container": "secretdata",
            "content": "",
            "contentMd5": null,
            "deleted": false,
            "encryptedMetadata": null,
            "encryptionKeySha256": null,
            "encryptionScope": null,
            "hasLegalHold": null,
            "hasVersionsOnly": null,
            "immutabilityPolicy": {
                "expiryTime": null,
                "policyMode": null
            },
            "isAppendBlobSealed": null,
            "isCurrentVersion": null,
            "lastAccessedOn": null,
            "metadata": {},
            "name": "final-instructions.txt",
            ---- SNIP ----
            }
            ```

    2. Just one more step and we can see what the final instructions are!

        ```powershell
        Get-Content ~/ex3-secretdata-final-instructions.txt 
        ```

        ??? summary "Sample result"

            ```
            When all is done:
            ---- SNIP ----
            ```
            Somehow I expected it would not be that easy.

    3. Congratulations! You have just emulated an attacker finding a file or interest, downloading it, and reviewing it. We could now spend our time deciphering the message, but that is not what we are here for - so let´s move on 😊. 

## Conclusion

Now that you have successfully located and pulled down the honey file, the next exercise will explore how to identify this access.
