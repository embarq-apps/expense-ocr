# Expense OCR

This project offers a simple OCR solution for expense documents through AI (Mistral).

## Usage

To run the OCR solution, you need to provide the following parameters:

```json
{
  "url": "DOCUMENT_URL",
  "doc_type": "DOCUMENT_TYPE"
}
```

-`url` is the URL of the document to be processed.

- `doc_type` can be `image` or `pdf`.

## Response

The response will be a JSON object with the following structure:

```json
{
  "amount": 37.97,
  "currency": "EUR",
  "date": "2025-02-04",
  "expense_type": "periodic",
  "category": "telco"
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
