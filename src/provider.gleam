//// Module for Ethereum providers (e.g JSON-RPC, Alchemy, IPC, etc)

import error.{type RpcError}
import gleam/dynamic
import gleam/hackney
import gleam/http.{Post}
import gleam/http/request
import gleam/int.{base_parse}
import gleam/json
import gleam/result
import gleam/string

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
      use rpc_res <- result.try(rpc_call(rpc_url, "eth_blockNumber", []))
      use block_num <- result.try(process_hex(rpc_res.result))
      Ok(block_num)
    }
  }
}

pub fn get_chain_id(provider: EthereumProvider) -> Result(Int, RpcError) {
  case provider {
    JsonRpcProvider(rpc_url) -> {
      use rpc_res <- result.try(rpc_call(rpc_url, "eth_chainId", []))
      use chain_id <- result.try(process_hex(rpc_res.result))
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
      use rpc_res <- result.try(
        rpc_call(rpc_url, "eth_getBalance", [address, "latest"]),
      )
      use balance <- result.try(process_hex(rpc_res.result))
      Ok(balance)
    }
  }
}

fn process_hex(hex_string: String) -> Result(Int, RpcError) {
  hex_string
  |> string.drop_left(2)
  |> base_parse(16)
  |> result.map_error(fn(_) { error.CallFailed })
}

fn rpc_call(
  url: String,
  method: String,
  params: List(String),
) -> Result(JsonRpcResponse, RpcError) {
  let call = JsonRpcCall("2.0", method, params, 0)
  let decoder =
    dynamic.decode1(JsonRpcResponse, dynamic.field("result", dynamic.string))
  let call_body =
    call
    |> encode_rpc_call
    |> json.to_string

  use request <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { error.InvalidUrl }),
  )

  use response <- result.try(
    request
    |> request.prepend_header("content-type", "application/json")
    |> request.set_method(Post)
    |> request.set_body(call_body)
    |> hackney.send
    |> result.map_error(fn(_) { error.CallFailed }),
  )

  case response.status {
    200 -> {
      json.decode(response.body, decoder)
      |> result.map_error(fn(_) { error.CallFailed })
    }
    _ -> Error(error.CallFailed)
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
