import pytest
from brownie import network

from scripts.deploy_auction import deploy_auction
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account


def test_deploy_auction():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Test only runs on local blockchain")
    auction = deploy_auction()
    assert auction.address is not None
