import https from "https";

// Keep a reference to the needed MX headers for use in ALL API calls.
let MX_PLATFORM_API_HEADERS = null;

/**
 * @description Use this function to set up the headers for all future API calls.
 * (It is currently called when the server is booting up)
 * @param {string} clientId this value is given to you from MX when you sign up.
 * @param {string} apiKey this value is given to you from MX when you sign up.
 */
export function config(clientId, apiKey) {
  MX_PLATFORM_API_HEADERS = {
    "Content-Type": "application/json",
    Accept: "application/vnd.mx.api.v1+json",
    Authorization: `Basic ${getBase64StringOf(`${clientId}:${apiKey}`)}`,
  };
}

/**
 *
 * @param {string} idAndKeyString any string
 * @returns a Base64 encoded string of idAndKeyString
 */
function getBase64StringOf(idAndKeyString) {
  const base64String = Buffer.from(idAndKeyString).toString("base64");
  return base64String;
}

/**
 *
 * @param {object} options see Node's http and https request options
 * @param {string} data stringified data, ready to be sent via POST.
 * @returns Promise containing the request results
 */
export async function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    let responseData = "";
    const mxRequest = https.request(options, (res) => {
      console.log(`STATUS: ${res.statusCode}`);
      console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
      res.setEncoding("utf8");
      res.on("data", (chunk) => {
        console.log(`BODY: ${chunk}`);
        responseData += chunk;
      });
      res.on("end", () => {
        console.log("No more data in response.");
        const jsonResponse = JSON.parse(responseData);
        console.log(jsonResponse);
        resolve(jsonResponse);
      });
    });

    mxRequest.on("error", (error) => reject(error));

    if (data && options.method === "POST") {
      mxRequest.write(data);
    }

    mxRequest.end();
  });
}

/**
 *
 * @param {string} endpoint the path and query params to send if any.
 * ex: /api/web_url
 * ex: /users?id=connectdemo
 * @param {object} rawData the data that you wish to send to the server.
 * @returns Promise containing the POST results.
 */
export async function post(endpoint, rawData) {
  const data = JSON.stringify(rawData);
  const allOptions = {
    hostname: "int-api.mx.com",
    path: endpoint,
    method: "POST",
    headers: {
      ...MX_PLATFORM_API_HEADERS,
      "Content-Length": Buffer.byteLength(data),
    },
  };

  return await makeRequest(allOptions, data);
}

/**
 *
 * @param {string} endpoint the path and query params to send if any.
 * ex: /api/web_url
 * ex: /users?id=connectdemo
 * @returns Promise containing the GET results.
 */
export async function get(endpoint) {
  const allOptions = {
    hostname: "int-api.mx.com",
    path: endpoint,
    method: "GET",
    headers: { ...MX_PLATFORM_API_HEADERS },
  };

  return await makeRequest(allOptions);
}
