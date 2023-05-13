## DevNotes

### ToDo
- [X] Write Objective text
- [X] Write Exercise text
- [X] Provide Commands / Scripts
- [ ] Provide Screenshots

-----

# Exercise 5: Testing the Detection Rule & Automation

<!-- markdownlint-disable MD007 MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #880ED4;
}
</style>

**Estimated Time to Complete:** 20 minutes

## Objectives
* Perform T1530 (Data from Cloud Storage) with a service principal to trigger the Scheduled Rule
* Review the Incident created by the Scheduled Rule and verify that the automation added investigation tasks 

## Challenges

### Challenge 1: Perform T1530 as another user

Perform the same attack as before from the Azure Cloud Shell, but use a service principal instead of your Azure AD user account this time.

??? cmd "Solution"

    1. Return to your Azure Cloud Shell session (you may need to refresh the page if it timed out).

    2. First we need to change the principal az is using to access the storage. In your Azure Cloud Shell run the `az login` command with the credentials of the service principal. 

        ```powershell
        az login --service-principal -u '<>' -p '<>' --tenant '<>' | jq .[].user 
        ```

        !!! summary "Sample results"

            ```sql
            {
              "name": "dj49flw9-d834-mfde-ldo1-39fh3091dk3s",
              "type": "servicePrincipal"
            }
            ```

    3. As we already did this attack before, lets optimize our commands a bit to make this easier. First, we will again list our storage accounts and the container content.   

        ```powershell
        Write-Output ($storageAccount = az storage account list --resource-group 'DetectionWorkshop' | jq -r '.[] | select(.name | startswith("prod")) | .name'); Write-Output ($containerNamesArray = az storage container list --account-name $storageAccount --auth-mode login | jq -r '.[].name')
        ```

        !!! summary "Sample result"

            ```
            proddatadj35l13m5693m5
            hr-documents
            secretdata
            ```

    4. Now run the following command which creates a folder in your homedirectory called `exercise5_loot` and downloads all the blobs from the `hr-document` and `secretdata`.

        ```powershell
        New-Item -Path '~/' -Name "exercise5_loot" -ItemType "directory"; $containerNamesArray | foreach-object {az storage blob download-batch --account-name $storageAccount --source $_ --destination ~/exercise5_loot/ --overwrite true --auth-mode login | jq .}
        ```

        !!! summary "Sample result"

            ```
                Directory: /home/alex

            UnixMode   User             Group                 LastWriteTime           Size Name
            --------   ----             -----                 -------------           ---- ----
            drwxr-xr-x alex             alex                5/13/2023 20:28           4096 exercise5_loot
            Finished[#############################################################]  100.0000%
            [
            "job-posting-personalassistent-draft.txt",
            "job-posting-secops-azure-draft.txt"
            ]
            Finished[#############################################################]  100.0000%
            [
            "final-instructions.txt"
            ]
            ```

    5. And a final command to verify that we got the blobs successfully by outputting their content.

        ```powershell
        Get-ChildItem -Path '~/exercise5_loot' | foreach-object {$_.Name + ":"; (Get-Content $_) + "`n"}
        ```

        !!! summary "Sample result"

            ```
            final-instructions.txt:
            When all is done:
            ---- SNIP ----

            job-posting-personalassistent-draft.txt:
            Are you looking for a challenging and rewarding career as a personal assistant? Do you have a keen eye for details, a sharp mind for solving problems, and a passion for adventure? If so, you might be the perfect candidate for working with the world's most famous detective, Sherlock Holmes!
            ---- SNIP ----

            job-posting-secops-azure-draft.txt:
            Are you a passionate and experienced cyber security engineer who loves solving complex problems and protecting valuable data? Do you have a strong background in Azure cloud services and security best practices? Do you want to work with one of the most brilliant and famous detectives in the world?
            ---- SNIP ---- 
            ```

### Challenge 2: Review the Sentinel Incident

Review the Sentinel Incident created by our Scheduled Rule. Verify the true-positive, that both Entities have been identified and that the Automation added the investigation tasks.   

??? cmd "Solution"

    1. Navigate to the Incident blade in Sentinel, located in the `Threat management` section. You should see an incident created by our Scheduled Query rule. You might have multiple, should you have run the previous script multiple times. Clicking on any of them will bring out the incident overview to your right. Click on the `View full details` button.    

        ![](../img/placeholder.png ""){: class="w600" }

        ??? note "No incident visible?"
            
            If no incident was triggered by our Scheduled Rule, you can re-set the schedule of the rule. The easiest way to achieve this is by disabling and re-enabling the rule. Navigate to the Analytics blade, click on the three dots to the right of your rule and select Disable/Enable.


            ![](../img/ex5-ch3-reboot.gif ""){: class="w500" }


            Remember that at least 5 minutes need to pass between your action and the run the Scheduled Query rule for it to be able to find the events.


            Don´t know what to do while you wait? Go back to our logs in Sentinel and search for events in our BlobStorageLogs table. Some entries will have the `AuthorizationDetails` populated and some are not. Try to figure out in which case you will not have this field, and check with the Microsoft documentation if your guess was right 😉.

    2. Walking trough all the different components and aspects of the Incident details would be a full-day workshop itself, so we will focus on two aspects: tasks and entities.

        ![](../img/placeholder.png ""){: class="w600" }

    3. Let´s first see if our Automation added our investigation steps. Locate the `Tasks` section on the left pane and click on `View full details`. A new pane on your right will appear, showing your tasks for this incident type.

        Even simple information like those three steps can already help immensely when dealing with incidents!

        ![](../img/placeholder.png ""){: class="w600" }

    4. Now with some guidance provided to us, we´ll check if our IP and Azure resource mapping was successful and how it might help us investigate this incident. In the incident details view, locate the `Entities` section on the left pane and select the IP. You will be brought to a new blade with information about the IP used in our attack.

        ![](../img/placeholder.png ""){: class="w600" }

        This kind of view, where information from different sources about an entity is presented, is an efficient method to establish situational awareness and makes `pivoting` while investigating a lot easier!  

    5. Time to return to the incident. The easiest (and reliable) way to navigate back is by using the "breadcrumbs" in the upper left corner. Click on the last item `incident` and you will be at the incident detail view again.

        ![](../img/placeholder.png ""){: class="w600" }

        Feel free to look around the various section, features and the Azure resource entity on your own.    

## Conclusion

Congrats! You have successfully built a detection to spot an adversary accessing a honey file! More importantly, you have walked though a process to create a detection:

![Detection Build Process](../img/detection-build-process.png ""){: class="w600" }