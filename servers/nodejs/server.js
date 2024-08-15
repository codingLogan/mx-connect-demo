/**
 * -----------------------------------------------------------
 * Note
 * -----------------------------------------------------------
 * This server assumes that only a demo user will be used,
 * in order to simplify the demo's scope.
 *
 * On boot of the server, the application will attempt to find
 * or create a demo user and will use it for ALL API requests.
 */

import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import * as api from "./api.js";
import express from "express";

/**
 *
 * @param {fn} userHandler the user will be passed to this handler.
 * @param {*} errorMessageHandler on error, this handler will be called
 * with a message string.
 */
function initializeDemoUser(userHandler, errorMessageHandler) {
  const DEMO_USER_ID = "connectdemo";

  api.get(`/users?id=${DEMO_USER_ID}`).then(
    (searchResults) => {
      if (!searchResults?.users?.length) {
        // If there's not a demo user yet, create one and return it instead
        api
          .post("/users", {
            user: {
              id: DEMO_USER_ID,
              metadata:
                '{\\"first_name\\": \\"MX\\", \\"last_name\\": \\"Demo\\"}',
            },
          })
          .then(
            () => {
              console.log("Create a brand-new demo user");
              userHandler;
            },
            () => {
              errorMessageHandler("Demo user create error");
            }
          );
      } else {
        console.log("Using an already-created demo user");
        userHandler(searchResults.users[0]);
      }
    },
    () => {
      errorMessageHandler("Demo user search error");
    }
  );
}

// Populate the environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: `${__dirname}/../../.env` });

// Configure the API
api.config(process.env.CLIENT_ID, process.env.API_KEY);

const app = express();

// Find or create the demo user, and keep a reference to it for future API calls.
// (this strategy may change later)
let demoUser = null;
initializeDemoUser(
  (user) => {
    demoUser = user;
    console.log(demoUser);
  },
  (message) => {
    console.error(
      "Demo could not get or create the user it needs, server aborting..."
    );
    console.error(message);
    process.exit(1);
  }
);

app.listen(3000);

/**
 * Serve a simple frontend web page that uses Connect.
 * Go to http://localhost:3000 to open the web page.
 */
app.use(express.static(path.join(__dirname, "/../../clients/web")));

// Endpoint - Returns a basic mx Connect Widget Url.
app.get("/api/web_url", (req, res) => {
  api
    .post(`/users/${demoUser.guid}/widget_urls`, {
      widget_url: {
        ui_message_version: 4,
        widget_type: "connect_widget",
      },
    })
    .then(
      (urlResponse) => {
        res.json(urlResponse);
      },
      (urlError) => {
        console.error(urlError);
        res.statusCode(500);
        res.json("Something went wrong getting a widget URL");
      }
    );
});

// Endpoint - Returns a basic mx Connect Widget Url.
app.get("/api/mobile_url", (req, res) => {
  api
    .post(`/users/${demoUser.guid}/widget_urls`, {
      widget_url: {
        ui_message_version: 4,
        widget_type: "connect_widget",
        is_mobile_webview: true,
        ui_message_webview_url_scheme: "mxconnectdemo",
      },
    })
    .then(
      (urlResponse) => {
        res.json(urlResponse);
      },
      (urlError) => {
        console.error(urlError);
        res.statusCode(500);
        res.json("Something went wrong getting a widget URL");
      }
    );
});
