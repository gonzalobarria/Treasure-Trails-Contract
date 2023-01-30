// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TreasureTrailsXP is Ownable, AccessControl {
    enum ActivityType {
        Challenge,
        Meal,
        Attraction,
        Product
    }

    struct Ticket {
        string name;
        uint price;
        uint expiresAt;
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

    event ApprovedBuy(address, uint);
    event ChallengeStarted(address, uint);

    Ticket[] public tickets;
    Activity[] activities;
    ActivityType[] public activityTypes;

    // uint amount of credit
    mapping(address => uint) credits;
    // uint ticketIndex
    mapping(address => uint[]) ticketsPlayer;
    // uint activityIndex
    mapping(address => mapping(uint => uint)) activitiesPlayer;
    mapping(address => mapping(uint => uint)) activitiesWinnedPlayer;

    constructor() {
        // require(msg.value == tickets[_ticketIndex].price, "Insufficient funds");
        // Ticket memory ticket = tickets[_ticketIndex];
        // // TODO:  definir hora de expiración
        // // ticket.expiresAt
        // ticketsPlayer[msg.sender].push(_ticketIndex);
        // credits[msg.sender] = ticket.initialCredits;
    }

    // está sera la función que recibirá las compras
    function drop(string memory _gameHash, uint _amount) public {}

    function withdraw() public onlyOwner {
        (bool res, ) = owner().call{value: address(this).balance}("");
        require(res);
    }

    // se cancela funcion porque al firmar el contrato es la compra de una entrada
    function buyTicket(uint _ticketIndex) external payable {
        require(
            msg.value == tickets[_ticketIndex].price,
            "Incorrect amount sended"
        );
        ticketsPlayer[msg.sender].push(_ticketIndex);
        credits[msg.sender] = tickets[_ticketIndex].initialCredits;
    }

    function completeChallenge(uint _activityIndex) public {
        // - revisar si challenge está activo
        // - desactivar challenge después de X completados
        // - tener evento de notificación de finalización de challenge
        // - aumentar balance de créditos de usuario que gana challenge
        // - extra crédito si desea subir foto
        require(_activityIndex < activities.length, "Activity not found");

        Activity memory activity = activities[_activityIndex];
        credits[msg.sender] += activity.earnCredits;
    }

    function entranceAttraction(uint _activityIndex) public {
        // - hay juegos que pagas créditos por fast lane
        require(_activityIndex < activities.length, "Activity not found");
        Activity memory activity = activities[_activityIndex];
        credits[msg.sender] -= activity.discountCredits;

        activitiesPlayer[msg.sender][_activityIndex]++;
    }

    function exitAttraction(uint _activityIndex) public {
        // la regla es marcar a la entrada del juego sí o sí
        // - hay juegos donde ganas créditos marcando inicio y fin de juego (es como challenge)
        require(_activityIndex < activities.length, "Activity not found");

        uint rides = activitiesPlayer[msg.sender][_activityIndex];
        uint winnedRides = activitiesWinnedPlayer[msg.sender][_activityIndex];
        require(rides > winnedRides, "Only 1 prize");

        // Activity memory activity = activities[_activityIndex];

        // se revisa si marcó la entrada
        // if (activity.discountCredits > 0) {
        //     require(rides > winnedRides, "You are not payed your entrance");
        // }

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
        uint _expiresAt,
        uint _initialCredits
    ) public onlyOwner {
        // TODO: revisar que no haya otro ticket con el mismo nombre
        tickets.push(
            Ticket({
                name: _name,
                price: _price,
                expiresAt: _expiresAt,
                initialCredits: _initialCredits,
                isActive: true
            })
        );
    }

    function toggleTicket(uint _ticketIndex, bool _isActive) public onlyOwner {
        tickets[_ticketIndex].isActive = _isActive;
    }

    function toggleActivity(
        uint _activityIndex,
        bool _isActive
    ) public onlyOwner {
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

    function getActiveChallenges() public view returns (Activity[] memory) {
        uint count = 0;
        for (uint i = 0; i < activities.length; i++) {
            if (
                activities[i].isActive == true &&
                activities[i].activityType == ActivityType.Challenge
            ) count++;
        }

        Activity[] memory activeChallenges = new Activity[](count);
        uint j = 0;

        for (uint i = 0; i < activities.length; i++) {
            if (
                activities[i].isActive == true &&
                activities[i].activityType == ActivityType.Challenge
            ) activeChallenges[j] = activities[i];
        }

        return activeChallenges;
    }

    function getActivity(
        uint _activityIndex
    ) public view returns (Activity memory) {
        return activities[_activityIndex];
    }

    function getTicket(uint _ticketIndex) public view returns (Ticket memory) {
        return tickets[_ticketIndex];
    }

    function getTickets() public view returns (Ticket[] memory) {
        return tickets;
    }

    function getMyTickets() public view returns (uint[] memory) {
        return ticketsPlayer[msg.sender];
    }

    function getEntranceCount(uint _activityId) public view returns (uint) {
        return activitiesPlayer[msg.sender][_activityId];
    }

    function getExitCount(uint _activityId) public view returns (uint) {
        return activitiesWinnedPlayer[msg.sender][_activityId];
    }
}
