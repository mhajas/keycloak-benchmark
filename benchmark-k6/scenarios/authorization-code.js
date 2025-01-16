// import necessary modules
import { check } from 'k6';
import http from 'k6/http';
import { uuidv4 } from "https://jslib.k6.io/k6-utils/1.0.0/index.js";

// define configuration
export const options = {

  scenarios: {
    constant_load: {
      executor: 'constant-arrival-rate',
      preAllocatedVUs: 300,
      rate: 150,
      duration: '300s'
    },
  },

  // Do not reuse connection the same way as we do in Gatling
  noVUConnectionReuse: true,
  insecureSkipTLSVerify: true,
  summaryTrendStats: ['count', 'min', 'p(50)', 'p(75)', 'p(95)', 'p(99)', 'max', 'med', ],
  thresholds: {
    'http_req_duration{name:OpenLoginForm}': [],
    'http_req_duration{name:SubmitLoginForm}': [],
    'http_req_duration{name:ExchangeCode}': [],
    'http_req_duration{name:Logout}': [],
  }

};

const BASE_URL = __ENV.KEYCLOAK_URL || "http://localhost:8080"
const REALM_URL = BASE_URL + "/realms/realm-0";
const AUTH_ENDPOINT = REALM_URL + "/protocol/openid-connect/auth";
const TOKEN_ENDPOINT = REALM_URL + "/protocol/openid-connect/token";
const LOGOUT_ENDPOINT = REALM_URL + "/protocol/openid-connect/logout"

export default function () {
  // define URL and request body

  const redirectUri = "http://localhost:8080/realms/realm-0/account";
  const params = {
    headers: {
      'Accept': 'text/html,application/xhtml+xml,application/xml',
      'Accept-Encoding': 'gzip, deflate',
      'Accept-Language': 'en-US,en;q=0.5',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:16.0) Gecko/20100101 Firefox/16.0'
    },
    redirects: 0,
  };
  const queryParams = {
    "login": "true",
    "response_type": "code",
    "client_id": "client-0",
    "state": uuidv4(),
    "redirect_uri": redirectUri,
    "scope": "openid"
  }

  buildQueryString(queryParams);

  // send a post request and save response as a variable
  const login_page_response = http.get(`${AUTH_ENDPOINT}?${buildQueryString(queryParams)}`, Object.assign({tags: {name: "OpenLoginForm"}}, params));

  // check that response is 200
  check(login_page_response, {
    'response code was 200': (res) => res.status === 200,
  });

  let authorization_response = login_page_response.submitForm({
    formSelector: '#kc-form-login',
    fields: { username: "user-0", password: "user-0-password" },
    params: { redirects: 0, tags: { name: "SubmitLoginForm" } },
  });

  let location = authorization_response.headers["Location"];
  let re = /[&?]code=([^&]+)(&|$)/g;
  let matches = [... location.matchAll(re) ];
  let code = matches[0][1];

  let access_token_request = {
    "grant_type": "authorization_code",
    "code": code,
    "redirect_uri": queryParams.redirect_uri,
    "client_id": "client-0",
    "client_secret": "client-0-secret"
  };
  let access_token_response = http.post(TOKEN_ENDPOINT, access_token_request, Object.assign({tags: {name: "ExchangeCode"}}, params));

  check(access_token_response, {
    'access_token_response.status == 200': (http) => http.status === 200,
  });

  if (access_token_response.status !== 200) {
    throw new Error(`access_token_response.status is ${access_token_response.status}, expected 200`);
  }

  let logoutQueryParams = {
    "client_id": "client-0",
    "post_logout_redirect_uri": redirectUri,
    "id_token_hint": access_token_response.json()["id_token"],
  }

  let logout_response = http.get(`${LOGOUT_ENDPOINT}?${buildQueryString(logoutQueryParams)}`, Object.assign({tags: {name: "Logout"}}, params))

  check(logout_response, {
    'logout_response.status == 302': (http) => http.status === 302,
  });
}

function buildQueryString(data) {
  const result = [];

  Object.keys(data)
      .forEach((key) => {
        const encode = encodeURIComponent;
        result.push(encode(key) + "=" + encode(data[key]));
      });

  return result.join("&");
}
