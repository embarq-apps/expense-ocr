# frozen_string_literal: true

require 'json'
require 'faraday'
require 'aws-sdk-secretsmanager'

# ExpenseOcr analyzes documents using Mistral AI and returns the extracted information as JSON
class ExpenseOcr
  def initialize(url, doc_type)
    @url = url
    @doc_type = doc_type
    @is_img = @doc_type == 'image'
  end

  def analyze_document_content
    raise "Error communicating with Mistral AI: #{response.body}" unless response.success?

    JSON.parse(response.body)['choices'][0]['message']['content']
  end

  private

  def prompt
    <<-PROMPT
    You are an AI specialized in document analysis and data extraction. \
    Your task is to analyze an input document (PDF or image) and extract key financial information from it. \
    Extraction Requirements: \
    1. Amount (€ or $): The total monetary value in the document. \
    2. Date: The date of the transaction (format: YYYY-MM-DD). \
    3. Expense Type: \
    "- periodic if the document suggests a recurring payment (e.g., subscriptions, utility bills)." \
    "- one-time if the document suggests a single transaction (e.g., restaurant bill, one-time purchase)." \
    4. Category: Choose one of the following based on the document content: \
    - meal (e.g., restaurant, catering, food delivery) \
    - telco (e.g., phone, internet, communication services) \
    - transport_lodging (e.g., taxi, flight, hotel, car rental) \
    - supplies (e.g., office supplies, equipment purchases) \
    - client_gift (e.g., gifts, promotional items, entertainment expenses, restaurant for more than one person) \
    - misc (if no other category fits). \
    Output Format (JSON): Ensure your response follows this structure: \
    { "amount": 123.45, "currency": "EUR", "date": "2025-03-14", "expense_type": "one-time", "category": "meal" }. \
    Important Notes: \
    - If multiple amounts are detected, pick the total or most relevant one. \
    - If no clear date is found, infer the most probable one (e.g., invoice date, payment date). \
    - If categorization is uncertain, provide the closest match. \
    - If the amount is not in Euro, please convert it to Euro
    PROMPT
  end

  def connection
    Faraday.new(url: 'https://api.mistral.ai/v1') do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['Authorization'] = "Bearer #{ENV['MISTRAL_API_KEY'] || api_key}"
    end
  end

  def response
    connection.post('/chat/completions') do |req|
      req.body = body
    end
  end

  def body
    {
      model: model,
      messages: [{ role: 'user', content: content }],
      response_format: { type: 'json_object' }
    }.to_json
  end

  def content
    [
      { type: 'text', text: prompt },
      *(@is_img ? [{ type: 'image_url', image_url: @url }] : [{ type: 'document_url', document_url: @url }])
    ]
  end

  def model
    @is_img ? 'pixtral-12b-2409' : 'mistral-small-latest'
  end

  def api_key
    client = Aws::SecretsManager::Client.new(region: 'eu-west-3')
    client.get_secret_value(secret_id: 'MistralApiKey').secret_string
  end
end
