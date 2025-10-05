curl -X GET "https://<your-resource-name>.search.windows.net/indexes/products-index/docs?api-version=2023-07-01&search=*" \
-H "api-key: <your-admin-key>"

curl -X POST "https://<your-resource-name>.openai.azure.com/openai/deployments/<deployment-name>/chat/completions?api-version=2023-07-01-preview" \
-H "Content-Type: application/json" \
-H "api-key: <your-aoai-key>" \
-d '{"messages":[{"role":"user","content":"Hello"}]}'
