# @version ^0.3.3

# Auction params
# Beneficiary receives money from the highest bidder
beneficiary: public(address)
auctionStart: public(uint256)
auctionEnd: public(uint256)

# Current state of the auction
highestBidder: public(address)
highestBid: public(uint256)

# Set to true when the auction has ended
ended: public(bool)

pendingReturns: public(HashMap[address, uint256])

@external
def __init__(_beneficiary: address, _auction_start: uint256, _bidding_time: uint256):
    self.beneficiary = _beneficiary
    self.auctionStart = _auction_start
    self.auctionEnd = _auction_start + _bidding_time
    assert block.timestamp < self.auctionEnd

@external
@payable
def bid():
    assert block.timestamp >= self.auctionStart
    assert block.timestamp < self.auctionEnd
    assert msg.value > self.highestBid
    # track the refund for the previous highest bidder
    self.pendingReturns[self.highestBidder] += self.highestBid
    
    self.highestBidder = msg.sender
    self.highestBid = msg.value

@external
def withdraw():
    pending_amount: uint256 = self.pendingReturns[msg.sender]
    self.pendingReturns[msg.sender] = 0
    send(msg.sender, pending_amount)

@external
def endAuction():
    # checks
    assert block.timestamp >= self.auctionEnd
    assert not self.ended

    # effects
    self.ended = True

    # interaction
    send(self.beneficiary, self.highestBid)