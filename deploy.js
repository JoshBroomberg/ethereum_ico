// DEPRECATED

var Web3 = require("web3");
const fs = require("fs");
const readFile = require('fs-readfile-promise');

if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
}
var contracts = [];

function deployContract(name, source) {
  console.log("Compiling " + name);
  var contractCompiled = web3.eth.compile.solidity(source);
  var contract = web3.eth.contract(contractCompiled.info.abiDefinition);

  var Contract = contract.new({
    from: web3.eth.accounts[0],
    data: contractCompiled.code,
    gas: 3000000
  }, function(e, contract) {
      if(!e) {
        if(!contract.address) {
          console.log("Deploying " + name + "...");
        } else {
          console.log(name + " contract mined! Address: " + contract.address);
        }
      }
  });
  contracts.push(Contract);
}

readFile('token.sol').then(function (data) {
    data = data.toString();
    deployContract("Token", data);
    return readFile('association.sol', 'utf8');
}).then(function (data) {
    data = data.toString();
    deployContract("Association", data);
    return readFile('sale.sol');
}).then(function (data) {
    data = data.toString();
    deployContract("Sale", data);
});
