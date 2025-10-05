// server.js
const express = require("express");
const axios = require("axios");
const bodyParser = require("body-parser");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Replace with your Azure details
const SEARCH_URL = "https://<your-search-resource>.search.windows.net/indexes/products-index/docs";
const SEARCH_KEY = "<your-search-admin-key>";
const GPT_URL = "https://<your-openai-resource>.openai.azure.com/openai/deployments/gpt-products-deployment/chat/completions?api-version=2023-07-01-preview";
const GPT_KEY = "<your-openai-api-key>";

// Endpoint to handle frontend queries
app.post("/api/query", async (req, res) => {
  try {
    const prompt = req.body.prompt;

    // Step 1: Query Cognitive Search
    const searchResponse = await axios.get(SEARCH_URL, {
      params: { "api-version": "2023-07-01", search: prompt, $top: 5 },
      headers: { "api-key": SEARCH_KEY }
    });

    const searchResults = searchResponse.data.value;
    if (searchResults.length === 0) return res.json({ answer: "No products found" });

    // Step 2: Prepare context for GPT
    const context = searchResults.map(r => `Product: ${r.productName}, Description: ${r.description}, Category: ${r.category}, Price: ${r.price}`).join("\n");
    const combinedPrompt = `${prompt}\n\nHere are some products:\n${context}`;

    // Step 3: Call GPT
    const gptResponse = await axios.post(
      GPT_URL,
      { messages: [{ role: "user", content: combinedPrompt }] },
      { headers: { "api-key": GPT_KEY, "Content-Type": "application/json" } }
    );

    const answer = gptResponse.data.choices[0].message.content;
    res.json({ answer });

  } catch (err) {
    console.error(err);
    res.status(500).json({ answer: "Error fetching response" });
  }
});

app.listen(3000, () => console.log("Backend running on port 3000"));
