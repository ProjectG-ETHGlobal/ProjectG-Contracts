const ProjectG = artifacts.require("ProjectG");

module.exports = async function (deployer) {
    await deployer.deploy(ProjectG);
    const projectG = await ProjectG.deployed();
    console.log("ProjectG deployed to:", projectG.address);
}