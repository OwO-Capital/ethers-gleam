import gleam/io
import gleam/result.{try}
import glenvy/env.{get_string}
import provider

fn test_json_rpc() {
  use rpc_url <- try(get_string("ETHERS_RPC_URL"))
  let rpc_prov = provider.new_json_rpc_provider(rpc_url)
  let block_num = provider.get_block_number(rpc_prov)

  let _ = io.debug(block_num)

  Ok(Nil)
}

pub fn main() {
  let _ = test_json_rpc()
  io.println("Some testing will be here at some point :)")
}
