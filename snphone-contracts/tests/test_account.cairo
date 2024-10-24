use snforge_std::{declare, ContractClassTrait};
use snforge_std::{start_prank, stop_prank, CheatTarget};
use starknet::contract_address_const;
use contracts::account::{IStarknetPhoneAccountDispatcher, IStarknetPhoneAccountDispatcherTrait};

#[test]
fn test_deploy() {
    let class_hash = declare("StarknetPhoneAccount");
    let _pub_key = 'pub_key';
    let contract_address = class_hash.deploy(@array![_pub_key]).unwrap();
    let wallet = IStarknetPhoneAccountDispatcher { contract_address };

    let pub_key = wallet.get_public_key();
    assert(pub_key == _pub_key, 'Pub key not set');
}

// Test that only the contract owner can change the public key
#[test]
fn test_only_account_can_change_public_key() {
    let class_hash = declare("StarknetPhoneAccount");
    let _pub_key = 'pub_key';
    let contract_address = class_hash.deploy(@array![_pub_key]).unwrap();
    let wallet = IStarknetPhoneAccountDispatcher { contract_address };

    // Other contract calls function
    let new_pub_key = 'new_pub_key';

    start_prank(CheatTarget::One(wallet.contract_address), contract_address);
    wallet.set_public_key(new_pub_key);
    stop_prank(CheatTarget::One(wallet.contract_address));

    assert(wallet.get_public_key() == new_pub_key, 'Pub key should change');
}

// Test only the wallet can change its public key
#[test]
#[should_panic]
fn test_other_account_cannot_change_public_key() {
    let class_hash = declare("StarknetPhoneAccount");
    let _pub_key = 'pub_key';
    let contract_address = class_hash.deploy(@array![_pub_key]).unwrap();
    let wallet = IStarknetPhoneAccountDispatcher { contract_address };

    // Other contract calls function
    let not_wallet = contract_address_const::<'not_wallet'>();
    let new_pub_key = 'new_pub_key';

    start_prank(CheatTarget::One(wallet.contract_address), not_wallet);
    wallet.set_public_key(new_pub_key);
    stop_prank(CheatTarget::One(wallet.contract_address));

    assert(wallet.get_public_key() != new_pub_key, 'Pub key should not change');
}
// TODO: Upgrade to scarb 2.8.4
// TODO: Test is_valid_signature() works as expected (valid returns true, anything else returns false (check 0 hash and empty sigs as well))
// TODO: Test __execute__() works as expected (solo and multi-calls should work as expected)
//        - Might need to create a mock erc20 contract to test calls (see if the wallet is able to do a multi call (try sending eth to 2 accounts from the deployed wallet, both accounts' balance should update)
// TODO: Research if OZ erc20/721/1155 contracts have any logic requiring the wallet to verify it can receive tokens (on solidity, some nft contracts require that the receiver explicitly states that it can receive these tokens, look into safeTransferFrom, etc)
//        - If there is no such logic, ignore the 2 points below
// TODO: Test that wallet can receive & transfer ERC20 tokens
// TODO: Test that wallet can receive/transfer ERC721/1155 tokens


// Down the pipeline:
// - Test typical deployment flow:
//  - Wallet class hash is declared on the network
//  - In wallet app, user creates a new wallet (save this deployment data, it is essentially the constructor args for the wallet)
//  - Wallet needs to be funded to be deployed (user must send eth/strk to the created wallet address, wallet is not actually deployed at this time)
//  - In wallet app, user should see a button to deploy/initialize their wallet (now that it is funded)
//  - This txn should deploy the wallet to the pre calculated address (using the deployment data created during 'create new wallet')
//  - Once this txn is complete, the wallet should be charged the deployment gas fees, and be fully operational after this point

// Notes for AA/Sn wallets:
// - On Starknet, a wallet's address is not the same as its public key (on EVM they are the same thing).
//  - This allows a user to keep their same wallet address, but change their signing key if they wish (user changes their public key, meaning the is_valid_signature() function will return false if the old private key is used to sign txns)
//    - (on EVM if your private key is compromised, your whole wallet is because that private key will always be able to sign that address/public key's txns, whereas on starknet, if the private key is compromised, you can update the public key, keeping the same wallet address, but now the compromised private key is useless)
//      - (you would also need to beat the malicious party to the set_public_key() function call for this to work, or else they could lock you out of the wallet, see argent guardians or braavos recovery/lockdown windows)
// - The deployment data (typically JSON) contains all of the necessary info about a wallet (the data necessary to deploy it (salt, etc), and also its original public/private key)

// For Spicing Up The Wallet:
// - Braavos and Argent have some pretty cool features that are seeming standard on Starknet, might want to implement a few of them:
//  - Braavos has hardware signing (faceID, touchID, etc)
//    - This feature allows you to have a 12 word seed phrase, but also requires a secondary signature (pk for this is stored in secure-enclave). Turning this feature on means even if someone steals your passphrase, they would also need the extra key from your secure enclave to send any txns (they will be able to load the wallet on their phone but not be able to send/sign anything)
//  - Argent has guardians for changing the public key, I'm not sure the exact source code, but the flow is something like:
//    - Alice creates an argent wallet on her phone and sets up guardians (she sets her ipad as 1 guardian, and her computer as another. these are both different staknet wallets)
//    - Alice loses her phone and passphrase but she wants into her wallet with a new private key
//    - She initiates a recovery process. This process requires one or more of her guardians to sign txns allowing the set_public_key() function to be called. Since its essentially a multi-sig, the guardians cant take over the wallet easily, and can be used to get Alice access to her wallet again
//    - Alice's guardians allow her/or themselves to then set a new public key (which alice owns the private key to), once the new public key is set, alice has signing control of her wallet again
//  - Both wallets have recovery windows. If Matt is logged into an Argent wallet on his phone, and wants to also put the wallet on his iPad, he logs in on the iPad, and starts a wallet recovery.
//    This recovery sets a 48 hour window before the iPad has access to the wallet. The idea is that if someone hacks into Matt's Argent account, he will get an alert and have 48 hours to change the public key/cancel the recovery and change his passwords
// - AA wallets really have endless possibilities, can code in almost any logic into the is_valid_signature() functions, can add any form of public key changing flows, can explore restricted wallets (cant spend more than X of this token every Y days, etc), pretty sure there is already work exploring trades happening in a multicall to allow a user to use any token for gas fees
