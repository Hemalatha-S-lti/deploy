from flask import Flask, request, jsonify
from flask_cors import CORS
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
import openai

app = Flask(__name__)
CORS(app)

# -------------------------
# Azure OpenAI Configuration
# -------------------------
openai.api_type = "azure"
openai.api_base = "https://<your-azure-openai-endpoint>.openai.azure.com/"
openai.api_version = "2024-12-01-preview"
openai.api_key = "<your-azure-openai-key>"
deployment_name = "gpt-35-turbo-demo"  # GPT deployment name

# -------------------------
# Azure AI Search Configuration
# -------------------------
search_endpoint = "https://<your-search-service>.search.windows.net"
search_index_name = "<your-index-name>"      # The index you created for the Excel
search_api_key = "<your-search-api-key>"

search_client = SearchClient(
    endpoint=search_endpoint,
    index_name=search_index_name,
    credential=AzureKeyCredential(search_api_key)
)

# -------------------------
# API route for frontend
# -------------------------
@app.route("/ask", methods=["POST"])
def ask():
    data = request.json
    question = data.get("question", "").strip()

    if not question:
        return jsonify({"answer": "No question provided."})

    try:
        # Step 1: Query Azure AI Search
        results = search_client.search(question, top=1)  # top 1 result
        top_result = next(results, None)

        if not top_result:
            return jsonify({"answer": "No relevant document found."})

        # Step 2: Build document context from relevant columns
        document_text = f"Product: {top_result.get('productName', '')}, " \
                        f"Brand: {top_result.get('brandName', '')}, " \
                        f"Category: {top_result.get('category', '')}"

        # Step 3: Use GPT to answer based on top document
        response = openai.ChatCompletion.create(
            engine=deployment_name,
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": f"Answer the question based on this document:\n{document_text}\nQuestion: {question}"}
            ],
            temperature=0.7
        )

        answer = response['choices'][0]['message']['content']
        return jsonify({"answer": answer})

    except Exception as e:
        return jsonify({"answer": f"Error: {str(e)}"})

# -------------------------
# Run server
# -------------------------
if __name__ == "__main__":
    app.run(debug=True)
