// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../governance/Senate.sol";

contract MockSenate is Senate {
    function mockInitialize(
        IVotesUpgradeable _token,
        TimelockControllerUpgradeable _timelock,
        address[] calldata _governanceWhitelist,
        address calldata _senatePositionsContract
    ) external {
        initialize(_token, _timelock, _senatePositionsContract);
        for (uint256 i = 0; i < _governanceWhitelist.length; i++) {
            governanceWhitelist[_governanceWhitelist[i]] = true;
        }
    }

    function mockSetQuorum(uint16 _quorumValue) external {
        quorum = _quorumValue;
    }

    function mockSetPosition(
        address user,
        Position position
    ) external {
        if (position == Position.Censor) {
            Censors(censorsContract).mockAddCensor(user);
        } else if (position == Position.Consul) {
            Consuls(consulsContract).mockAddConsul(user);
        } else if (position == Position.Dictator) {
            Dictators(dictatorsContract).mockAddDictator(user);
        } else if (position == Position.Senator) {
            Senators(senatorsContract).mockAddSenator(user);
        } else if (position == Position.Tribune) {
            Tribunes(tribunesContract).mockAddTribune(user);
        }
    }

    function mockRemovePosition(
        address user,
        Position position
    ) external {
        if (position == Position.Censor) {
            Censors(censorsContract).mockRemoveCensor(user);
        } else if (position == Position.Consul) {
            Consuls(consulsContract).mockRemoveConsul(user);
        } else if (position == Position.Dictator) {
            Dictators(dictatorsContract).mockRemoveDictator(user);
        } else if (position == Position.Senator) {
            Senators(senatorsContract).mockRemoveSenator(user);
        } else if (position == Position.Tribune) {
            Tribunes(tribunesContract).mockRemoveTribune(user);
        }
    }

    function mockSetGovernanceWhitelist(address user, bool status) external {
        governanceWhitelist[user] = status;
    }
}
