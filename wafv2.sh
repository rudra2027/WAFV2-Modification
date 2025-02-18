#!/bin/bash
set -x
profile="XXXXXXX"
Scope='CLOUDFRONT'
Region='us-east-1'
acl_Name='XXXXXXXXXXXXXXXXX'
acl_Id='XXXXXXXXX-XXXXXX-XXXXXXX'
aws wafv2 get-web-acl --name $acl_Name --scope $Scope --id $acl_Id --profile $profile --region $Region --query 'WebACL.Rules[]'> WAF_Rules.json
#Extract and decode all ByteMatchStatement SearchString values
input_file="WAF_Rules.json"   # Input JSON file
output_file="WAF_Rules_Decoded.json"  # Output file with decoded SearchString values

# Process JSON and decode Base64 SearchString values
jq 'def decode_b64:
      if type == "string" and test("^[A-Za-z0-9+/=]+$") and (length % 4 == 0) then
        try @base64d catch .
      else
        .
      end;

    # Recursively find and decode SearchString in ByteMatchStatement
    walk(if type == "object" and has("SearchString") then
          .SearchString |= decode_b64
         else . end)' "$input_file" > "$output_file"

echo "Decoded JSON saved to: $output_file"

LockToken=`aws wafv2 get-web-acl --name $acl_Name --scope $Scope --id $acl_Id --profile $profile --region $Region --query 'LockToken' --output text`
echo -e LockToken= $LockToken
jq 'map(if .Name == "External" then .Action |= with_entries(if .key == "Block" then .key = "Allow" else . end) else . end)' "$output_file">WAF_Rules2
if [ $? == 0 ]; then
        cat WAF_Rules2|sed -z 's/}\n{/},\n{/g' > WAF_Rules3.json
        input_file="WAF_Rules3.json"
        output2_file="WAF_Rules_Encoded.json"
        jq 'def encode_b64:
                if type == "string" then @base64 else . end;

                # Recursively find and encode SearchString in ByteMatchStatement
                walk(if type == "object" and has("SearchString") then
                .SearchString |= encode_b64
                else . end)' "$input_file" > "$output2_file"
        echo "Base64 encoded JSON saved to: $output2_file"
        aws wafv2 update-web-acl --name $acl_Name --scope $Scope --id $acl_Id --default-action '{"Allow": {}}' --profile $profile --rules file://$output2_file --visibility-config '{"SampledRequestsEnabled": true,"CloudWatchMetricsEnabled": true,"MetricName": "talentcentral-1a"}' --lock-token $LockToken --region $Region

else
       echo "ERROR with Json conversion , please check file WAF_Rules2 for possible errors"
       exit 1
fi
