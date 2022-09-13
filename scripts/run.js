// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const [deployer, address1, address2] = await hre.ethers.getSigners();
 const rsvpContractFactory = await hre.ethers.getContractFactory('WEB3RSVP')
 const rsvpContract = rsvpContractFactory.deploy();
 await rsvpContract.deployed();
  console.log("Contract deployed to:", rsvpContract.address);
  
  let deposit = hre.ethers.utils.parseEther("1");
  let maxCapacity = 3;
  let timestamp = 1718926200;
  let eventDataCID =
    "bafybeibhwfzx6oo5rymsxmkdxpmkfwyvbjrrwcl7cekmbzlupmp5ypkyfi";

    
    let txn = await rsvpContract.createNewEvent(
      timestamp,
      deposit,
      maxCapacity,
      eventDataCID
    );
    let wait = await txn.wait();
    console.log("NEW EVENT CREATED:", wait.events[0].event, wait.events[0].args);
    
    let eventID = wait.events[0].args.eventID;
    console.log("EVENT ID:", eventID);


  
          
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
