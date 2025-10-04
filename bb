from flask import Flask, request, jsonify
from flask_cors import CORS
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
import openai

app = Flask(__name__)
CORS(app)

# -------------------------
# Azure OpenAI Configuration (Optional, if using GPT for context-aware answers)
# -------------------------
openai.api_type = "azure"
openai.api_base = "https://<your-azure-openai-endpoint>.openai.azure.com/"
openai.api_version = "2024-12-01-preview"
openai.api_key = "<your-azure-openai-key>"
deployment_name = "gpt-35-turbo-demo"  # Chat model deployment name

# -------------------------
# Azure AI Search Configuration
# -------------------------
search_endpoint = "https://<your-search-service>.search.windows.net"
search_index_name = "<your-index-name>"
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
        results = search_client.search(question, top=1)  # get top 1 result
        top_result = next(results, None)

        if not top_result:
            return jsonify({"answer": "No relevant document found."})

        # Step 2: Combine important columns for GPT
        document_text = f"""
        Product Name: {top_result.get('productName', '')}
        Brand Name: {top_result.get('brandName', '')}
        Description: {top_result.get('brandDesc', '')}
        Product Size: {top_result.get('productSize', '')}
        Price: {top_result.get('sellPrice', '')} {top_result.get('currancy', '')}
        Discount: {top_result.get('discount', '')}
        Category: {top_result.get('category', '')}
        """

        # Step 3: Ask GPT with the top document as context
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


import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './home.html',
  styleUrls: ['./home.css']
})
export class Home {
  prompt: string = '';
  isSubmitting = false;

  // Store submitted prompts
  submittedPrompts: string[] = [];
  
  // Store backend/GPT response
  backendResponse: string = '';

  constructor(private http: HttpClient) {}

  submitPrompt(): void {
    const text = this.prompt.trim();
    if (!text || this.isSubmitting) return;

    this.isSubmitting = true;
    this.backendResponse = '';

    // Call backend API
    this.http.post<{ answer: string }>('http://127.0.0.1:5000/ask', { question: text })
      .subscribe({
        next: (res) => {
          console.log('Backend response:', res);
          this.submittedPrompts.push(text);
          this.backendResponse = res.answer;  // Store GPT response
          this.prompt = '';
          this.isSubmitting = false;
        },
        error: (err) => {
          console.error('Error:', err);
          this.backendResponse = 'Could not connect to backend';
          this.isSubmitting = false;
        }
      });
  }

  clearPrompt(): void {
    if (this.isSubmitting) return;
    this.prompt = '';
  }

  get isSubmitDisabled(): boolean {
    return !((this.prompt ?? '').trim()) || this.isSubmitting;
  }
}

<div class="home-center dark-theme" style="--header-h: 0px;">
  <section class="prompt-card" role="region" aria-labelledby="promptTitle">
    <h2 class="title" id="promptTitle">Ask anything</h2>

    <label class="sr-only" for="promptInput">Your prompt</label>
    <textarea
      id="promptInput"
      class="prompt-input"
      [(ngModel)]="prompt"
      placeholder="Type your prompt here…"
      (keydown.control.enter)="submitPrompt()"
      (keydown.meta.enter)="submitPrompt()"
    ></textarea>

    <div class="actions">
      <button class="clear-btn" type="button" (click)="clearPrompt()" 
        [disabled]="!prompt.length || isSubmitting">
        Clear
      </button>

      <button class="primary-btn" type="button" (click)="submitPrompt()" 
        [disabled]="isSubmitDisabled">
        {{ isSubmitting ? 'Submitting…' : 'Submit' }}
      </button>
    </div>

    <!-- Submitted prompts displayed -->
    <div class="submitted-prompts" *ngIf="submittedPrompts.length">
      <h3 class="submitted-title">Submitted Prompts:</h3>
      <div class="prompt-card-small" *ngFor="let p of submittedPrompts">
        {{ p }}
      </div>
    </div>

    <!-- GPT/Backend response -->
    <div *ngIf="backendResponse" class="response-box">
      <h3>Backend Response:</h3>
      <p>{{ backendResponse }}</p>
    </div>
  </section>
</div>

.response-box {
  margin-top: 20px;
  padding: 10px;
  border: 1px solid #888;
  border-radius: 5px;
  background-color: #f5f5f5;
}
