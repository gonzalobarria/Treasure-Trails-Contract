// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Utils.sol";
import "./TreasureTrailsXPSetup.sol";

contract TreasureTrailsXP is TreasureTrailsXPSetup {
    constructor(string memory _parkName, int _diffTZ) {
        parkName = _parkName;
        diffTZ = _diffTZ;
    }

    function getCredits() public view returns (uint) {
        return credits[msg.sender];
    }

    function getMyTickets() public view returns (TicketPlayer[] memory) {
        return ticketsPlayer[msg.sender];
    }

    function buyTicket(uint _ticketIndex) external payable {
        require(_ticketIndex < tickets.length, "Ticket not found");

        Ticket memory ticket = tickets[_ticketIndex];

        require(ticket.isActive, "Ticket is not Active");

        uint expiresAt = Utils.getTicketExpireAt(ticket.durationInDays, diffTZ);

        // se debe enviar el monto exacto del ticket
        require(
            msg.value == tickets[_ticketIndex].price,
            "Incorrect amount sended"
        );

        TicketPlayer[] memory myTickets = ticketsPlayer[msg.sender];

        bool ticketActivated = false;
        for (uint i = 0; i < myTickets.length; i++) {
            if (myTickets[i].expiresAt > block.timestamp) {
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

    // cuantas veces he subido a un juego
    function getEntranceCount(uint _activityId) public view returns (uint) {
        return activitiesPlayer[msg.sender][_activityId];
    }

    // cuántas veces he marcado la salida del juego
    function getExitCount(uint _activityId) public view returns (uint) {
        return activitiesWinnedPlayer[msg.sender][_activityId];
    }

    function buyMeals(uint _restaurantIndex, uint[] memory _items) public {
        require(_restaurantIndex < restaurants.length, "Restaurant not found");
        uint[] memory menu = getIdsMenuRestaurant(_restaurantIndex);

        bool itemsValidos = false;
        for (uint j = 0; j < _items.length; j++) {
            if (!Utils.isItemInArray(menu, _items[j])) break;

            itemsValidos = j == _items.length - 1;
        }

        require(itemsValidos, "Some Items are not in the restaurant");

        uint total;
        for (uint i = 0; i < _items.length; i++) {
            total += activities[_items[i]].discountCredits;
        }

        require(credits[msg.sender] >= total, "Insufficient Credits");

        credits[msg.sender] -= total;
    }

    function buyProducts(uint _storeIndex, uint[] memory _items) public {
        require(_storeIndex < stores.length, "Store not found");
        uint[] memory products = getIdsProductsStore(_storeIndex);

        bool itemsValidos = false;
        for (uint j = 0; j < _items.length; j++) {
            if (!Utils.isItemInArray(products, _items[j])) break;

            itemsValidos = j == _items.length - 1;
        }

        require(itemsValidos, "Some Items are not in the store");

        uint total;
        for (uint i = 0; i < _items.length; i++) {
            total += activities[_items[i]].discountCredits;
        }

        require(credits[msg.sender] >= total, "Insufficient Credits");

        credits[msg.sender] -= total;
    }

    // cambia por token del parque
    function canjeaToken() public {
        // - solo puede canjear si tiene una entrada válida del día
        // - sino se conjelan para la próxima visita
    }
}
