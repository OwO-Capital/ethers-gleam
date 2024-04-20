//// Module for Ethereum providers (e.g JSON-RPC, Alchemy, IPC, etc)

import error.{type RpcError}
import gleam/dynamic
import gleam/hackney
import gleam/http.{Post}
import gleam/http/request
import gleam/int.{base_parse}
import gleam/json
import gleam/result
import gleam/string.{drop_left}
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
pub fn get_block_number(provider: EthereumProvider) -> Result(Int, RpcError) {
  case provider {
    JsonRpcProvider(rpc_url) -> {
      let rpc_res = rpc_call(rpc_url, "eth_blockNumber", [])
      let block_num =
        drop_left(rpc_res.result, 2)
        |> base_parse(16)
        |> result.unwrap(0)

      should.not_equal(block_num, 0)
      // TODO: We could handle unwrapping better

      Ok(block_num)
    }
  }
}

pub fn get_chain_id(provider: EthereumProvider) -> Result(Int, RpcError) {
  case provider {
    JsonRpcProvider(rpc_url) -> {
      let rpc_res = rpc_call(rpc_url, "eth_chainId", [])
      let chain_id =
        drop_left(rpc_res.result, 2)
        |> base_parse(16)
        |> result.unwrap(0)

      should.not_equal(chain_id, 0)
      // TODO: We could handle unwrapping better

      Ok(chain_id)
    }
  }
}

pub fn get_balance(
  provider: EthereumProvider,
  address: String,
) -> Result(Int, RpcError) {
  case provider {
    JsonRpcProvider(rpc_url) -> {
      let rpc_res = rpc_call(rpc_url, "eth_getBalance", [address, "latest"])
      let balance = process_hex(rpc_res.result)

      Ok(balance)
    }
  }
}

fn process_hex(hex_string: String) -> Int {
  drop_left(hex_string, 2)
  |> base_parse(16)
  |> result.unwrap(0)
  // TODO: Better unwrapping starts here ^
}

fn rpc_call(
  url: String,
  method: String,
  params: List(String),
) -> JsonRpcResponse {
  let call = JsonRpcCall("2.0", method, params, 0)
  let decoder =
    dynamic.decode1(JsonRpcResponse, dynamic.field("result", dynamic.string))
  let call_body =
    call
    |> encode_rpc_call
    |> json.to_string

  // Send RPC call.
  let assert Ok(request) = request.to(url)
  let assert Ok(response) =
    request
    |> request.prepend_header("content-type", "application/json")
    |> request.set_method(Post)
    |> request.set_body(call_body)
    |> hackney.send

  response.status
  |> should.equal(200)

  let assert Ok(rpc_res) = json.decode(response.body, decoder)
  rpc_res
}

fn encode_rpc_call(json_rpc_call: JsonRpcCall) {
  json.object([
    #("jsonrpc", json.string(json_rpc_call.jsonrpc)),
    #("method", json.string(json_rpc_call.method)),
    #("params", json.array(from: json_rpc_call.params, of: json.string)),
    #("id", json.int(json_rpc_call.id)),
  ])
}
//fn handle_rpc_res(res: Result(FalconResponse(JsonRpcResponse), FalconError)) {
//  todo
//  "Implement handling the response so that any errors from Falcon will be logged thru ``io.debug()``"
//}
