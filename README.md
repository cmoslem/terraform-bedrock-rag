# AWS Bedrock RAG Chatbot with Aurora Serverless and Terraform

## Project Overview

This project implements a Retrieval-Augmented Generation (RAG) chatbot using AWS Bedrock, an Aurora Serverless PostgreSQL database (for vector storage), and Amazon S3 for document storage. The entire infrastructure is deployed using Terraform, and the chatbot interface is built with Streamlit.

The primary goal is to provide accurate, context-aware responses to user queries based on a private corpus of documents (e.g., product specification sheets). This approach allows Large Language Models (LLMs) to leverage up-to-date or proprietary information without requiring costly fine-tuning.

## Architecture

The system follows a standard RAG pattern, enhanced with an LLM-based prompt validation mechanism:

1.  **User Interaction:** Users interact with a Streamlit web application.
2.  **Prompt Validation (LLM Guardrail):** Before processing, the user's prompt is sent to an AWS Bedrock LLM (e.g., Anthropic Claude) for classification. This acts as a guardrail, ensuring only relevant queries proceed, thereby optimizing costs and maintaining context.
3.  **Knowledge Retrieval:** If the prompt is valid, the system queries a Bedrock Knowledge Base. This Knowledge Base performs a semantic search against an Aurora Serverless PostgreSQL vector store (powered by `pg_vector`), retrieving the most relevant document chunks.
4.  **Context Augmentation:** The retrieved document chunks are then used to augment the original user prompt, creating a richer, context-aware query.
5.  **Response Generation:** This augmented prompt is sent to a Bedrock LLM (e.g., Anthropic Claude), which generates a precise and factual response based on the provided context.
6.  **Display:** The LLM's response is displayed to the user in the Streamlit application.

```mermaid
graph TD
    A[User Query] --> B(Streamlit App)
    B --> C{Validate Prompt (LLM Guardrail)}
    C -- Valid --> D[Bedrock Knowledge Base (Aurora Vector Store)]
    C -- Invalid --> E[Generic Refusal Message]
    D -- Retrieved Context --> F[Augment Prompt]
    F --> G[Bedrock LLM (Anthropic Claude)]
    G -- Generated Response --> B
    E --> B
```

## Features

*   **Retrieval-Augmented Generation (RAG):** Leverages private data for context-aware LLM responses.
*   **LLM-based Prompt Validation:** Intelligent filtering of irrelevant or inappropriate user queries.
*   **Infrastructure as Code (IaC):** Automated and reproducible deployment of all AWS resources using Terraform.
*   **Scalable Vector Store:** Amazon Aurora Serverless PostgreSQL with `pg_vector` for efficient semantic search.
*   **User-Friendly Interface:** Interactive chatbot built with Streamlit.
*   **Modular Design:** Clear separation of concerns between UI, business logic, and infrastructure.

## Technologies Used

*   **AWS Bedrock:** LLM invocation (Anthropic Claude) and Knowledge Base.
*   **Amazon Aurora Serverless v2 (PostgreSQL):** Vector database for semantic search.
*   **Amazon S3:** Storage for source documents (PDFs, etc.).
*   **Terraform:** Infrastructure as Code for deploying AWS resources.
*   **Python:** Backend logic and Streamlit application.
*   **Streamlit:** Web application framework for the chatbot UI.
*   **Boto3:** AWS SDK for Python.
*   **python-dotenv:** For managing local environment variables.

## Project Structure

```
.
├── .gitignore
├── app.py                      # Streamlit web application for the chatbot UI
├── bedrock_utils.py            # Python utilities for AWS Bedrock interactions (RAG logic, prompt validation)
├── requirements.txt            # Python dependencies
├── .env.example                # Example environment variables file
├── modules/
│   ├── database/               # Terraform module for Aurora Serverless DB
│   └── bedrock_kb/             # Terraform module for Bedrock Knowledge Base
├── scripts/
│   ├── aurora_sql.sql          # SQL script to prepare Aurora DB (e.g., enable pg_vector)
│   └── upload_s3.py            # Python script to upload documents to S3
│   └── spec-sheets/            # Directory for source documents (PDFs)
├── stack1/                     # Terraform stack for core AWS infrastructure (VPC, Aurora, S3)
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
└── stack2/                     # Terraform stack for Bedrock Knowledge Base
    ├── main.tf
    ├── outputs.tf
    └── variables.tf
```

## Prerequisites

Before you begin, ensure you have the following:

*   AWS CLI installed and configured with appropriate credentials.
*   Terraform installed (version 1.0+ recommended).
*   Python 3.9+ installed.
*   `pip` (Python package manager).

## Deployment Steps

Follow these steps to deploy the infrastructure and run the chatbot:

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd <your-repo-directory>
```

### 2. Configure Environment Variables

Create a `.env` file from the `.env.example` and fill in your AWS region and Bedrock Knowledge Base ID.

```bash
cp .env.example .env
# Open .env and edit:
# AWS_REGION="your_aws_region" # e.g., us-east-1, us-west-2
# BEDROCK_KB_ID="your_bedrock_knowledge_base_id"
```

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 4. Deploy Infrastructure - Stack 1 (VPC, Aurora, S3)

Navigate to the `stack1` directory and deploy the core infrastructure.

```bash
cd stack1
terraform init
terraform apply --auto-approve
cd ..
```

*Note down the outputs, especially the Aurora cluster endpoint and the S3 bucket name.*

### 5. Prepare Aurora PostgreSQL Database

Connect to your Aurora PostgreSQL cluster (e.g., via AWS RDS Query Editor or `psql`) and run the SQL script to enable necessary extensions like `pg_vector`.

```sql
-- Example from scripts/aurora_sql.sql (you will run this in your DB client)
CREATE EXTENSION IF NOT EXISTS vector;
-- Other setup as needed by Bedrock KB for vector storage
```

### 6. Deploy Infrastructure - Stack 2 (Bedrock Knowledge Base)

Navigate to the `stack2` directory and deploy the Bedrock Knowledge Base. Ensure you provide the Knowledge Base ID as output by the stack.

```bash
cd stack2
terraform init
terraform apply --auto-approve
cd ..
```

*Update your `.env` file with the actual `BEDROCK_KB_ID` once created.*

### 7. Upload Documents to S3

Place your source documents (e.g., PDF spec sheets) in the `scripts/spec-sheets/` directory. Then, use the provided Python script to upload them to your S3 bucket.

*   **Modify `scripts/upload_s3.py`:** Update the `bucket_name` variable with the S3 bucket name output from `stack1` deployment.
*   **Run the upload script:**

```bash
python scripts/upload_s3.py
```

### 8. Sync Bedrock Knowledge Base Data Source

After uploading documents to S3, you must synchronize the data source in the Bedrock Knowledge Base. You can do this via the AWS Console or programmatically using the Bedrock Agents API.

### 9. Run the Chatbot Application

Once the knowledge base is synchronized, you can start the Streamlit application.

```bash
streamlit run app.py
```

Open your web browser to the address provided by Streamlit (usually `http://localhost:8501`).

## Contributing

Feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

moslem chalfouh

## Medium Article

[Link to your future Medium article here!]
