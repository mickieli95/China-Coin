pragma solidity ^0.6.2;
/* SPDX-License-Identifier: UNLICENSED */

interface IERC20
{
    function transfer(address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint256 balance);
}

contract ChinaCoinMiningSystem
{
    IERC20 private TCCI;
    address tcc_contract = 0xb4eef1F9777C9d7a7c2bCC8da6686f53fBbF1DCD;

    uint256 level_0_mining = 5000000000000000000000000; /* 5 mil */
    uint256 level_0_reward = 300000000000000000000000;  /* 300k */

    uint256 level_1_mining = 10000000000000000000000000; /* 10 mil */
    uint256 level_1_reward = 350000000000000000000000;   /* 350k */

    uint256 level_2_mining = 25000000000000000000000000; /* 25 mil */
    uint256 level_2_reward = 500000000000000000000000;   /* 500k */

    uint256 level_3_mining = 50000000000000000000000000; /* 50 mil */
    uint256 level_3_reward = 700000000000000000000000;   /* 700k */

    address public owner_address;

    mapping(address => uint256) public last_update_time;
    uint256 public start_timestamp;
    uint256 last_global_update = 0;

    uint16 total_miners_in_period = 0;

    uint16 period_duration = 60; /* How long a mining period lasts, in seconds. */
    uint16 max_miners_in_period = 10; /* How many miners are allowed in one period. */

    bool locked = false;

    constructor() public 
    {
        owner_address = msg.sender;
        start_timestamp = 1646251200; /* Wednesday, 2 March 2022 20:00:00 */
        TCCI = IERC20(tcc_contract);
    }

    modifier onlyOwner()
    {
        require (msg.sender == owner_address);
        _;
    }

    receive() external payable 
    {   require(!locked, "mining is halted.");
        /* Check user's China Coin balance. */
        uint256 current_balance = TCCI.balanceOf(msg.sender);
        require(current_balance >= 5000000000000000000000000);

        require(now > start_timestamp, "mining not open yet.");
        require(msg.value >= 1 ether, "minimum 1 TLOS.");
        require(msg.value <= 2 ether, "maximum 2 TLOS.");
        require(last_update_time[msg.sender] >= now+60, "mining too fast, throttled.");

        /* Get global update time */
        if (last_global_update == 0)
        {   last_global_update = now;   }

        if (now >= last_global_update+period_duration)
        {/* Reset global throttling timer */
            last_global_update = now;
            total_miners_in_period = 0; }

        total_miners_in_period++;
        require(total_miners_in_period <= max_miners_in_period, "too many miners, throttled.");

        uint256 reward = 300000000000000000000000; /* level 0 reward */
        /* Determine mining level */
        if (current_balance >= level_1_mining)
        {   if (current_balance < level_2_mining)
            {   reward = 350000000000000000000000;   } /* level 1 reward */
            else
            {   if (current_balance < level_3_mining)
                {   reward = 500000000000000000000000;   } /* level 2 reward */
                else
                {   if (current_balance >= level_3_mining)
                    {   reward = 700000000000000000000000;   } /* level 3 reward */
                }
            }
        }
        /* Update the user's last_cooldown_time */
        last_update_time[msg.sender] = now;
        /* Check own balances.*/
        require(TCCI.balanceOf(address(this)) >= reward);
        /* Send the user his coins */
        TCCI.transfer(msg.sender, reward);
    }

    function withdraw() public onlyOwner
    {
        address payable owner = address(uint160(msg.sender));
        owner.transfer(address(this).balance);
    }

    function SET_LVL0_REWARD(uint256 reward) public onlyOwner {level_0_reward = reward;}
    function SET_LVL1_REWARD(uint256 reward) public onlyOwner {level_1_reward = reward;}
    function SET_LVL2_REWARD(uint256 reward) public onlyOwner {level_2_reward = reward;}
    function SET_LVL3_REWARD(uint256 reward) public onlyOwner {level_3_reward = reward;}
    function SET_PERIOD_DURATION(uint16 duration) public onlyOwner {period_duration = duration;}
    function SET_MAX_MINERS(uint16 max_miners) public onlyOwner {max_miners_in_period = max_miners;}
    function SET_LOCKED(bool _locked) public onlyOwner {locked = _locked;}
}
