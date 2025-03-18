# Expense OCR

This project offers a simple OCR solution for expense documents through AI (Mistral).

## Usage

First you need to add the aws sdk lambda to your Gemfile:

```ruby
gem 'aws-sdk-lambda'
```

Then run :

```sh
bundle install
```

To invoke the function:

```ruby
# Get your AWS credentials
aws_env = Rails.application.credentials.dig(Rails.env.to_sym, :aws)
credentials = Aws::Credentials.new(aws_env[:access_key_id], aws_env[:secret_access_key])

# Create Lambda client
lambda_client = Aws::Lambda::Client.new(aws_env[:access_key_id], aws_env[:secret_access_key])

# Define the payload
payload = { url: "DOCUMENT_URL", doc_type: "DOCUMENT_TYPE"}.to_json

# Invoke the function
response = lambda_client.invoke({
  function_name: "expenseOCR",
  payload: payload,
  invocation_type: 'RequestResponse',
})

# Get results
result = JSON.parse(response.payload.string)
```

In the payload, you need to pass the following parameters:

- `url` : URL of the document to be processed
- `doc_type` : type of the document (`image` or `pdf`)

## Response

The response will be a JSON object with the following structure:

```json
{
  "amount": 123.45,
  "currency": "EUR",
  "date": "2025-03-14",
  "expense_type": "one-time",
  "category": "meal",
  "comment": "This expense was categorized as 'meal' because it corresponds to a restaurant bill for a single person, which is generally deductible if related to business."
}
```

- `expense_type` can be `periodic` or `one-time`.
- `category` is the category of the expense defined by the AI (see categorization section).

## Categorization

The possible categories are based on the Embarq App :

- meal (e.g., restaurant, catering, food delivery)
- telco (e.g., phone, internet, communication services)
- transport_lodging (e.g., taxi, flight, hotel, car rental)
- supplies (e.g., office supplies, equipment purchases)
- client_gift (e.g., gifts, promotional items, entertainment expenses, restaurant for more than one person)
- misc (if no other category fits).

## Authorization

To allow your app to access this function, you must add this IAM policy to the aws user that will be running the function:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:eu-west-3:057449144315:function:expenseOCR"
    }
  ]
}
```

Also, you need to ask an Embarq AWS admin to update the Lambda function's permissions :

1. Go to AWS Lambda Console [Lambda Dashboard](https://console.aws.amazon.com/lambda).
2. Select ExpenseOCR function.
3. Go to Configurations -> Permissions.
4. Under Resource-based policy, click Add permissions → AWS Account.
5. Enter the AWS Account ID of the external account.
6. Choose lambda:InvokeFunction as the action.
7. Click Save.
