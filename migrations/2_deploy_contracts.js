var Token = artifacts.require("./Token.sol");
var Association = artifacts.require("./Association.sol");
var Sale = artifacts.require("./Sale.sol");

module.exports = function(deployer) {
  deployer.deploy(Token);
  deployer.deploy(Association);
  deployer.deploy(Sale);
};
