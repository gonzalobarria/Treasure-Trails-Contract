// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TreasureTrailsXPFactory.sol";

contract TreasureTrailsXPSetup is TreasureTrailsXPFactory {
    function getActivity(
        uint _activityIndex
    ) public view returns (Activity memory) {
        require(_activityIndex < activities.length, "Activity not found");

        return activities[_activityIndex];
    }

    function getActivities() public view returns (Activity[] memory) {
        return activities;
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
            ) {
                activeChallenges[j] = activities[i];
                j++;
            }
        }

        return activeChallenges;
    }

    function getTicket(uint _ticketIndex) public view returns (Ticket memory) {
        require(_ticketIndex < tickets.length, "Activity not found");

        return tickets[_ticketIndex];
    }

    function getTickets() public view returns (Ticket[] memory) {
        return tickets;
    }

    function getRestaurants() public view returns (Restaurant[] memory) {
        return restaurants;
    }

    function getMenuRestaurant(
        uint _restaurantIndex
    ) public view returns (Activity[] memory) {
        uint[] memory activityItems = menuRestaurant[_restaurantIndex];

        Activity[] memory menu = new Activity[](activityItems.length);

        uint j = 0;
        for (uint i = 0; i < activityItems.length; i++) {
            menu[j] = getActivity(activityItems[i]);
            j++;
        }

        return menu;
    }

    function getIdsMenuRestaurant(
        uint _restaurantIndex
    ) public view returns (uint[] memory) {
        return menuRestaurant[_restaurantIndex];
    }

    function getStores() public view returns (Store[] memory) {
        return stores;
    }

    function getProductsStore(
        uint _storeIndex
    ) public view returns (Activity[] memory) {
        uint[] memory activityItems = productsStore[_storeIndex];

        Activity[] memory products = new Activity[](activityItems.length);

        uint j = 0;
        for (uint i = 0; i < activityItems.length; i++) {
            products[j] = getActivity(activityItems[i]);
            j++;
        }

        return products;
    }

    function getIdsProductsStore(
        uint _storeIndex
    ) public view returns (uint[] memory) {
        return productsStore[_storeIndex];
    }
}
