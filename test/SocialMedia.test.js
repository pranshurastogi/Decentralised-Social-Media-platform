const { expect } = require("chai");
const { ethers } = require("hardhat");

let socialMedia;
let creator;

before(async function() {
    const contractFactory = await ethers.getContractFactory("SocialMedia");
    socialMedia = await contractFactory.deploy();
    await socialMedia.deployed();

    [creator] = await ethers.getSigners();
});

describe("Working with Post", function() {
    it("Create a post", async function() {
        await socialMedia.createPost("test description", "https://jibrish.ipfs");
        expect(await socialMedia.getAllPosts()).to.have.lengthOf(1);        
    });

    it ("Get a post by id", async function() {
        const post = await socialMedia.getPostById(1);
        expect(post).to.have.property("content", "https://jibrish.ipfs");
    });

    it ("Get post by user address", async function() {
        const postArray = await socialMedia.getPostsByUser(creator.address);
        expect(postArray.map(e => e.description)).to.include("test description");
    });
});