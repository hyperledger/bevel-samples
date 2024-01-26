const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GeneralContract Testing", function () {
  let contractInstance, manufacturer, carrier, warehouse;
  let containers, products;

  before("Deploy the General contract instance", async function () {
    const GeneralContract = await ethers.getContractFactory("General");
    contractInstance = await GeneralContract.deploy();
    [manufacturer, carrier, warehouse] = await ethers.getSigners();
  });

  it("Create a new product", async function () {
    products = [
      {
        productName: "Dextrose",
        health: "good",
        misc: ["\{ 'name': 'Expensive Dextrose' \}"],
        trackingID: "123",
        lastScannedAt: "OU=Manufacturer,O=Manufacturer,L=47.38/8.54/Zurich,C=CH",
        participants: [(manufacturer.address + "," + "OU=Manufacturer,O=Manufacturer,L=47.38/8.54/Zurich,C=CH"),
        (carrier.address + "," + "OU=Carrier,O=PartyB,L=51.50/-0.13/London,C=GB"),
        (warehouse.address + "," + "OU=Warehouse,O=PartyC,L=42.36/-71.06/Boston,C=US")]
      },
    ];
    await contractInstance.addProduct(
      products[0].trackingID,
      products[0].productName,
      products[0].health,
      products[0].misc,
      products[0].lastScannedAt,
      products[0].participants);

    // call getSingleProduct to see if product is created
    const result = await contractInstance.getSingleProduct("123");
    // Checking the 1st index of the returned tuple
    expect(result[0]).to.equal("123");
  });

  it("Create a new container", async () => {
    containers = [
      {
        health: "good",
        misc: ["\{ 'name': 'Dextrose' \}"],
        trackingID: "jjj",
        lastScannedAt: "OU=Manufacturer,O=Manufacturer,L=47.38/8.54/Zurich,C=CH",
        counterparties: [(manufacturer.address + "," + "OU=Manufacturer,O=Manufacturer,L=47.38/8.54/Zurich,C=CH"),
        (carrier.address + "," + "OU=Carrier,O=PartyB,L=51.50/-0.13/London,C=GB"),
        (warehouse.address + "," + "OU=Warehouse,O=PartyC,L=42.36/-71.06/Boston,C=US")]
      },
    ];
    await contractInstance.addContainer(
      containers[0].health,
      containers[0].misc,
      containers[0].trackingID,
      containers[0].lastScannedAt,
      containers[0].counterparties);

    // call getSingleContainer to see if product got created
    const result = await contractInstance.getSingleContainer("jjj");
    expect(result[4]).to.equal("jjj");
  });

  it("Get the total number of products created", async () => {
    const result = await contractInstance.getProductsLength();
    expect(result).to.equal(1);
  });

  it("Get the total number of containers created", async () => {
    const result = await contractInstance.getContainersLength();
    expect(result).to.equal(1);
  });

  it("Get a container using a tracking id", async () => {
    var trackingID = "jjj";
    const result = await contractInstance.getSingleContainer(trackingID);
    expect(result[4]).to.equal(trackingID);
  });

  it("Get a product using a tracking id", async () => {
    var trackingID = "123";
    const result = await contractInstance.getSingleProduct(trackingID);
    expect(result[0]).to.equal(trackingID);
  });

  it("Get the containerless product", async () => {
    var trackingID = "123";
    result = await contractInstance.getContainerlessAt(0);
    expect(result[0]).to.equal(trackingID);
  });

  it("Manufacturer packages product into container and checks product", async () => {
    //tracking ID of the product
    const trackingId = "123";
    // tracking ID of the container that will become the products container ID
    const containerId = "jjj";
    await contractInstance.packageTrackable(trackingId, containerId);
    const result = await contractInstance.getSingleProduct(trackingId);
    // checks the 8th index of the product tuple
    expect(result[8]).to.equal(containerId);
  })

  it("Carrier takes possession of the container", async () => {
    //tracking ID of the product
    const trackingId = "123";
    // tracking ID of the container that will become the products container ID
    const containerId = "jjj";
    const lastScannedAt = "OU=Carrier,O=PartyB,L=51.50/-0.13/London,C=GB"
    await contractInstance.connect(carrier).updateContainerCustodian(containerId, lastScannedAt, { from: carrier });
    const result = await contractInstance.getSingleContainer(containerId);
    //checking to see if the container custodian was updated to carrier
    expect(String(result[2]) + "," + lastScannedAt).to.equal(containers[0].counterparties[1]);
  })

  // Manufacturer no longer have possession of the product and therefore should not be able to unpackage the container
  it("Manufacturer should not be able to unpackage container", async () => {
    //tracking ID of the product
    const trackingId = "123";
    // tracking ID of the container that will become the products container ID
    const containerId = "jjj";
    await expect(contractInstance.unpackageTrackable(containerId, trackingId, { from: manufacturer }))
      .to.be.revertedWith("HTTP 400: container custodian not same as sender address");

  })

  it("Carrier wants to unpackage container", async () => {
    //tracking ID of the product
    const trackingId = "123";
    // tracking ID of the container that will become the products container ID
    const containerId = "jjj";
    await contractInstance.connect(carrier).unpackageTrackable(containerId, trackingId, { from: carrier });
    const result = await contractInstance.getSingleProduct(trackingId);
    expect(result[8]).to.equal("");
  })

  it("Warehouse wants to claim product", async () => {
    const trackingId = "123";
    const lastScannedAt = "OU=Warehouse,O=PartyC,L=42.36/-71.06/Boston,C=US";
    await contractInstance.connect(warehouse).updateCustodian(trackingId, lastScannedAt, { from: warehouse });
    const result = await contractInstance.getSingleProduct(trackingId);
    expect(result[5] + "," + lastScannedAt).to.equal(products[0].participants[2]);
  })

  it("Manufacturer wants to check ownership of product", async () => {
    const trackingId = "123";
    const result = await contractInstance.scan(trackingId);
    expect(result).to.equal("unowned");
  })

  it("Manufacturer wants to get history of a product", async () => {
    const trackingId = "123";
    var history = [];
    // Call getHistoryLength to get the number of transactions for that trackingID
    const historyCounter = await contractInstance.getHistoryLength(trackingId);
    //toNumber function converts big number to javascript native number
    for (var i = 0; i < historyCounter; i++) {
      result = await contractInstance.getHistory((i), trackingId);
      history.push(result);
    }
    expect(history.length).to.equal(3);
  });
});
