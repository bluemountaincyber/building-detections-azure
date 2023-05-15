## DevNotes

### ToDo
- [X] Write Objective text
- [X] Write Exercise text
- [X] Provide Commands / Scripts
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
* Create a Scheduled query rule based on the KQL query
* Configure an Automation to assist security analysts in their investigation


## Challenges

### Challenge 1: Analyze Storage Logs with Sentinel

Use Microsoft Sentinel to explore the data being forwarded from our blob storage into the Log Analytic workspace.

??? cmd "Solution"

    1. From the Azure Portal homepage, type `Sentinel` in the searchbox at the top of the portal (1) and select **Microsoft Sentinel** under the **Services** category (2).

        ![](../img/20.png ""){: class="w400" } 
    
    2. On the next page, select the instance based on the **securitymonitoring** Log Analytics workspace.
        
        ![](../img/21.png ""){: class="w600" }

    3. In the **General** section on the left panel, select the **Logs** blade.

        ![](../img/22.png ""){: class="w400" }

        !!! note 
        
            If you are greeted by the **Queries** dialog, deactivate the **Always show Queries** toggle (1) and close the dialog with the `X` in the upper right corner (2).  
        
            ![](../img/23.png ""){: class="w600" }

    4. With the **Logs** blade in front of you, we need to find the table in which our blob storage events are stored. Begin by expanding the **Schema and Filter** bar on the left of the main panel. 

        ![](../img/24.png ""){: class="w200" }
    
    5. With the pane expanded, select the **Tables** tab, open the **LogManagement** node and look for the aptly named **StorageBlobLogs** table.
        
        ![](../img/placeholder.png ""){: class="w600" }
    
        !!! warning

            If there is no table with this name, the most likely causes are:
                
            1. The diagnostic setting were not properly applied
            
                Check the diagnostic setting for your blob storage from exercise 2 and make sure to select the `securitymonitoring` Log Analytics workspace.
            
            2. Events did not yet arrive in the Log Analytics workspace
    
                It can take a few minutes for events to arrive and be ingested. Use the time to double-check your diagnostic setting for the blob storage and return to Sentinel later. Don´t forget to reload your browser tab should you use multiple tabs! 
        
    4. Either double click on the `StorageBlobLogs` table to load it into the editor, or type out the name of the table yourself. Set the Time range to `Last 4 hours` and press the `Run` button.
    
        ![](../img/placeholder.png ""){: class="w600" }

        ??? summary "Sample result"

            ![](../img/placeholder.png ""){: class="w600" }
    
    
    5. Thats already quite some events! Let´s use [KQL](https://learn.microsoft.com/en-us/azure/data-explorer/kql-quick-reference) and the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/storagebloblogs) to get a better understanding of our data.   

        ```sql
        StorageBlobLogs
        | summarize count() by AccountName, Protocol, OperationName
        ```

        ??? summary "Sample result"

            ![](../img/placeholder.png ""){: class="w600" }

    6. At this point we should have a fair understanding of how the data is structured. Great! Now let´s make sure that we can see read events in the data.  

        ```sql
        StorageBlobLogs
        | where OperationName == "GetBlob"
        ```

        ??? summary "Sample result"

            ![](../img/placeholder.png ""){: class="w600" }

### Challenge 2: Write a Detection Query in KQL

We now have the knowledge of `StorageBlobLogs` table structure, an true-positive event in the dataset, and the power of KQL at our fingertips! Build a robust query which can be turned into a Scheduled Analytics Rule, and make sure the [IP Entity](https://learn.microsoft.com/en-us/azure/sentinel/entities-reference#ip-address) and [Azure Resource](https://learn.microsoft.com/en-us/azure/sentinel/entities-reference#azure-resource) can be extracted from the alert.     

??? cmd "Solution"

    1. First, refine the query to only find `GetBlob` operations on the 'final-instructions.txt' honey file in the storage account starting with `proddata`. Verify you get results at this stage.

        ```sql
        StorageBlobLogs
        | where AccountName startswith "proddata"
        | where OperationName == "GetBlob"
        | where ObjectKey endswith "final-instructions.txt"
        ```

        ??? summary "Sample result"

            ![](../img/placeholder.png ""){: class="w600" }

    2. To later configure our Entities in the Scheduled Analytics Rule, we need to have strong identifiers. As stated in the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/sentinel/entities-reference), this would the IP address for the IP Entity and the Resource ID for the Azure resource. The later is already directly available in the `_ResourceId` field. However for the IP Address we would need to strip the port from the `CallerIpAddress` field, which we can achieve by using `split()`    

        ```sql
        StorageBlobLogs
        | where AccountName startswith "proddata"
        | where OperationName == "GetBlob"
        | where ObjectKey endswith "final-instructions.txt"
        | extend AttackerIP = split(CallerIpAddress,':')[0]
        | sort by TimeGenerated desc
        ```

        ??? summary "Sample result"

            ![](../img/placeholder.png ""){: class="w600" }

### Challenge 3: Create a Scheduled Query Rule

With your detection query at hand, create a Scheduled Query Rule with an entity mapping for the IP address  of the caller and the Azure resource. 

??? cmd "Solution"

    1. Select the Analytics blade in the Configuration section on the left navigation pane. Once loaded, start the Analytics rule wizard by selecting `Scheduled query rule` under the `Create` dropdown.  

        ![](../img/placeholder.png ""){: class="w600" }

    2. First we need to provide some general information about our rule. Fill out the fields as followed and when done, click `Next: Set rule logic >`   
        
        - **Name**
        
            The human readable name which we give to our rule.

            > StorageAccounts - BlobRead operation on sensitive file detected

        - **Description**

            It is highly advised to provide additional information about the rule. Such as the intended detection use case, what a true-positive would indicate, or circumstances which could lead to an false-positive.        

            > Detects when a file in a sensitive Blob Storage location is read. This can indicate stolen user credential or an insider threat. False-positives can be triggered by legitimate file access operations.
                    
        - **Tactics and techniques**
        
            Mapping your rules to the [MITRE ATT&CK framework](https://attack.mitre.org/matrices/enterprise/) helps you keep track of your detection coverage.  

            > Discovery, T1619 - Cloud Storage Object Discovery
    
        ??? summary "Expected Result"

            ![](../img/placeholder.png ""){: class="w600" }

    3. Here we have to fill out quite some fields, so let´s take it step by step. Start by providing our KQL query and hit the `View query results` button. We expect to see the same results as before.

        ```sql
        StorageBlobLogs
        | where AccountName startswith "proddata"
        | where OperationName == "GetBlob"
        | where ObjectKey endswith "final-instructions.txt"
        | extend AttackerIP = split(CallerIpAddress,':')[0]
        | sort by TimeGenerated desc
        ```

        ![](../img/placeholder.png ""){: class="w600" }

        Unfold the Entity mapping section and create 2 entities, IP and Azure resource. Map Address to `AttackerIP` for the IP entity, and ResourceId to `_ResourceId` for the Azure resource entity.

        ![](../img/placeholder.png ""){: class="w600" }

        For the Query scheduling, select 15 Minutes for both parameters - the first controls the schedule, the second how far the query should look back. Be aware that Sentinel has a built-in 5 min delay, i.e. a query running at time T with lookup of 15 minutes will query for data from T-5 min back to T-20 min.       
        
        ![](../img/placeholder.png ""){: class="w600" }
        
        For the purpose of our workshop, set the Event grouping to `Trigger an alert for each event`.  

        ![](../img/placeholder.png ""){: class="w600" }

        ??? summary "Expected Result"

            ![](../img/placeholder.png ""){: class="w600" }

    4. Not much to do for us on the next view, except verifying that Incident settings are `Enabled` and Alert grouping is `Disabled`.

        ??? summary "Expected Result"

            ![](../img/placeholder.png ""){: class="w600" }

    5. Here we could already configure our Automation, but let´s finish creating our detection first and attach the Automation in the next section.

        ??? summary "Expected Result"

            ![](../img/placeholder.png ""){: class="w600" }

    6. At this step Sentinel does one final validation of our inputs - and so should we. When our rule passes the validation we hit the `create` button and thus exit the wizard.     

        ??? summary "Expected Result"

            ![](../img/placeholder.png ""){: class="w600" }

    7. You should be brought back to the Analytics blade and see your newly created Scheduled Query Rule.
 
        ??? summary "Expected Result"

            ![](../img/placeholder.png ""){: class="w600" }

### Challenge 4: Automate the creation of investigation tasks

When writing detections, it is important to think about how the alerts generated by those detections should be handled. Create a Automation which adds investigation tasks to incidents created by your Scheduled Query rule.    

??? cmd "Solution"

    1. Select the Automation blade in the Configuration section on the left navigation pane. Once loaded, start the Automation rule creation wizard by selecting `Automation rule` under the `Create` dropdown. Compared to the Scheduled Query rule this is a rather short wizard.

        ![](../img/placeholder.png ""){: class="w600" }

    2. Give the Automation an appropriate `name` (e.g. "Add Tasks - Suspicious data access playbook") and select `When incident is created` as the Trigger. As a condition, select the name of your Scheduled Query rule.   

        ![](../img/placeholder.png ""){: class="w600" }

    3. Add three separate Actions of the type `Add Task` and provide simple investigation tasks which you would want an analyst to complete when working on this type of incident.

        For the purposes of demonstration, you can use the following:

           - `Investigate account used for data access`
           - `Investigate host used for data access`
           - `Decide on escalation path`  

        ![](../img/placeholder.png ""){: class="w600" }

    4. Thats all! Press the `Apply` button to finish the wizard and return to the Automation blade. 

## Conclusion

We now have the Scheduled Query rule and automation to add investigation tasks to incidents created by the rule in place. The next step is to rerun our attack and verify everything is working.