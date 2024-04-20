import gleam/io
import gleam/result.{try}
import glenvy/env.{get_string}
import provider

fn test_json_rpc() {
  use rpc_url <- try(get_string("ETHERS_RPC_URL"))
  let rpc_prov = provider.new_json_rpc_provider(rpc_url)
  let block_num = provider.get_block_number(rpc_prov)
  let bal =
    provider.get_balance(rpc_prov, "0xb1eAfc8C60f68646F4EFbd3806875fE468933749")

  let _ = io.debug(block_num)
  let _ = io.debug(bal)

  Ok(Nil)
}

pub fn main() {
  let _ = test_json_rpc()
  io.println("Some testing will be here at some point :)")
}
