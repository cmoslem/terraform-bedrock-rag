import boto3
from botocore.exceptions import ClientError
import json
import os

# Initialize AWS Bedrock client
bedrock = boto3.client(
    service_name='bedrock-runtime',
    region_name=os.getenv("AWS_REGION", "us-west-2")  # Replace with your AWS region
)

# Initialize Bedrock Knowledge Base client
bedrock_kb = boto3.client(
    service_name='bedrock-agent-runtime',
    region_name=os.getenv("AWS_REGION", "us-west-2")  # Replace with your AWS region
)

def valid_prompt(prompt, model_id):
    try:

        messages = [
            {
                "role": "user",
                "content": [
                    {
                    "type": "text",
                    "text": f"""Human: Clasify the provided user request into one of the following categories. Evaluate the user request agains each category. Once the user category has been selected with high confidence return the answer.
                                Category A: biodiversité Vexin.
                                Category B: histoire de Sannois.
                                Category C: Autonomie Model Y .
                                Category D: The request is not related to Categories A, B, or C.
                               
                                <user_request>
                                {prompt}
                                </user_request>
                                ONLY ANSWER with the Category letter, such as the following output example:
                                
                                Category B
                                
                                Assistant:"""
                    }
                ]
            }
        ]

        response = bedrock.invoke_model(
            modelId=model_id,
            contentType='application/json',
            accept='application/json',
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31", 
                "messages": messages,
                "max_tokens": 10,
                "temperature": 0,
                "top_p": 0.1,
            })
        )
        print(f"Raw LLM response: {response}")
        response_body = response['body'].read()
        print(f"LLM response body: {response_body}")
        response_json = json.loads(response_body)
        print(f"LLM response JSON: {response_json}")
        category = response_json['content'][0]["text"]
        print(f"Extracted category: {category}")
        
        if category.lower().strip() in ["category a", "category b", "category c"]:
            return True
        else:
            return False
    except ClientError as e:
        print(f"Error validating prompt (ClientError): {e}")
        return False
    except Exception as e:
        print(f"Error validating prompt (General Error): {e}")
        return False

def query_knowledge_base(query, kb_id):
    try:
        response = bedrock_kb.retrieve(
            knowledgeBaseId=kb_id,
            retrievalQuery={
                'text': query
            },
            retrievalConfiguration={
                'vectorSearchConfiguration': {
                    'numberOfResults': 3
                }
            }
        )
        return response['retrievalResults']
    except ClientError as e:
        print(f"Error querying Knowledge Base: {e}")
        return []

def generate_response(prompt, model_id, temperature, top_p):
    try:

        messages = [
            {
                "role": "user",
                "content": [
                    {
                    "type": "text",
                    "text": prompt
                    }
                ]
            }
        ]

        response = bedrock.invoke_model(
            modelId=model_id,
            contentType='application/json',
            accept='application/json',
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31", 
                "messages": messages,
                "max_tokens": 500,
                "temperature": temperature,
                "top_p": top_p,
            })
        )
        return json.loads(response['body'].read())['content'][0]["text"]
    except ClientError as e:
        print(f"Error generating response: {e}")
        return ""