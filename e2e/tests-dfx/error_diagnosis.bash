#!/usr/bin/env bats

load ../utils/_

setup() {
    standard_setup
}

teardown() {
    dfx_stop

    standard_teardown
}

@test "Duplicate assets in dist/ from src/" {
    dfx_new_frontend hello
    install_asset greet
    dfx_start
    assert_command dfx deploy

    # simulate previous deploy with CopyPlugin step
    cp src/hello_frontend/assets/* dist/hello_frontend/

    assert_command_fail dfx deploy
    assert_contains "Remove the CopyPlugin step from webpack.config.js"
    assert_contains "Delete all files from the dist/ directory"
}

@test "HTTP 403 has a full diagnosis" {
    dfx_new hello
    install_asset greet
    dfx_start
    assert_command dfx deploy
    
    # make sure normal status command works
    assert_command dfx canister status hello_backend

    # create a non-controller ID
    assert_command dfx identity new alice --storage-mode plaintext
    assert_command dfx identity use alice

    # calling canister status with different identity provokes HTTP 403
    assert_command_fail dfx canister status hello_backend
    assert_match "not part of the controllers" # this is part of the error explanation
    assert_match "'dfx canister update-settings --add-controller <controller principal to add> <canister id/name or --all> \(--network ic\)'" # this is part of the solution
}

@test "Instruct user to set a wallet" {
    dfx_new hello
    install_asset greet
    assert_command dfx identity new alice --storage-mode plaintext
    assert_command dfx identity use alice

    # this will fail because no wallet is configured for alice on network ic
    assert_command_fail dfx deploy --network ic
    assert_match "requires a configured wallet" # this is part of the error explanation
    assert_match "'dfx identity set-wallet <wallet id> --network <network name>'" # this is part of the solution
}
