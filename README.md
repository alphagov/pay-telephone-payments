# Storing records about phone payments on GOV.UK Pay

Version history:

| Date          | Version | Comment |
|:------------- | ------- | --------------------------------------------------------- |
| 27/4/2020     | 0.2     | Draft for circulation to DWP Child maintenance group     |


You can store records about phone payments in your GOV.UK Pay account using the API, if you want to report on both your:
 
- online payments processed by GOV.UK Pay
- phone payments processed by a third-party telephone payment provider

You can then track, refund and report on phone payments using the API or by signing in to the [GOV.UK Pay admin tool](https://selfservice.payments.service.gov.uk/). 

## Requirements
You can only store records about phone payments if all of the following apply:

- you already process online payments using GOV.UK Pay
- you process telephone payments using a third-party provider
- your payment service provider (PSP) is Worldpay
- you can configure your Worldpay merchant account to direct all Worldpay notifications to GOV.UK Pay

You must also set up one GOV.UK Pay account for your online payments and another GOV.UK Pay account for your phone payments. You must not [combine your services into one PSP account](https://docs.payments.service.gov.uk/account_structure/#type-3-gov-uk-pay-separate-psp-combined).

We cannot send email notifications to your users about phone payments.

If you operate a PCI-compliant call centre, you can also [take agent-keyed payments over the phone (‘MOTO’ payments)](https://docs.payments.service.gov.uk/optional_features/moto_payments) where you fill in GOV.UK Pay payment pages with your users’ details.

## Before you start

Before you can store records about phone payments, you must configure your GOV.UK Pay live account to connect with the Worldpay account used by your third-party telephone payment provider. 

Follow the guidance on [connecting your live account to Worldpay](https://docs.payments.service.gov.uk/switching_to_live/set_up_a_live_worldpay_account/#connect-your-live-account-to-worldpay). 

You may need to configure the __Capture delay (days)__ setting differently to make sure that Worldpay captures payments before you call the GOV.UK Pay API. Ask your third-party telephone payment provider if you’re not sure.

When you [set up 'Merchant channels'](https://docs.payments.service.gov.uk/switching_to_live/set_up_a_live_worldpay_account/#set-up-your-worldpay-39-merchant-channels-39) in your Worldpay settings, you must send all notifications to GOV.UK Pay. If you do not, refunds will not work.

## Storing a record about a phone payment

The call to notify us about a phone payment with the GOV.UK Pay API is:

`POST /v1/payment_notification`

You must only store a record about a phone payment on GOV.UK Pay after you've asked Worldpay to capture the money from your user's payment card.

Example request body:

```json
{
  "amount": 14500,
  "reference": "MRPC12345",
  "description": "Pay your council tax",
  "created_date": "2019-02-21T16:04:25Z",
  "authorised_date": "2019-02-21T16:05:33Z",
  "processor_id": "12345",
  "provider_id": "45678",
  "auth_code": "91011",
  "payment_outcome": {
    "status": "success"
  },
  "card_type": "master-card",
  "name_on_card": "Mr Sherlock Holmes",
  "email_address": "sherlock.holmes@example.com",
  "card_expiry": "02/19",
  "first_six_digits": "654321",
  "last_four_digits": "1234",
  "telephone_number": "+447700123456"
}
```

### Required arguments

#### amount

`amount` is the amount in pence. In the example, the payment is for £145.

The amount must be a number data type.

The minimum amount is one pence. The maximum amount is 10,000,000 pence (£100,000).

#### reference

`reference` is the reference number you wish to associate with this payment. It must be a string. 

The reference number does not need to be unique, and must not:

- be longer than 255 characters
- contain URLs

#### description

`description` is a human-readable description of the payment. This is shown to your staff in the GOV.UK Pay admin tool.

The description must be no longer than 255 characters, and must not contain URLs.

#### provider_id

`provider_id` is the `orderCode` you received from Worldpay when you requested authorisation. It must be a string.

`provider_id` is used as an idempotency key for notification API calls. If a payment already exists with the `provider_id` you provided, the API will not store a record about a new payment, or update or change the record about a payment you previously stored.
#### payment_outcome

`payment_outcome` is what you received from Worldpay after you asked them to authorise the payment.

The [`status`](https://docs.payments.service.gov.uk/api_reference/#payment-status-lifecycle), [`code`](https://docs.payments.service.gov.uk/api_reference/#errors-caused-by-payment-statuses) and `supplemental` parameter values you include will depend on what happened.

|What happened|Status|Code|
|---|---|---|
|Worldpay authorised the payment|`success`|Do not include|
|Worldpay declined authorisation|`failed`|`P0010`|
|Payment cancelled by your user (for example user hung up)|`failed`|`P0030`|
|There was an error when Worldpay tried to process the payment|`failed`|`P0050`|

If the status is `failed`, you can also include a `supplemental` object in `payment_outcome`. This object must include the `error_code` and `error_message` Worldpay sent to you.

For example:

```json
  "payment_outcome": {
    "status": "failed",
    "code": "P0010",
    "supplemental": {
      "error_code": "E1234",
      "error_message": "The payment card does not exist."
    }
  },
```
`error_code` and `error_message` must be 50 characters or fewer.

#### card_type

`card_type` must be one of the following strings:

- `master-card`
- `visa`
- `maestro`
- `diners-club`
- `american-express`
- `jcb`

#### processor_id

`processor_id` is the unique internal reference number you want to associate with this payment for your own reporting purposes. It must be a string. 
### Optional arguments

#### auth_code

`auth_code` is the `AuthorisationId` you received from Worldpay when it authorised the payment. It must be a string of 50 characters or less.

#### created_date

`created_date` is the time when you initiated the payment - for example when you received the phone call from your user. It must be:

- in [ISO 8601-1 datetime](https://www.gov.uk/government/publications/open-standards-for-government/date-times-and-time-stamps-standard) format, including the time zone
- 50 characters or less

#### authorised_date

`authorised_date` is the time when Worldpay authorised the payment. It must be:

- in [ISO 8601-1 datetime](https://www.gov.uk/government/publications/open-standards-for-government/date-times-and-time-stamps-standard) format, including the time zone
- 50 characters or less

#### name_on_card

`name_on_card` is your user's name on the front of their payment card.

#### email_address

`email_address` is your user's email address.

#### card_expiry

`card_expiry` is the expiry date of your user's payment card, in `MM/YY` format, for example `11/22`. It must be a string.

#### first_six_digits

`first_six_digits` is the first 6 digits of the 16-digit number on the front of your user's payment card. It must be a string.

#### last_four_digits
`last_four_digits` is the last 4 digits of the 16-digit number on the front of your user's payment card. It must be a string.

#### telephone_number

`telephone_number` is your user's telephone number. It must be a string of 50 characters of less.

### API response
After you make the API call, the API will respond with an HTTP status code of:

- 200 if the payment was successfully added to your GOV.UK Pay account
- a [400 or 500 status code](https://docs.payments.service.gov.uk/api_reference/#http-status-codes) if the payment was not added

If the code is a 400 or 500, you must retry the API call. You can retry a maximum of once per hour, for up to 72 hours. [Contact us](https://docs.payments.service.gov.uk/support_contact_and_more_information/#contact-us) if you're still receiving a 400 or 500 status code after 72 hours.
## Get a stored record about a payment
You can [get information about a payment](https://docs.payments.service.gov.uk/reporting) using the API or by signing in to the [GOV.UK Pay admin tool](https://selfservice.payments.service.gov.uk/).

Some of the fields will be returned in a `metadata` object in the API response.

Example API response:

```
{
    "amount": 12000,
    "description": "Apply for a passport",
    "reference": "MRPC12345",
    "payment_provider": "sandbox",
    "provider_id": "17498-8412u9-1273891239",
    "payment_id": "2neaugk4iggr8ts039pv75g24f1",
    "email": "example.example@example.org",
    "card_brand": "Mastercard",
    "created_date": "2020-04-21T13:55:36.705Z",    
    "metadata": {
        "status": "failed",
        "code": "P0010",
        "error_code": "E1234",
        "error_message": "The payment card does not exist",
        "telephone_number": "+44000000000",
        "processor_id": "183f2j8923j8",
        "created_date": "2018-02-21T16:04:25Z",
        "authorised_date": "2018-02-21T16:05:33Z",
        "auth_code": "666"
    },
    "state": {
        "status": "failed",
        "finished": true,
        "message": "Payment method rejected",
        "code": "P0010"
    },
    "card_details": {
        "last_digits_card_number": "1234",
        "first_digits_card_number": "654321",
        "cardholder_name": "Example name",
        "expiry_date": "02/19",
        "billing_address": null,
        "card_brand": "Mastercard",
        "card_type": null
    },
}
```

## Refund a stored payment
You can [refund a payment](https://docs.payments.service.gov.uk/refunding_payments).

