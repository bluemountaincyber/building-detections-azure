## DevNotes

### ToDo
- [X] Write Objective text
- [X] Write Exercise text
- [ ] Provide Commands / Scripts
- [ ] ~~Provide Screenshots~~

-----

# Exercise 3: Creating True-Positive Events 

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #ff0000;
}
</style>

**Estimated Time to Complete:** 10 minutes

## Objectives

* Execute the following techniques to generate true-positive log entries which will help build your detection and automation:
    * Perform discovery of blob storage resources - ATT&CK Technique T1619 (Cloud Storage Object Discovery)
    * Download an interesting file - ATT&CK Technique T1530 (Data from Cloud Storage)

## Challenges

### Challenge 1: Perform ATT&CK Technique T1619 (Cloud Storage Object Discovery)

Using the Azure Cloud Shell, perform reconnaissance of the storage account and the content of its blob containers. You will find that one has some interestingly named data that an attacker may be tempted to download.

??? info "Using the GUI instead"

    This step can also be done via the Azure Portal. However, be aware which credentials are being used when downloading the blob! Make sure the portal is using your Azure AD Login and not the access keys to which it might default to. The mode of access can be seen and changed in the GUI like this: <!---ALEX:screenshot/GIF---> 

??? cmd "Solution"

    1. Return to your Azure Cloud Shell session (you may need to refresh the page if it timed out).

    2. Discovering cloud resources in Azure is best done with the `az` command. Following the pattern of `az` - `reference name` - `command` we can quickly navigate through our storage accounts, containers, and content. Let´s first check what storage accounts we can see.

        ```powershell
        <!---ALEX:commands---> 
        ```

        !!! summary "Sample results"

            ```powershell
             <!---ALEX:sampleoutput---> 
            ```

    3. You should see two storage accounts: one beginning with `cs-` and one beginning with `productiondata-`. We will ignore the first storage account, as it´s just the one which your Azure Cloud Shell uses to persist data. So, what content awaits us in the `productiondata-` storage account?   

        ```powershell
        <!---ALEX:commands---> 
        ```

        !!! summary "Expected result"

            ```powershell
             <!---ALEX:sampleoutput---> 
            ```

    4. `hr-documents` and *`secretdata`*? I wonder what´s in there. Let us list the content of those containers. 

        ```powershell
        <!---ALEX:commands---> 
        ```

        !!! summary "Sample result"

            ```powershell
             <!---ALEX:sampleoutput---> 
            ```

    5. Looks like some job postings in the `hr-documents` container. Nothing out of the ordinary. But `secretdata` has something more interesting: `final-instructions.txt`.

        ??? tip "I wonder..." 
            ![](../img/ex3-ch1-attention.gif ""){: class="w600" }

### Challenge 2: Perform ATT&CK Technique T1530 (Data from Cloud Storage)

That certainly looks like something an adversary could not leave untouched. And to be fair, neither can we 😉. Let´s download this file to our Azure Cloud Shell session! 

??? cmd "Solution"

    1. Downloading can be easily achieved with the `az` command and the right parameters. For the purpose of this workshop we want to make sure we use our Azure AD User Account for authentication, and not the access keys.   

        ```powershell
        <!---ALEX:commands---> 
        ```

        !!! summary "Sample result"

            ```powershell
             <!---ALEX:sampleoutput---> 
            ```

    2. Just one more step and we can see what the final instructions are!

        ```powershell
        <!---ALEX:commands---> 
        ```

        !!! summary "Sample result"

            ```powershell
             <!---ALEX:sampleoutput---> 
            ```
            Somehow I expected it would not be that easy.

    3. Congratulations! You have just emulated an attacker finding a file or interest, downloading it, and reviewing it. We could now spend our time deciphering the message, but that is not what we are here for - so let´s move on 😊. 

## Conclusion

Now that you have successfully located and pulled down the honey file, the next exercise will explore how to identify this access.
