use core::result::ResultTrait;
use snforge_std::{declare, ContractClassTrait};

use contracts::account::{IStarknetPhoneAccountDispatcher, IStarknetPhoneAccountDispatcherTrait};

#[test]
fn test_deploy() {
    let contract = declare("StarknetPhoneAccount");
    let c_pub_key = 'pub_key';
    let contract_address = contract.deploy(@array![c_pub_key]).unwrap();

    let dispatcher = IStarknetPhoneAccountDispatcher { contract_address };

    let pub_key = dispatcher.get_public_key();
    assert(pub_key == c_pub_key, 'balance == 0');
}
