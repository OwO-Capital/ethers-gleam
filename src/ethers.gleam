import gleam/io
import provider

fn test_json_rpc() {
  // TODO: Use environment variable for RPC
  let rpc_prov =
    provider.new_json_rpc_provider("<Alchemy or whatever goes here>")
  let block_num = provider.get_block_number(rpc_prov)

  io.debug(block_num)
}

pub fn main() {
  let _ = test_json_rpc()
  io.println("Some testing will be here at some point :)")
}
