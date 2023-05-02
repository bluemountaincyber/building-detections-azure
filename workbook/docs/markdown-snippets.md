# Exercise 1: Markdown Snippets

## Challenges

### Challenge 1: Title of the challenge 

Description of what should be done in this step

??? cmd "Solution"

    1. Just a step

    2. Step with Code Example

        ```powershell
        az storage account list | jq .
        az storage container list --account-name productiondatamain --auth-mode login | jq .
        az storage blob list --account-name productiondatamain --container-name secretdata --auth-mode login | jq .
        ```

    3. Step with Code Example and Expected Result Call-Out

        ```bash
        BUCKET=$(aws s3api list-buckets | jq -r \
          '.Buckets[] | select(.Name | startswith("cloudlogs-")) | .Name')
        aws s3 ls s3://$BUCKET/
        ```

        !!! summary "Expected result"

            ```bash
                                       PRE AWSLogs/
            ```

    4. Step with Code Example and Sample Result Call-Out

        ```bash
        BUCKET=$(aws s3api list-buckets | jq -r \
          '.Buckets[] | select(.Name | startswith("databackup-")) | .Name')
        aws s3 ls s3://$BUCKET/
        ```

        !!! summary "Sample result"

            ```bash
            2023-03-19 10:16:30         91 password-backup.txt
            ```

    5. Step with a Warning and extra text - mind the new line between text and warning

        !!! warning

            Warning Message followed by a Call-Out

            !!! summary "Failed deployment"

                More text to put between summary and the codeblock
            
                ```bash
                Failed to create/update the stack. Run the following command
                to fetch the list of events leading up to the failure
                aws cloudformation describe-stack-events --stack-name building-detections
                ```
            
            Block of code after the summary

            ```bash
            aws cloudformation delete-stack --stack-name building-detections
            aws securityhub disable-security-hub
            ```

### Challenge 2: Title of the next challenge

Description of the second challenge with a table

| Field | Description |
|:-------|-------------|
| `userIdentity.userName` | The AWS username (IAM user) or account alias |
| `sourceIPAddress` | The client IP address |


## Conclusion

Finishing up the exercise with a summary