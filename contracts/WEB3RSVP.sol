//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract WEB3RSVP{
    event NewEventCreated(
    bytes32 eventID,
    address creatorAddress,
    uint256 eventTimestamp,
    uint256 maxCapacity,
    uint256 deposit,
    string eventDataCID
);

event NewRSVP(bytes32 eventID, address attendeeAddress);

event ConfirmedAttendee(bytes32 eventID, address attendeeAddress);

event DepositsPaidOut(bytes32 eventID);

    struct CreateEvent{
        bytes32 eventId;
        string eventDataCID;
        address eventOwner;
        uint256 eventTimestamp;
        uint256 deposit;
        uint256 maxCapacity;
        address[] confirmedRSVPs;
        address[] claimedRSVPs;
        bool paidOut;
    }

    mapping(bytes32 => CreateEvent) public idToEvent;

    function createNewEvent(uint256 eventTimeStamp, uint256 deposit, uint256 maxCapacity, string calldata eventDataCID) external {
        bytes32 eventId = keccak256(abi.encodePacked(msg.sender, address(this), eventTimeStamp, deposit, maxCapacity));

        address[] memory confirmedRSVPs;
        address[] memory claimedRSVPs;

        idToEvent[eventId] = CreateEvent(eventId, eventDataCID, msg.sender, eventTimeStamp, deposit, maxCapacity, confirmedRSVPs, claimedRSVPs, false);
        emit NewEventCreated(eventId,msg.sender,eventTimeStamp,maxCapacity,deposit,eventDataCID
);

    }

    function createNewRSVP(bytes32 eventId) external payable {
        CreateEvent storage myEvent = idToEvent[eventId];
        require(msg.value == myEvent.deposit, "Not Enough");
        require(block.timestamp <= myEvent.eventTimestamp, "Event has already started");
        require(myEvent.confirmedRSVPs.length < myEvent.maxCapacity, "Event is full");

        for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
            require(myEvent.confirmedRSVPs[i] != msg.sender, "You have already RSVP'd");
        }
        emit NewRSVP(eventId, msg.sender);

    }

    function confirmAttendee(bytes32 eventId, address attendee) public {
        CreateEvent storage myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "You are not the event owner");

        address rsvpConfirm;

        for(uint8 i = 0; i <myEvent.confirmedRSVPs.length; i++) {
            if(myEvent.confirmedRSVPs[i] == attendee) {
                rsvpConfirm = attendee;
            }
        }
        require(rsvpConfirm == attendee, "RSVP not found");

        for(uint8  i = 0; i< myEvent.confirmedRSVPs.length; i++ ){
            require(myEvent.claimedRSVPs[i] != attendee, "ALREADY CLAIMED");
        }

        require(myEvent.paidOut == false, "Event has already been paid out");
        myEvent.claimedRSVPs.push(attendee);

        (bool sent,) = attendee.call{value: myEvent.deposit}("");

        if(!sent) {
            myEvent.claimedRSVPs.pop();
        }

        require(sent, "Failed to send Ether");
        emit ConfirmedAttendee(eventId, attendee);


    }

    function confirmAllAttendees(bytes32 eventId) external {
        CreateEvent memory myEvent = idToEvent[eventId];

    // make sure you require that msg.sender is the owner of the event
    require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

    // confirm each attendee in the rsvp array
    for (uint8 i = 0; i < myEvent.confirmedRSVPs.length; i++) {
        confirmAttendee(eventId, myEvent.confirmedRSVPs[i]);
    }
    }

    function withdrawUnclaimedDeposits(bytes32 eventId) external{
        CreateEvent memory myEvent = idToEvent[eventId];

        require(msg.sender == myEvent.eventOwner, "NOT AUTHORIZED");

        require(!myEvent.paidOut, "EVENT HAS ALREADY BEEN PAID OUT");

        require(
        block.timestamp >= (myEvent.eventTimestamp + 7 days),
        "TOO EARLY"
    );
        uint256 unclaimed  = myEvent.confirmedRSVPs.length - myEvent.claimedRSVPs.length;
        uint256 payout = unclaimed  * myEvent.deposit;

        myEvent.paidOut = true;

        (bool sent, ) = msg.sender.call{value: payout}("");

    // if this fails
    if (!sent) {
        myEvent.paidOut = false;
    }

    require(sent, "Failed to send Ether");
    emit DepositsPaidOut(eventId);

    }

}
