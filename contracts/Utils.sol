// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Utils {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    int constant OFFSET19700101 = 2440588;

    function _daysFromDate(
        uint year,
        uint month,
        uint day
    ) public pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint(__days);
    }

    function _daysToDate(
        uint _days
    ) public pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(
        uint year,
        uint month,
        uint day
    ) public pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint timestamp) public pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint timestamp) public pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function addDays(
        uint timestamp,
        uint _days
    ) public pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(
        uint timestamp,
        uint _hours
    ) public pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function subHours(
        uint timestamp,
        uint _hours
    ) public pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function timestampTZ(
        uint _timestamp,
        int diffTZ
    ) public pure returns (uint) {
        return
            diffTZ >= 0
                ? addHours(_timestamp, uint(diffTZ))
                : subHours(_timestamp, uint(-diffTZ));
    }

    function tzTimeToTS(
        uint _timestamp,
        int diffTZ
    ) public pure returns (uint) {
        return
            diffTZ >= 0
                ? subHours(_timestamp, uint(diffTZ))
                : addHours(_timestamp, uint(-diffTZ));
    }

    function getTicketExpireAt(
        uint _days,
        int diffTZ
    ) public view returns (uint) {
        uint ahoraconTZ = timestampTZ(block.timestamp, diffTZ);
        return
            tzTimeToTS(
                timestampFromDate(
                    getYear(ahoraconTZ),
                    getMonth(ahoraconTZ),
                    getDay(addDays(ahoraconTZ, _days))
                ),
                diffTZ
            );
    }

    function isItemInArray(
        uint[] memory arr,
        uint item
    ) public pure returns (bool) {
        bool isIn = false;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                isIn = true;
                break;
            }
        }
        return isIn;
    }
}
