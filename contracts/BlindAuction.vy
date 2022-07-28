# @version ^0.3.3

struct Bid:
    blindedBid: bytes32
    deposit: uint256

# Vyper doesnot allow dynamic arrays, so limited the number of bids that can be placed for an address
MAX_BIDS: constant(int128) = 128

event AuctionEnded:
    hidhestBidder: address
    highestBid: uint256

# Auction params
beneficiary: public(address)
biddingEnd: public(uint256)
revealEnd: public(uint256)

# set at end of the auction
ended: public(bool)

# final auction state
highestBid: public(uint256)
hidhestBidder: public(address)

# state of bids
bids: HashMap[address, Bid[MAX_BIDS]]
bidCounts: HashMap[address, int128]

pendingReturns: HashMap[address, uint256]

# Place a blinded bid with:
#
# _blindedBid = keccak256(concat(
#       convert(value, bytes32),
#       convert(fake, bytes32),
#       secret)
# )
#
# The sent ether is only refunded if the bid is correctly revealed in the
# revealing phase. The bid is valid if the ether sent together with the bid is
# at least "value" and "fake" is not true. Setting "fake" to true and sending
# not the exact amount are ways to hide the real bid but still make the
# required deposit. The same address can place multiple bids.


@external
def __init__(_beneficiary: address, _biddingTime: uint256, _revealTime: uint256):
    self.beneficiary = _beneficiary
    self.biddingEnd = block.timestamp + _biddingTime
    self.revealEnd = self.biddingEnd + _revealTime

@external
@payable
def bid(_blindedBid: bytes32):
    assert block.timestamp < self.biddingEnd, "Bidding time has ended"

    numBids: int128 = self.bidCounts[msg.sender]

    assert numBids < MAX_BIDS, "You have already placed the maximum number of bids"

    self.bids[msg.sender][numBids] = Bid({
        blindedBid: _blindedBid,
        deposit: msg.value
    })
    self.bidCounts[msg.sender] =+ 1

@internal
def placeBid(bidder: address,  _value: uint256) -> bool:
    if (_value <= self.highestBid):
        return False
    if (self.hidhestBidder != ZERO_ADDRESS):
        self.pendingReturns[self.hidhestBidder] += self.highestBid
    self.highestBid = _value
    self.hidhestBidder = bidder
    return True

@external
def reveal(_numBids: int128, _values: uint256[MAX_BIDS], _fakes: bool[MAX_BIDS], _secrets: bytes32[MAX_BIDS]):
    assert block.timestamp > self.biddingEnd, "Bidding time has not ended"
    assert block.timestamp < self.revealEnd, "Reveal time has ended"

    assert _numBids == self.bidCounts[msg.sender], "Wrong number of bids"

    # calculate refund for sender
    refund: uint256 = 0
    for i in range(MAX_BIDS):
        if i >= _numBids:
            break
        bidToCheck: Bid = self.bids[msg.sender][i]

        value: uint256 = _values[i]
        fake: bool = _fakes[i]
        secret: bytes32 = _secrets[i]
        blindedBid: bytes32 = keccak256(concat(
            convert(value, bytes32),
            convert(fake, bytes32),
            secret
        ))

        # donot refund if bid is not revealed
        assert blindedBid == bidToCheck.blindedBid, "Bid not revealed"

        refund += bidToCheck.deposit
        if (not fake and bidToCheck.deposit >= value):
            if (self.placeBid(msg.sender, value)):
                refund -= value
        bidToCheck.blindedBid = EMPTY_BYTES32
    
    if (refund != 0):
        send(msg.sender, refund)

@external
def auctionEnd():
    assert block.timestamp >= self.revealEnd, "Reveal time has not ended"
    assert not self.ended, "Auction has already ended"

    log AuctionEnded(self.hidhestBidder, self.highestBid)
    self.ended = True

    send(self.beneficiary, self.highestBid)