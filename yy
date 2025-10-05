import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import fetch from "node-fetch"; // npm i node-fetch@2

const app = express();
app.use(cors());
app.use(bodyParser.json());

const PORT = 5000; // backend port

// ----------------- ⚡ CONFIGURE HERE -----------------
const SEARCH_ENDPOINT = "https://<your-search-resource>.search.windows.net";
const SEARCH_INDEX = "<your-index-name>"; // e.g., products-index
const SEARCH_KEY = "<your-search-admin-key>";

const GPT_ENDPOINT = "https://<your-aoai-resource>.openai.azure.com/openai/deployments/<deployment-name>/chat/completions?api-version=2023-07-01-preview";
const GPT_KEY = "<your-aoai-key>";
// ----------------------------------------------------

// Root route
app.get("/", (req, res) => {
  res.send("Backend is running. Use /health or /api/query");
});

// Health check route
app.get("/health", (req, res) => {
  res.json({ status: "ok", message: "Backend is running fine 🚀" });
});

// API route for frontend
app.post("/api/query", async (req, res) => {
  try {
    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ error: "Prompt is required" });

    // 1️⃣ Query Azure Cognitive Search
    const searchResp = await fetch(`${SEARCH_ENDPOINT}/indexes/${SEARCH_INDEX}/docs/search?api-version=2023-07-01`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": SEARCH_KEY
      },
      body: JSON.stringify({ search: prompt })
    });

    const searchData = await searchResp.json();
    const searchResults = searchData.value
      ? searchData.value.map(d => d.productName || JSON.stringify(d)).join("\n")
      : "";

    // 2️⃣ Send search results + prompt to Azure GPT
    const gptResp = await fetch(GPT_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": GPT_KEY
      },
      body: JSON.stringify({
        messages: [
          { role: "system", content: "You are a helpful assistant for product search." },
          { role: "user", content: `Context:\n${searchResults}\n\nQuestion: ${prompt}` }
        ]
      })
    });

    const gptData = await gptResp.json();
    const answer = gptData.choices?.[0]?.message?.content || "No response from GPT";

    // 3️⃣ Send response to frontend
    res.json({ response: answer });

  } catch (error) {
    console.error("Error in /api/query:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

app.listen(PORT, () => {
  console.log(`✅ Backend running on http://localhost:${PORT}`);
});

import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './home.html',
  styleUrls: ['./home.css']
})
export class Home {
  prompt: string = '';
  isSubmitting = false;

  // Array to store submitted prompts and GPT responses
  submittedPrompts: string[] = [];

  // Submit prompt to backend
  submitPrompt(): void {
    const text = this.prompt.trim();
    if (!text || this.isSubmitting) return;

    this.isSubmitting = true;

    fetch("http://localhost:5000/api/query", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: text })
    })
      .then(res => res.json())
      .then(data => {
        // Store question and GPT response
        this.submittedPrompts.push(`Q: ${text}\nA: ${data.response}`);
        this.prompt = '';
        this.isSubmitting = false;
      })
      .catch(err => {
        console.error("Error fetching response:", err);
        this.submittedPrompts.push(`Q: ${text}\nA: Error fetching response`);
        this.isSubmitting = false;
      });
  }

  // Clear the prompt textarea
  clearPrompt(): void {
    if (this.isSubmitting) return;
    this.prompt = '';
  }

  // Disable submit button if no text or submitting
  get isSubmitDisabled(): boolean {
    return !((this.prompt ?? '').trim()) || this.isSubmitting;
  }
}

import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './home.html',
  styleUrls: ['./home.css']
})
export class Home {
  prompt: string = '';
  isSubmitting = false;

  // Array to store submitted prompts and GPT responses
  submittedPrompts: string[] = [];

  // Submit prompt to backend
  submitPrompt(): void {
    const text = this.prompt.trim();
    if (!text || this.isSubmitting) return;

    this.isSubmitting = true;

    fetch("http://localhost:5000/api/query", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: text })
    })
      .then(res => res.json())
      .then(data => {
        console.log("Backend response:", data); // Debugging

        // Safely get GPT response
        const gptResponse = data.response ?? data.error ?? "No response from GPT";

        // Store question + GPT response
        this.submittedPrompts.push(`Q: ${text}\nA: ${gptResponse}`);
        this.prompt = '';
        this.isSubmitting = false;
      })
      .catch(err => {
        console.error("Error fetching response:", err);
        this.submittedPrompts.push(`Q: ${text}\nA: Error fetching response`);
        this.isSubmitting = false;
      });
  }

  // Clear the prompt textarea
  clearPrompt(): void {
    if (this.isSubmitting) return;
    this.prompt = '';
  }

  // Disable submit button if no text or submitting
  get isSubmitDisabled(): boolean {
    return !((this.prompt ?? '').trim()) || this.isSubmitting;
  }
}

