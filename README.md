# WAFV2-Modification
A Bash script to make changes in WAFV2 using aws cli commands

Steps :   1) Save File
2) Make changes as per the use case 
3) chmod +x filename.sh 
4) bash filename.sh

Explanation:  STEPS=>

	          1) Fetch the current WAF rule set in json format to a file.

              2) Fetch the Last LockToken of WAF rule-set **#For every change commited to waf rule-set a new lock token is generated which is to be used to make changes in every next change commit to keep backend track of changes as verison**
							
              3) Decode all the base64 encoded SearchString values for custom rule strings  **#Very Crucial as by default the WAF using cli is fetched base64 encoded (ONLY FOR CUSTOM STRINGS) and again when uploaded it once again encodes it . This might change the expected rule string and can cause P1/P2**
							
              4) Use Jq in bash to manipulate the json file and make expected changes to waf rule-set **#You might have to create multiple files during this process make sure to terminate them at the end post debugging if required**
							
              5) Encode all the custom strings back again before uploading the json to reflect the changes **#AWS CLI does not allow you to upload the decoded string file**
							
              6) Upload the json back to AWS using cli command passing the locktoken from step 2.
							
              7) Make sure to add conditions and status code checks as per need.
							
