from datetime import datetime
from scripts.helpful_scripts import get_account
from brownie import Auction, BlindAuction


def deploy_auction():
    account = get_account()
    auction_start = int(datetime.now().timestamp())
    auction_end = auction_start + 3600
    auction = Auction.deploy(account, auction_start, auction_end, {
        "from": account
    })
    print("Auction deployed at:", auction.address)
    return auction

def deploy_blind_auction():
    account = get_account()
    auction_start = int(datetime.now().timestamp())
    auction_end = auction_start + 3600
    auction = BlindAuction.deploy(account, auction_start, auction_end, {
        "from": account
    })
    print("Blind Auction deployed at:", auction.address)
    return auction

def main():
    deploy_auction()