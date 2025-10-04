from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import requests
from openai import OpenAI

app = Flask(__name__)
CORS(app)

# -------------------------
# Azure OpenAI Configuration
# -------------------------
openai_api_key = "YOUR_OPENAI_KEY"
openai_endpoint = "https://YOUR_OPENAI_RESOURCE.openai.azure.com/"
openai_deployment = "gpt-35-turbo-demo"  # your ChatGPT deployment name

client = OpenAI(api_key=openai_api_key, base_url=openai_endpoint)

# -------------------------
# Azure AI Search Configuration
# -------------------------
search_api_key = "YOUR_SEARCH_KEY"
search_endpoint = "https://YOUR_SEARCH_SERVICE.search.windows.net"
search_index = "YOUR_INDEX_NAME"  # index created in AI Search

# -------------------------
# API route
# -------------------------
@app.route("/ask", methods=["POST"])
def ask():
    data = request.json
    question = data.get("question", "")
    if not question:
        return jsonify({"answer": "No question provided."})

    try:
        # Step 1: Use GPT to convert user question to structured query
        response = client.chat.completions.create(
            model=openai_deployment,
            messages=[{"role": "user", "content": question}]
        )
        structured_query = response.choices[0].message.content

        # Step 2: Send structured query to Azure AI Search
        search_url = f"{search_endpoint}/indexes/{search_index}/docs/search?api-version=2023-07-01-Preview"
        headers = {
            "api-key": search_api_key,
            "Content-Type": "application/json"
        }
        payload = {
            "search": structured_query,
            "queryType": "semantic"
        }
        search_response = requests.post(search_url, headers=headers, json=payload)
        search_results = search_response.json()

        return jsonify({"answer": search_results})

    except Exception as e:
        return jsonify({"answer": f"Error: {str(e)}"})


# -------------------------
# Run server
# -------------------------
if __name__ == "__main__":
    app.run(debug=True)
