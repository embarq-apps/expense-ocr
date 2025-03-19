# frozen_string_literal: true

require 'json'
require 'faraday'
require 'aws-sdk-ssm'

# ExpenseOcr analyzes documents using Mistral AI and returns the extracted information as JSON
class ExpenseOcr
  MISTRAL_API_KEY = ENV['MISTRAL_API_KEY']

  def initialize(url, content_type)
    @url = url
    @content_type = content_type
    @is_img = @content_type.include?('image/')
  end

  def extract_data
    raise "Error communicating with Mistral AI: #{chat_completions.body}" unless chat_completions.success?

    JSON.parse(chat_completions.body)['choices'][0]['message']['content']
  end

  private

  def prompt
    <<~PROMPT
      You are an AI specialized in document analysis and financial data extraction.
      Analyze an input document (PDF or image) and extract key financial details while ensuring compliance with deductible expense regulations.

      ### Extraction Requirements:

      1. **Amount (€)**: The total monetary value, including taxes (TTC).
      2. **Date**: The transaction date (format: YYYY-MM-DD).
      3. **Frequency**:
         - `"periodic"` → Monthly recurring payment (e.g., subscriptions, utility bills). **Yearly recurring payments should be `"one-time"`**.
         - `"one_time"` → Single transaction (e.g., restaurant bill, one-time purchase).
      4. **Category & Deductibility Rules**:

         - **"meal"**: Food-related expenses (e.g., restaurant, catering, food delivery).
           - **Deductible if incurred during a professional activity and not covered by per diem allowances**.
           - **1 person** → Categorize as `"meal"` (if deductible).
           - **2+ people** → Categorize as `"client_gift"` (business hospitality).

         - **"telco"**: Phone, internet, communication services.
           - Deductible only for professional use. **For mixed personal-professional use, apply a pro rata deduction**.

         - **"transport_lodging"**: Travel-related expenses (e.g., taxi, flight, hotel, car rental, public transport subscriptions).
           - **Monthly public transport passes (e.g., metro, bus, train subscription) belong here**.
           - **Lodging limitation:** Long-term lodging may fall under permanent establishment rules.

         - **"supplies"**: Office supplies, equipment purchases, work tools.
           - **Small supplies** → Deductible immediately.
           - **Large purchases (e.g., computers, furniture)** → May require amortization.

         - **"client_gift"**: Gifts, promotional items, entertainment, or restaurant bills for multiple people.
           - **Deductible if the total annual amount remains below tax thresholds (e.g., €73 per beneficiary in France)**.

         - **"misc"**: If no other category applies.

      ### Output Format (JSON):
      Ensure this structured response:
      ```json
      {
        "status": "success",
        "amount": 123.45,
        "date": "2025-03-14",
        "frequency": "one_time",
        "category": "meal",
      }
      ```

      ### Additional Processing Rules:
      - **Multiple amounts:** Choose the total with taxes.
      - **Missing date:** Infer the most probable one (e.g., invoice date, payment date).
      - **Error Handling:**
        - If the document is **not a valid expense proof**, return:
          ```json
          { "status": "error", "comment": "Reason for failure" }
          ```
      - **Multiple proofs:**
        - If the document contains multiple proofs, **sum the total of each proof**.
        - **Set `"periodic"` if dates vary**
        - Determine the **best overall category**.
      - **Mandatory JSON Structure:** Ensure that every response is in the required JSON format.
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
    @chat_completions ||= connection.post('/v1/chat/completions') do |req|
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
    'pixtral-large-latest'
  end

  def api_key
    client = Aws::SSM::Client.new(region: 'eu-west-3')
    client.get_parameter(name: 'MISTRAL_API_KEY', with_decryption: true).parameter.value
  end
end
