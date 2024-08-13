# MX Connect Demo

This repository is a helpful reference for how to interact with the MX Connect Widget. It should help answer questions like:

- What events does the widget send to my app?
- How can I react to events that happen in the widget?
- What changes if I need to use a _webview in a mobile app_?
- How can I close the widget?

## Getting Started

Obtain your API credentials

1. Sign up at https://dashboard.mx.com and log in.
2. Obtain your _Api Key_ and your _Client ID_ from your dashboard
3. Copy `.env.sample` in the root directory to a new file named `.env` and fill in the values

Set up a Client

1. In the terminal navigate to `./clients/web`
2. Run `npm install`

Set up a Server

1. In the terminal navigate to `./servers/nodejs`
2. Run `npm install`
3. Start the server using `npm start`

## Open a Client

The web Client is automatically running with the Node Server

- Navigate to http://localhost:3000 to open it.

Mobile Client

- ...stay tuned...
