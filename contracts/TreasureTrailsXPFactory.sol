// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TreasureTrailsXPFactory is Ownable {
    int diffTZ;
    string parkName;

    enum ActivityType {
        Challenge,
        Meal,
        Attraction,
        Product
    }

    struct Ticket {
        string name;
        uint price;
        uint durationInDays;
        uint initialCredits;
        bool isActive;
    }

    struct Activity {
        string name;
        string description;
        uint earnCredits;
        uint discountCredits;
        bool isActive;
        uint expiresAt;
        ActivityType activityType;
    }

    struct TicketPlayer {
        uint ticketIndex;
        uint expiresAt;
    }

    struct Restaurant {
        string name;
    }

    struct Store {
        string name;
    }

    event ApprovedBuy(address, uint);
    event ChallengeStarted(address, uint);

    Ticket[] tickets;
    Activity[] activities;
    ActivityType[] public activityTypes;
    Restaurant[] public restaurants;
    Store[] public stores;

    // uint amount of credit
    mapping(address => uint) credits;

    // restaurantIndex => activityIndex tipo MEAL
    mapping(uint => uint[]) menuRestaurant;

    // storeIndex => activityIndex tipo PRODUCT
    mapping(uint => uint[]) productsStore;

    // uint activityIndex
    mapping(address => mapping(uint => uint)) activitiesPlayer;
    mapping(address => mapping(uint => uint)) activitiesWinnedPlayer;

    mapping(address => TicketPlayer[]) ticketsPlayer;

    function withdraw() public onlyOwner {
        (bool res, ) = owner().call{value: address(this).balance}("");
        require(res);
    }

    function addTicket(
        string memory _name,
        uint _price,
        uint _durationInDays,
        uint _initialCredits
    ) public onlyOwner {
        bool allowedCreation = tickets.length == 0;
        for (uint i = 0; i < tickets.length; i++) {
            if (keccak256(bytes(tickets[i].name)) == keccak256(bytes(_name)))
                break;

            allowedCreation = (i == tickets.length - 1);
        }

        require(allowedCreation, "There is another ticket with the same name");

        tickets.push(
            Ticket({
                name: _name,
                price: _price,
                durationInDays: _durationInDays,
                initialCredits: _initialCredits,
                isActive: true
            })
        );
    }

    function toggleTicket(uint _ticketIndex, bool _isActive) public onlyOwner {
        require(_ticketIndex < tickets.length, "Ticket not found");

        tickets[_ticketIndex].isActive = _isActive;
    }

    function addActivity(
        string memory _name,
        string memory _description,
        uint _earnCredits,
        uint _discountCredits,
        uint _expiresAt,
        ActivityType _activityType
    ) public onlyOwner {
        bool allowedCreation = activities.length == 0;
        for (uint i = 0; i < activities.length; i++) {
            if (keccak256(bytes(activities[i].name)) == keccak256(bytes(_name)))
                break;

            allowedCreation = (i == activities.length - 1);
        }

        require(
            allowedCreation,
            "There is another activity with the same name"
        );

        activities.push(
            Activity({
                name: _name,
                description: _description,
                earnCredits: _earnCredits,
                discountCredits: _discountCredits,
                isActive: false,
                expiresAt: _expiresAt,
                activityType: _activityType
            })
        );
    }

    function toggleActivity(
        uint _activityIndex,
        bool _isActive
    ) public onlyOwner {
        require(_activityIndex < activities.length, "Activity not found");

        activities[_activityIndex].isActive = _isActive;
    }

    function addRestaurant(string memory _name) public onlyOwner {
        restaurants.push(Restaurant({name: _name}));
    }

    function setMenuRestaurant(
        uint _restaurantIndex,
        uint[] memory _meals
    ) public onlyOwner {
        require(_restaurantIndex < restaurants.length, "Restaurant not found");

        bool correctItems = false;

        for (uint i = 0; i < _meals.length; i++) {
            if (activities[_meals[i]].activityType != ActivityType.Meal) break;

            correctItems = i == _meals.length - 1;
        }

        require(correctItems, "Some meal came with problems");

        menuRestaurant[_restaurantIndex] = _meals;
    }

    function addStore(string memory _name) public onlyOwner {
        stores.push(Store({name: _name}));
    }

    function setProductsStore(
        uint _storeIndex,
        uint[] memory _products
    ) public onlyOwner {
        require(_storeIndex < stores.length, "Store not found");

        bool correctItems = false;

        for (uint i = 0; i < _products.length; i++) {
            if (activities[_products[i]].activityType != ActivityType.Product)
                break;

            correctItems = i == _products.length - 1;
        }

        require(correctItems, "Some products came with problems");

        productsStore[_storeIndex] = _products;
    }
}
