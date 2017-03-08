var Token = artifacts.require("./Token.sol");
var Association = artifacts.require("./Association.sol");
var Sale = artifacts.require("./Sale.sol");

module.exports = function(deployer) {
  deployer.deploy(Token, "Token", "TKN", 8, 10000000000000).then(function () {
    deployer.deploy(Association, Token.address, 10080, 20000).then(function() {
      deployer.deploy(Sale, web3.eth.accounts[0], 200, 43200, 1, Token.address);
    });
  });
};
