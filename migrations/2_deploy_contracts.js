var Token = artifacts.require("./Token.sol");
var Association = artifacts.require("./Association.sol");
var Sale = artifacts.require("./Sale.sol");

module.exports = function(deployer) {
  var numberOfShares = 10000
  deployer.deploy(Token,
                  numberOfShares // Initial supply
                 ).then(function () {
    deployer.deploy(Association,
                    Token.address, // Shared distribution
                    10080, // debateTimeInMinutes
                    numberOfShares * 0.5 // minimumQuorum
                  ).then(function() {
      deployer.deploy(Sale,
                      Association.address, // beneficiary
                      1000, // funding goal in Ether
                      1, // duration in minutes. Set to 1 for demo.
                      1, // Ether cost per token
                      Token.address // Reward token address
                    ).then(function () {
                      return Token.deployed();
                    }).then(function(instance) {
                      return instance.changeMinter(Sale.address);
                    });
    });
  });
};
