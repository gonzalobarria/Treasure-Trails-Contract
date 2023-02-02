// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BokkyPooBahsDateTimeLibrary.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TreasureTrailsXP is Ownable, AccessControl {
    using BokkyPooBahsDateTimeLibrary for uint;
    int diffTZ;
    string parkName;

    constructor(string memory _parkName, int _diffTZ) {
        parkName = _parkName;
        diffTZ = _diffTZ;
    }

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
    // uint ticketIndex
    // mapping(address => uint[]) ticketsPlayer;

    // restaurantIndex => activityIndex tipo MEAL
    mapping(uint => uint[]) menuRestaurant;

    // storeIndex => activityIndex tipo PRODUCT
    mapping(uint => uint[]) productsStore;

    // uint activityIndex
    mapping(address => mapping(uint => uint)) activitiesPlayer;
    mapping(address => mapping(uint => uint)) activitiesWinnedPlayer;

    // TODO: revisará si el ticket se encuentra activo con respecto a la fecha de expiración
    // TODO: creo que necesito registrar la hora de la compra para que el ticket expire en a las 00 horas
    mapping(address => TicketPlayer[]) ticketsPlayer;

    function withdraw() public onlyOwner {
        (bool res, ) = owner().call{value: address(this).balance}("");
        require(res);
    }

    function timestampTZ(uint _timestamp) private view returns (uint) {
        return
            diffTZ >= 0
                ? _timestamp.addHours(uint(diffTZ))
                : _timestamp.subHours(uint(-diffTZ));
    }

    function tzTimeToTS(uint _timestamp) private view returns (uint) {
        return
            diffTZ >= 0
                ? _timestamp.subHours(uint(diffTZ))
                : _timestamp.addHours(uint(-diffTZ));
    }

    function getTicketExpireAt(uint _days) private view returns (uint) {
        uint ahoraconTZ = timestampTZ(block.timestamp);
        return
            tzTimeToTS(
                ahoraconTZ.getYear().timestampFromDate(
                    ahoraconTZ.getMonth(),
                    ahoraconTZ.addDays(_days).getDay()
                )
            );
    }

    function buyTicket(uint _ticketIndex) external payable {
        require(_ticketIndex < tickets.length, "Ticket not found");

        Ticket memory ticket = tickets[_ticketIndex];

        require(ticket.isActive, "Ticket is not Active");

        uint expiresAt = getTicketExpireAt(ticket.durationInDays);

        // se debe enviar el monto exacto del ticket
        require(
            msg.value == tickets[_ticketIndex].price,
            "Incorrect amount sended"
        );

        TicketPlayer[] memory myTickets = ticketsPlayer[msg.sender];

        bool ticketActivated = false;
        for (uint i = 0; i < myTickets.length; i++) {
            if (
                // myTickets[i].ticketIndex == _ticketIndex &&
                myTickets[i].expiresAt > block.timestamp
            ) {
                ticketActivated = true;
                break;
            }
        }
        require(!ticketActivated, "Just one active ticket per user");

        ticketsPlayer[msg.sender].push(
            TicketPlayer({ticketIndex: _ticketIndex, expiresAt: expiresAt})
        );
        credits[msg.sender] = tickets[_ticketIndex].initialCredits;
    }

    function completeChallenge(uint _activityIndex) public {
        // TODO - desactivar challenge después de X completados
        // TODO - tener evento de notificación de finalización de challenge
        // TODO - extra crédito si desea subir foto
        require(_activityIndex < activities.length, "Activity not found");

        Activity memory activity = activities[_activityIndex];

        // - la actividad que se completa debe ser un challenge
        require(
            activity.activityType == ActivityType.Challenge,
            "This is not a challenge"
        );

        // - revisar si challenge está activo
        require(activity.isActive, "Activity is not Active");

        // - el usuario no puede realizar dos veces el mismo challenge
        require(
            activitiesPlayer[msg.sender][_activityIndex] == 0,
            "Activity was already done"
        );

        // - aumentar balance de créditos de usuario que gana challenge
        credits[msg.sender] += activity.earnCredits;

        // - registrar la realización del challenge
        activitiesPlayer[msg.sender][_activityIndex]++;
    }

    function entranceAttraction(uint _activityIndex) public {
        // - hay juegos que pagas créditos por fast lane
        require(_activityIndex < activities.length, "Activity not found");

        Activity memory activity = activities[_activityIndex];

        // - revisar si challenge está activo
        require(activity.isActive, "Activity is not Active");

        // - la actividad debe ser una atracción
        require(
            activity.activityType == ActivityType.Attraction,
            "This is not a challenge"
        );

        // debe tener créditos para subir a la atracción
        require(
            credits[msg.sender] >= activity.discountCredits,
            "Don't have enough credits"
        );

        credits[msg.sender] -= activity.discountCredits;

        activitiesPlayer[msg.sender][_activityIndex]++;
    }

    function exitAttraction(uint _activityIndex) public {
        require(_activityIndex < activities.length, "Activity not found");

        uint rides = activitiesPlayer[msg.sender][_activityIndex];
        uint winnedRides = activitiesWinnedPlayer[msg.sender][_activityIndex];

        // la regla es marcar a la entrada del juego sí o sí
        require(rides > winnedRides, "Must do check-in in the entrance");

        credits[msg.sender] += activities[_activityIndex].earnCredits;
        activitiesWinnedPlayer[msg.sender][_activityIndex]++;
    }

    // cambia por token del parque
    function canjeaToken() public {
        // - solo puede canjear si tiene una entrada válida del día
        // - sino se conjelan para la próxima visita
    }

    function getCredits() public view returns (uint) {
        return credits[msg.sender];
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

    function toggleActivity(
        uint _activityIndex,
        bool _isActive
    ) public onlyOwner {
        require(_activityIndex < activities.length, "Activity not found");

        activities[_activityIndex].isActive = _isActive;
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

            allowedCreation = (i == tickets.length - 1);
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

    function getActiveActivities(
        ActivityType _activityType
    ) public view returns (Activity[] memory) {
        uint count = 0;
        for (uint i = 0; i < activities.length; i++) {
            if (
                activities[i].isActive &&
                activities[i].activityType == _activityType
            ) count++;
        }

        Activity[] memory activeChallenges = new Activity[](count);
        uint j = 0;

        for (uint i = 0; i < activities.length; i++) {
            if (
                activities[i].isActive &&
                activities[i].activityType == _activityType
            ) activeChallenges[j] = activities[i];
        }

        return activeChallenges;
    }

    function getActivity(
        uint _activityIndex
    ) public view returns (Activity memory) {
        require(_activityIndex < activities.length, "Activity not found");

        return activities[_activityIndex];
    }

    function getTicket(uint _ticketIndex) public view returns (Ticket memory) {
        require(_ticketIndex < tickets.length, "Activity not found");

        return tickets[_ticketIndex];
    }

    function getTickets() public view returns (Ticket[] memory) {
        return tickets;
    }

    function getMyTickets() public view returns (TicketPlayer[] memory) {
        return ticketsPlayer[msg.sender];
    }

    // cuantas veces he subido a un juego
    function getEntranceCount(uint _activityId) public view returns (uint) {
        return activitiesPlayer[msg.sender][_activityId];
    }

    // cuántas veces he marcado la salida del juego
    function getExitCount(uint _activityId) public view returns (uint) {
        return activitiesWinnedPlayer[msg.sender][_activityId];
    }

    function addStore(string memory _name) public onlyOwner {
        stores.push(Store({name: _name}));
    }

    function addRestaurant(string memory _name) public onlyOwner {
        restaurants.push(Restaurant({name: _name}));
    }

    function setMenuRestaurant(
        uint _restaurantIndex,
        uint[] memory _meals
    ) public onlyOwner {
        require(_restaurantIndex < restaurants.length, "Restaurant not found");

        bool correctItems = true;
        for (uint i = 0; i < activities.length; i++) {
            if (
                !activities[i].isActive ||
                activities[i].activityType != ActivityType.Meal
            ) {
                correctItems = false;
                break;
            }
        }

        require(correctItems, "Some meal came with problems");

        menuRestaurant[_restaurantIndex] = _meals;
    }

    function setProductsStore(
        uint _storeIndex,
        uint[] memory _products
    ) public onlyOwner {
        require(_storeIndex < stores.length, "Store not found");

        bool correctItems = true;
        for (uint i = 0; i < activities.length; i++) {
            if (
                !activities[i].isActive ||
                activities[i].activityType != ActivityType.Product
            ) {
                correctItems = false;
                break;
            }
        }

        require(correctItems, "Some products came with problems");

        productsStore[_storeIndex] = _products;
    }

    function buyItems(uint _restaurantIndex, uint[] memory _items) public {
        require(_restaurantIndex < restaurants.length, "Restaurant not found");

        uint total;
        for (uint i = 0; i < _items.length; i++) {
            total += activities[_items[i]].discountCredits;
        }

        require(credits[msg.sender] >= total, "Insufficient Credits");

        credits[msg.sender] -= total;
    }
}
