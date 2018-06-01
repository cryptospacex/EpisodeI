const SpaceXTokenSale = artifacts.require("./SpaceXTokenSale.sol")

module.exports = function(deployer) {
	deployer.deploy(SpaceXTokenSale);
};