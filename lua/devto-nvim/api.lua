local M = {}
local notify = require("devto-nvim.notify")
local article = require("devto-nvim.article")

--- Get the API key from the environment
--- @return string? The API key, or nil if it is not set
function M.key()
  return vim.env.DEVTO_API_KEY
end

--- The base URL for the API
local BASE_URL = "https://dev.to/api"

---@class Response
---@field status number
---@field body table

---@class CurlOptions
---@field headers table<string, string>?
---@field body table?

---@alias Method "GET" | "POST" | "PUT" | "DELETE"

--- Handle an error response
--- If the response is successful, the `on_success` callback will be called with the response body
--- If the response is an error, the error will be displayed to the user
---@param response Response
---@param on_success fun(body: table)
function M.handle_error(response, on_success)
  local start_status = string.sub(response.status, 1, 2)

  if start_status == "20" then
    on_success(response.body)
  else
    local error = response
    if response.body then
      error = response.body
      if response.body.error then
        error = response.body.error
      end
    end
    notify.error("Error: " .. tostring(error))
  end
end

--- Convert a `vim.SystemCompleted` object to a `Response` object
---@param out vim.SystemCompleted
---@return Response
local function system_completed_to_response(out)
  local status_code = nil
  local response_body = nil

  if out.stdout then
    -- Extract status code from headers
    status_code = out.stdout:match("HTTP/%d%.?%d?%s+(%d+)")

    -- Extract the body from the response (everything after the headers)
    response_body = out.stdout:match("\n\n(.*)")
  end

  local body = nil
  -- Only attempt to decode if we have a body
  if response_body and response_body ~= "" then
    -- Protect against JSON decode errors
    body = vim.json.decode(response_body)
  end

  return {
    status = status_code,
    body = body
  }
end

--- Make a curl request
---@param method Method The HTTP method to use
---@param endpoint string The endpoint to hit
---@param options CurlOptions Options to pass to curl
---@param on_exit fun(response: Response)? A callback to run when the request is complete, if not provided the request will be synchronous
---@return vim.SystemObj
local function curl(method, endpoint, options, on_exit)
  local headers = options.headers or {}
  local request_body = options.body and { "-d", vim.json.encode(options.body) } or {}

  local cmd = vim.iter({
    "curl",
    "-X",
    method,
    "-i", -- Include headers in the output
    vim.tbl_map(function(header)
      return { "-H", header }
    end, headers),
    request_body,
    BASE_URL .. endpoint
  }):flatten(2):totable()

  return vim.system(cmd, { text = true }, function(out)
    vim.schedule(function()
      local response = system_completed_to_response(out)
      if on_exit then
        on_exit(response)
      end
    end)
  end)
end

--- Make a synchronous request to the API
---@param method Method The HTTP method to use
---@param endpoint string The endpoint to hit
---@param options CurlOptions Options to pass to curl
---@return Response
local function request(method, endpoint, options)
  ---@type CurlOptions
  local parameters = vim.tbl_extend(
    "force",
    {
      headers = {
        "api-key: " .. M.key(),
        "Content-Type: application/json",
        "Accept: application/vnd.devto.api-v1+json"
      }
    },
    options
  )

  local out = curl(method, endpoint, parameters, nil):wait()
  local response = system_completed_to_response(out)

  return response
end

--- Make an asynchronous request to the API
---@param method Method The HTTP method to use
---@param endpoint string The endpoint to hit
---@param on_success fun(body: table) A callback to run when the request is successful
local function request_async(method, endpoint, on_success)
  ---@type CurlOptions
  local options = {
    headers = {
      "Api-Key: " .. M.key()
    }
  }

  curl(method, endpoint, options, function(response)
    M.handle_error(
      response,
      on_success
    )
  end
  )
end

--- Make a asynchronous GET request to the API
---@param endpoint string The endpoint to hit
---@param on_success fun(body: table) A callback to run when the request is successful
local function get(endpoint, on_success)
  request_async(
    "GET",
    endpoint,
    on_success
  )
end

--- Make a synchronous PUT request to the API
---@param endpoint string The endpoint to hit
---@param body table The body of the request
---@return Response
local function put(endpoint, body)
  return request("PUT", endpoint, { body = body })
end

--- Make a synchronous POST request to the API
---@param endpoint string The endpoint to hit
---@param body table The body of the request
---@return Response
local function post(endpoint, body)
  return request("POST", endpoint, { body = body })
end

--- Fetch all articles for the current user
--- The request is asynchronous
---@param on_success fun(body: table) A callback to run when the request is successful
function M.my_articles(on_success)
  return get("/articles/me/all", on_success)
end

--- Save an article
--- The request is synchronous
---@param id number The ID of the article to save
---@param content string The new content of the article
---@return Response
function M.save_article(id, content)
  return put(
    "/articles/" .. tostring(id),
    { article = { body_markdown = content } }
  )
end

--- Create a new article
--- The request is synchronous
---@param title string The title of the new article
---@return Response
function M.new_article(title)
  return post(
    "/articles",
    { article = { body_markdown = article.get_template(title) } }
  )
end

--- Fetch the feed of articles of the current user
--- The request is asynchronous
---@param on_success fun(body: FeedArticle[]) A callback to run when the request is successful
function M.feed(on_success)
  get("/articles", on_success)
end

--- Fetch an article by ID
--- The request is asynchronous
---@param id number The ID of the article to fetch
---@param on_success fun(body: table) A callback to run when the request is successful
function M.get_article(id, on_success)
  get(
    "/articles/" .. tostring(id),
    on_success
  )
end

--- Fetch an article by path
--- The request is asynchronous
---@param path string The path of the article to fetch
---@param on_success fun(body: table) A callback to run when the request is successful
function M.get_article_by_path(path, on_success)
  get("/articles/" .. path, on_success)
end

return M
