import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

const app = express();
app.use(cors());
app.use(bodyParser.json());

// 🟢 Step 1: Health check route
app.get("/health", (req, res) => {
  res.json({ status: "ok", message: "Backend is running fine 🚀" });
});

// 🟢 Step 2: Test query route
app.post("/api/query", (req, res) => {
  const { prompt } = req.body;

  if (!prompt) {
    return res.status(400).json({ error: "Prompt is required" });
  }

  // For now: just echo back the prompt
  res.json({ response: `You sent: ${prompt}` });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`✅ Backend running on http://localhost:${PORT}`);
});
