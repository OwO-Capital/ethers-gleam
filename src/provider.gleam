//// Module for Ethereum providers (e.g JSON-RPC, Alchemy, IPC, etc)

import error.{type RpcError}
import falcon.{type FalconError, extract_headers, merge_opts, new}
import falcon/core.{
  type FalconResponse, type Opts, ClientOptions, Headers, Json, Url,
}
import falcon/hackney.{Timeout}
import gleam/dynamic
import gleam/int.{parse}
import gleam/json
import gleeunit/should

pub opaque type EthereumProvider {
  JsonRpcProvider(rpc_url: String)
}

type JsonRpcCall {
  JsonRpcCall(jsonrpc: String, method: String, params: List(String), id: Int)
}

type JsonRpcResponse {
  JsonRpcResponse(result: String)
}

/// Creates a new JSON-RPC provider.
pub fn new_json_rpc_provider(rpc_url: String) -> EthereumProvider {
  JsonRpcProvider(rpc_url)
}

/// Fetches the current block number using `eth_blockNumber`.
pub fn get_block_number(provider: EthereumProvider) -> Result(Int, Nil) {
  case provider {
    JsonRpcProvider(rpc_url) -> {
      let decoder =
        dynamic.decode1(
          JsonRpcResponse,
          dynamic.field("result", dynamic.string),
        )
      let call = JsonRpcCall("2.0", "eth_blockNumber", [], 0)
      let call_body =
        call
        |> encode_rpc_call
        |> json.to_string

      let res =
        falcon.new(
          base_url: Url(rpc_url),
          headers: [#("content-type", "application/json")],
          timeout: falcon.default_timeout,
        )
        |> falcon.post("/", call_body, Json(decoder), options: [])
        |> should.be_ok
        |> fn(res: FalconResponse(JsonRpcResponse)) { res.body }

      parse(res.result)
    }
  }
}

fn encode_rpc_call(json_rpc_call: JsonRpcCall) {
  json.object([
    #("jsonrpc", json.string(json_rpc_call.jsonrpc)),
    #("method", json.string(json_rpc_call.method)),
    #("params", json.array(from: json_rpc_call.params, of: json.string)),
    #("id", json.int(json_rpc_call.id)),
  ])
}

fn handle_rpc_res(res: Result(FalconResponse(JsonRpcResponse), FalconError)) {
  todo
  "Implement handling the response so that any errors from Falcon will be logged thru ``io.debug()``"
}
