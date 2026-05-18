let widget = null;
const widgetMessagesDisplay = document.querySelector("#connect-messages");

const API_ENDPOINTS = {
  webConnectUrl: "/api/web_url",
  webVerificationUrl: "/api/web_verification_url",
  hybridMobileVerificationUrl: "/api/hybrid_mobile_verification_url",
};

let isInMobileContext = false;

/**
 * This is one way to receive Post Messages on your own webpage.
 * The web-widget-sdk has callbacks that can be used instead of
 * manually listening for messages like this.
 */
window.addEventListener("message", (messageEvent) => {
  if (messageEvent?.data?.mx === true) {
    console.log("MX Connect message (widget event)", messageEvent.data);

    const codePreElement = document.createElement("pre");
    const messageElement = document.createElement("code");
    messageElement.innerText = JSON.stringify(messageEvent.data, null, 2);
    codePreElement.appendChild(messageElement);
    widgetMessagesDisplay.appendChild(codePreElement);
    widgetMessagesDisplay.scrollTop = widgetMessagesDisplay.scrollHeight;

    if (messageEvent.data?.type == "mx/connect/oauthRequested") {
      if (isInMobileContext) {
        window.open(messageEvent.data.metadata.url);
      }
    }
  }
});

/**
 * On a button click open the Connect Widget (aggregation) using the MX Web Widget SDK.
 */
document
  .querySelector("#connect-widget-button")
  .addEventListener("click", async () => {
    const response = await getWebConnectUrl(API_ENDPOINTS.webConnectUrl);
    console.log("MX Connect url response", response);
    isInMobileContext = false;
    renderWidgetWithUrl(response?.widget_url?.url);
  });

/**
 * On a button click open the Connect Widget (verification) using the MX Web Widget SDK.
 */
document
  .querySelector("#connect-widget-verification-button")
  .addEventListener("click", async () => {
    const response = await getWebConnectUrl(API_ENDPOINTS.webVerificationUrl);
    console.log("MX Connect url response", response);
    isInMobileContext = false;
    renderWidgetWithUrl(response?.widget_url?.url);
  });

/**
 * On a button click open the Connect Widget (hybrid mobile verification) using the MX Web Widget SDK.
 */
document
  .querySelector("#connect-widget-hybrid-mobile-verification-button")
  .addEventListener("click", async () => {
    const response = await getWebConnectUrl(
      API_ENDPOINTS.hybridMobileVerificationUrl,
    );
    console.log("MX Connect url response", response);
    isInMobileContext = true;
    renderWidgetWithUrl(response?.widget_url?.url);
  });

// Close the widget with the SDK's unmount() function on a button click.
document
  .querySelector("#connect-widget-close")
  .addEventListener("click", () => {
    if (widget !== null) {
      widget?.unmount();
    }
  });

// `widgetSdk` is currently imported directly in the html page.
// It could also be imported using ESModules if a bundler like rollup
// is used to package your frontend app together.
async function renderWidgetWithUrl(url) {
  widget = new widgetSdk.ConnectWidget({
    container: "#connect-widget",
    url,
  });
}

/**
 * @description This function relies on the backend server's interaction
 * with the MX Platform API to get the widget URL.
 *
 * @returns a JSON response containing the url to the Connect widget
 */
async function getWebConnectUrl(url) {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Response status: ${response.status}`);
    }

    const json = await response.json();
    console.log(json);
    return json;
  } catch (error) {
    console.error(error.message);
  }
}
