pragma solidity ^0.5.0;


/*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {
    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner = msg.sender;

    uint256 TICKET_PRICE = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint256 public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint256 totalTickets;
        uint256 sales;
        mapping(address => uint256) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint256 => Event) events;

    event LogEventAdded(
        string desc,
        string url,
        uint256 ticketsAvailable,
        uint256 eventId
    );
    event LogBuyTickets(address buyer, uint256 eventId, uint256 numTickets);
    event LogGetRefund(
        address accountRefunded,
        uint256 eventId,
        uint256 numTickets
    );
    event LogEndSale(address owner, uint256 balance, uint256 eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(
        string memory description,
        string memory website,
        uint256 totalTickets
    ) public onlyOwner returns (uint256) {
        events[idGenerator].description = description;
        events[idGenerator].website = website;
        events[idGenerator].totalTickets = totalTickets;
        events[idGenerator].isOpen = true;

        emit LogEventAdded(description, website, totalTickets, idGenerator);
        idGenerator++;

        return idGenerator - 1;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint256 id)
        public
        view
        returns (
            string memory description,
            string memory website,
            uint256 totalTickets,
            uint256 sales,
            bool isOpen
        )
    {
        return (
            events[id].description,
            events[id].website,
            events[id].totalTickets,
            events[id].sales,
            events[id].isOpen
        );
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint256 id, uint256 numTickets) public payable {
        require(events[id].isOpen);
        require(msg.value >= numTickets * TICKET_PRICE);
        require(events[id].totalTickets - events[id].sales >= numTickets);

        events[id].buyers[msg.sender] += numTickets;
        events[id].sales += numTickets;

        uint256 surplus = msg.value - numTickets * TICKET_PRICE;
        msg.sender.transfer(surplus);

        emit LogBuyTickets(msg.sender, id, numTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint256 id) public {
        require(events[id].buyers[msg.sender] > 0);
        uint256 refundedTickets = events[id].buyers[msg.sender];
        events[id].buyers[msg.sender] = 0;
        events[id].sales -= refundedTickets;
        uint256 refund = refundedTickets * TICKET_PRICE;
        msg.sender.transfer(refund);
        emit LogGetRefund(msg.sender, id, refundedTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint256 id) public view returns (uint256) {
        return events[id].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint256 id) public onlyOwner {
        events[id].isOpen = false;
        uint256 amountTransferred = address(this).balance;
        owner.transfer(amountTransferred);
        emit LogEndSale(owner, amountTransferred, id);
    }
}
