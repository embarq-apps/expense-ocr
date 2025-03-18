# frozen_string_literal: true

require 'json'
require 'faraday'
require 'aws-sdk-ssm'

# ExpenseOcr analyzes documents using Mistral AI and returns the extracted information as JSON
class ExpenseOcr
  MISTRAL_API_KEY = ENV['MISTRAL_API_KEY']

  def initialize(url, doc_type)
    @url = url
    @doc_type = doc_type
    @is_img = @doc_type == 'image'
  end

  def extract_data
    raise "Error communicating with Mistral AI: #{chat_completions.body}" unless chat_completions.success?

    JSON.parse(chat_completions.body)['choices'][0]['message']['content']
  end

  private

  def prompt
    <<~PROMPT
      You are an AI specialized in document analysis and financial data extraction.
      Your task is to analyze an input document (PDF or image) and extract key financial information while ensuring compliance with deductible expense regulations based on official guidelines.

      ### Extraction Requirements:

      1. **Amount (€)**: The total monetary value in the document, including taxes (TTC).
      2. **Date**: The date of the transaction (format: YYYY-MM-DD).
      3. **Expense Type**:
         - "periodic" if the document suggests a monthly recurring payment (e.g., subscriptions, utility bills). Yearly reccuring payment should be considered "one-time".
         - "one-time" if the document suggests a single transaction (e.g., restaurant bill, one-time purchase).
      4. **Category & Deductibility Rules:**

         - **"meal"**: Expenses related to food (e.g., restaurant, catering, food delivery).
           - **Deduction rule:** Meal expenses are deductible only if incurred during a professional activity and not covered by per diem allowances.
           - **Non-deductible cases:** If considered a personal meal without justification of a professional necessity.
           - **Single cover (1 person)** → Categorize as `"meal"`, if deductible under business expenses.
           - **Multiple covers (2+ people)** → Categorize as `"client_gift"`, since meals involving clients, partners, or employees are considered business-related hospitality expenses.

         - **"telco"**: Phone, internet, and communication services.
           - **Deduction rule:** Deductible only for professional use. If a document indicates a mixed personal-professional use, consider a pro rata deduction.

         - **"transport_lodging"**: Travel-related expenses (e.g., taxi, flight, hotel, car rental, and public transport subscriptions).
           - **Special Case:** If the document mentions a **monthly transport pass (e.g., metro, bus, train subscription)**, classify it as `"transport_lodging"` instead of `"telco"`, even though it's recurring.
           - **Deduction rule:** Deductible if related to professional travel.
           - **Lodging limitation:** Long-term lodging might fall under permanent establishment rules, affecting deductibility.

         - **"supplies"**: Office supplies, equipment purchases, work tools.
           - **Deduction rule:** Small office supplies are deductible immediately.
           - **Depreciable assets:** Large purchases (e.g., computer, furniture) might require amortization over several years. If the document indicates an expensive item, flag it for potential depreciation.

         - **"client_gift"**: Gifts, promotional items, entertainment expenses, or restaurant bills involving multiple people.
           - **Deduction rule:** Gifts are deductible if their total annual amount remains below tax authority thresholds (e.g., €73 per beneficiary in France).
           - **Non-deductible cases:** Excessive gifts may be requalified as non-justified business expenses.

         - **"misc"**: If no other category fits.

      ### Output Format (JSON):
      Ensure your response follows this structure:
      {
        "amount": 123.45,
        "currency": "EUR",
        "date": "2025-03-14",
        "expense_type": "one-time",
        "category": "meal",
        "confidence": 80.0,
        "comment": "This expense was categorized as 'meal' because it corresponds to a restaurant bill for a single person, which is generally deductible if related to business."
      }

      ### Additional Processing Rules:
      - **Multiple amounts:** Choose the total or the most relevant one.
      - **Missing date:** Infer the most probable one (invoice date, payment date, transaction timestamp).
      - **Foreign currency:** Convert to Euro using the latest exchange rate.
      - **Comment Field:** Provide a detailed explanation of why the category was selected, referencing document content and deductibility rules.
      - **Confidence Score:** Assign a confidence percentage (0-100%) indicating how certain the AI is about the categorization. If score is lower than 90%, categorize as misc.
    PROMPT
  end

  def connection
    Faraday.new(url: 'https://api.mistral.ai') do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['Authorization'] = "Bearer #{MISTRAL_API_KEY || api_key}"
    end
  end

  def chat_completions
    connection.post('/v1/chat/completions') do |req|
      req.body = body
    end
  end

  def body
    {
      model: model,
      messages: [{ role: 'user', content: content }],
      response_format: { type: 'json_object' },
      temperature: 0.5
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
    client = Aws::SSM::Client.new(region: 'eu-west-3')
    client.get_parameter(name: 'MISTRAL_API_KEY', with_decryption: true).parameter.value
  end
end
